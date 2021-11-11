//
//  CardanoSendApiTests.swift
//  
//
//  Created by Ostap Danylovych on 02.11.2021.
//

import Foundation
import XCTest
@testable import Cardano
import BlockfrostSwiftSDK
import CardanoBlockfrost
import Bip39

final class CardanoSendApiTests: XCTestCase {
    private static let testMnemonic = try! Mnemonic()
    
    private static var testAccount: Account {
        let keychain = try! Keychain(mnemonic: testMnemonic.mnemonic(), password: Data())
        return try! keychain.addAccount(index: 0)
    }
    
    private static var testToAddress: Address {
        let keychain = try! Keychain(mnemonic: testMnemonic.mnemonic(), password: Data())
        let account = try! keychain.addAccount(index: 1)
        return try! account.baseAddress(
            index: 0,
            change: false,
            networkID: NetworkInfo.testnet.network_id
        ).address
    }
    
    private static var testExtendedAddress: ExtendedAddress {
        try! testAccount.baseAddress(
            index: 0,
            change: false,
            networkID: NetworkInfo.testnet.network_id
        )
    }
    
    private static var testChangeAddress: Address {
        try! testAccount.baseAddress(
            index: 1,
            change: true,
            networkID: NetworkInfo.testnet.network_id
        ).address
    }

    private static let testUtxo = UTXO(
        address: testExtendedAddress.address,
        txHash: TransactionHash(),
        index: 1,
        value: Value(coin: 1000)
    )

    private static let testTransactionHash = "testTransactionHash"
    
    private static let testTransaction = Transaction(
        body: TransactionBody(inputs: [], outputs: [], fee: 0, ttl: nil),
        witnessSet: TransactionWitnessSet(),
        metadata: nil
    )
    
    private let dispatchQueue = DispatchQueue(label: "CardanoSendApiTests.Async.Queue", target: .global())
    
    private enum TestError: Error {
        case error
    }
    
    private struct SignatureProviderMock: SignatureProvider {
        func accounts(_ cb: @escaping (Result<[Account], Error>) -> Void) {}
        
        func sign(tx: ExtendedTransaction, _ cb: @escaping (Result<Transaction, Error>) -> Void) {
            cb(.success(testTransaction))
        }
    }
    
    private struct AddressManagerMock: AddressManager {
        func accounts(_ cb: @escaping (Result<[Account], Error>) -> Void) {}
        
        func new(for account: Account, change: Bool) throws -> Address {
            guard account == testAccount, change else {
                throw TestError.error
            }
            return testChangeAddress
        }
        
        func get(cached account: Account) throws -> [Address] {
            guard account == testAccount else {
                throw TestError.error
            }
            return [testExtendedAddress.address]
        }
        
        func get(for account: Account, _ cb: @escaping (Result<[Address], Error>) -> Void) {}
        
        func fetch(for accounts: [Account], _ cb: @escaping (Result<Void, Error>) -> Void) {}
        
        func fetchedAccounts() -> [Account] {
            []
        }
        
        func extended(addresses: [Address]) throws -> [ExtendedAddress] {
            [testExtendedAddress]
        }
    }
    
    private struct UtxoProviderMock: UtxoProvider {
        struct TestUtxoIterator: UtxoProviderAsyncIterator {
            func next(_ cb: @escaping (Result<[UTXO], Error>, Self?) -> Void) {
                cb(.success([testUtxo]), nil)
            }
        }
        
        func get(for addresses: [Address], asset: (PolicyID, AssetName)?) -> UtxoProviderAsyncIterator {
            TestUtxoIterator()
        }
        
        func get(for transaction: TransactionHash, _ cb: @escaping (Result<[UTXO], Error>) -> Void) {}
    }
    
    private struct NetworkProviderMock: NetworkProvider {
        func getBalance(for address: Address, _ cb: @escaping (Result<UInt64, Error>) -> Void) {}
        
        func getTransactions(for address: Address,
                             _ cb: @escaping (Result<[AddressTransaction], Error>) -> Void) {}
        
        func getTransactionCount(for address: Address,
                                 _ cb: @escaping (Result<Int, Error>) -> Void) {}
        
