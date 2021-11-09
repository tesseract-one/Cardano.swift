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
                            _ cb: @escaping (Result<ChainTransaction, Error>) -> Void) {}
        
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
    
    func testSendAdaOnTestnet() throws {
        let testMnemonic = ProcessInfo.processInfo
            .environment["SendApiTests.testSendAda.testMnemonic"]!
            .components(separatedBy: " ")
        let sent = expectation(description: "Ada sent")
        let info = NetworkApiInfo(
            networkID: NetworkInfo.testnet.network_id,
            linearFee: try LinearFee(coefficient: 0, constant: 0),
            minimumUtxoVal: 0,
            poolDeposit: 0,
            keyDeposit: 0
        )
        let cardano = try Cardano(
            info: info,
            addresses: SimpleAddressManager(),
            utxos: NonCachingUtxoProvider(),
            signer: Keychain(
                mnemonic: testMnemonic,
                password: Data()
            ),
            network: BlockfrostNetworkProvider(config: BlockfrostConfig(
                basePath: "https://cardano-testnet.blockfrost.io/api/v0"
            ))
        )
        cardano.addresses.accounts { res in
            let accounts = try! res.get()
            let account = accounts[0]
            cardano.addresses.fetch(for: [account]) { res in
                try! res.get()
                let addresses = try! cardano.addresses.get(cached: account)
                let from = addresses.first!
                let to = addresses.count < 100
                    ? try! cardano.addresses.new(for: account, change: false)
                    : addresses.randomElement()!
                let change = try! cardano.addresses.new(for: account, change: true)
                let amount1: UInt64 = 100
                cardano.send.ada(to: to, amount: amount1, from: [from], change: change) { res in
                    let transactionHash = try! res.get()
                    cardano.tx.get(hash: transactionHash) { res in
                        let chainTransaction = try! res.get()
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
        }
        wait(for: [sent], timeout: 10)
    }
    
    func testSendAdaFromAccount() throws {
        let success = expectation(description: "success")
        let info = NetworkApiInfo(
            networkID: NetworkInfo.testnet.network_id,
            linearFee: try LinearFee(coefficient: 0, constant: 0),
            minimumUtxoVal: 0,
            poolDeposit: 0,
            keyDeposit: 0
        )
        let cardano = try Cardano(
            info: info,
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
        let info = NetworkApiInfo(
            networkID: NetworkInfo.testnet.network_id,
            linearFee: try LinearFee(coefficient: 0, constant: 0),
            minimumUtxoVal: 0,
            poolDeposit: 0,
            keyDeposit: 0
        )
        let cardano = try Cardano(
            info: info,
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