        func getTransaction(hash: String,
                            _ cb: @escaping (Result<ChainTransaction?, Error>) -> Void) {}
        
        func getUtxos(for addresses: [Address],
                      page: Int,
                      _ cb: @escaping (Result<[UTXO], Error>) -> Void) {}
        
        func getUtxos(for transaction: TransactionHash,
                      _ cb: @escaping (Result<[UTXO], Error>) -> Void) {}
        
        func submit(tx: Transaction,
                    _ cb: @escaping (Result<String, Error>) -> Void) {
            guard try! tx.bytes() == testTransaction.bytes() else {
                cb(.failure(TestError.error))
                return
            }
            cb(.success(testTransactionHash))
        }
    }
    
    private func getTransaction(cardano: Cardano,
                                transactionHash: String,
                                _ cb: @escaping (ChainTransaction) -> Void) {
        cardano.tx.get(hash: transactionHash) { res in
            guard let chainTransaction = try! res.get() else {
                self.dispatchQueue.asyncAfter(deadline: .now() + 10) {
                    self.getTransaction(cardano: cardano, transactionHash: transactionHash, cb)
                }
                return
            }
            cb(chainTransaction)
        }
    }
    
    func testSendAdaOnTestnet() throws {
        let sent = expectation(description: "Ada sent")
        let keychain = try Keychain(
            mnemonic: TestEnvironment.instance.mnemonic,
            password: Data()
        )
        let cardano = try Cardano(
            info: .testnet,
            addresses: SimpleAddressManager(),
            utxos: NonCachingUtxoProvider(),
            signer: keychain,
            network: BlockfrostNetworkProvider(config: BlockfrostConfig(
                basePath: "https://cardano-testnet.blockfrost.io/api/v0",
                projectId: TestEnvironment.instance.blockfrostProjectId
            ))
        )
        let account = try keychain.addAccount(index: 0)
        cardano.addresses.fetch(for: [account]) { res in
            try! res.get()
            let addresses = try! cardano.addresses.get(cached: account)
            let to = addresses.count < 100
                ? try! cardano.addresses.new(for: account, change: false)
                : addresses.randomElement()!
            let amount1: UInt64 = 10000000
            let change = try! cardano.addresses.new(for: account, change: true)
            cardano.send.ada(to: to, amount: amount1, from: [addresses.last!], change: change) { res in
                let transactionHash = try! res.get()
                self.getTransaction(cardano: cardano,
                                    transactionHash: transactionHash) { chainTransaction in
                    let amount2 = try! Value(
                        blockfrost: chainTransaction.outputAmount.map {
                            (unit: $0.unit, quantity: $0.quantity)
                        }
                    ).coin
                    XCTAssertEqual(amount1, amount2)
                    sent.fulfill()
                }
            }
        }
        wait(for: [sent], timeout: 100)
    }
    
    func testSendAdaFromAccount() throws {
        let success = expectation(description: "success")
        let cardano = try Cardano(
            info: .testnet,
            addresses: AddressManagerMock(),
            utxos: UtxoProviderMock(),
            signer: SignatureProviderMock(),
            network: NetworkProviderMock()
        )
        cardano.send.ada(to: Self.testToAddress, amount: 100, from: Self.testAccount) { res in
            let transactionHash = try! res.get()
            XCTAssertEqual(transactionHash, Self.testTransactionHash)
            success.fulfill()
        }
        wait(for: [success], timeout: 10)
    }
    
    func testSendAdaFromAddresses() throws {
        let success = expectation(description: "success")
        let cardano = try Cardano(
            info: .testnet,
            addresses: AddressManagerMock(),
            utxos: UtxoProviderMock(),
            signer: SignatureProviderMock(),
            network: NetworkProviderMock()
        )
        cardano.send.ada(to: Self.testToAddress,
                         amount: 100,
                         from: [Self.testExtendedAddress.address],
                         change: Self.testChangeAddress) { res in
            let transactionHash = try! res.get()
            XCTAssertEqual(transactionHash, Self.testTransactionHash)
            success.fulfill()
        }
        wait(for: [success], timeout: 10)
    }
}
