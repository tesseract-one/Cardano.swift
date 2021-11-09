//
//  CardanoTxApiTests.swift
//  
//
//  Created by Ostap Danylovych on 06.11.2021.
//

import Foundation
import XCTest
@testable import Cardano
import Bip39

final class CardanoTxApiTests: XCTestCase {
    private static let testMnemonic = try! Mnemonic()
    
    private static var testAddress: Address {
        let keychain = try! Keychain(mnemonic: testMnemonic.mnemonic(), password: Data())
        let account = try! keychain.addAccount(index: 0)
        return try! account.baseAddress(
            index: 0,
            change: false,
            networkID: NetworkInfo.testnet.network_id
        ).address
    }
    
    private static let testExtendedAddress = ExtendedAddress(
        address: testAddress,
        path: Bip32Path.prefix
    )
    
    private static let testTransactionHash = try! TransactionHash(bytes: Data(count: 32))
    private static let testTransactionHashString = "transactionHashString"
    private static let testChainTransaction = ChainTransaction(
        hash: testTransactionHashString,
        block: "",
        blockHeight: 0,
        slot: 0,
        index: 0,
        outputAmount: [],
        fees: "",
        deposit: "",
        size: 0,
        invalidBefore: nil,
        invalidHereafter: nil,
        utxoCount: 0,
        withdrawalCount: 0,
        mirCertCount: 0,
        delegationCount: 0,
        stakeCertCount: 0,
        poolUpdateCount: 0,
        poolRetireCount: 0,
        assetMintOrBurnCount: 0,
        redeemerCount: 0
    )
    private static let testTransaction = Transaction(
        body: TransactionBody(inputs: [], outputs: [], fee: 0, ttl: nil),
        witnessSet: TransactionWitnessSet(),
        metadata: nil
    )
    
    private enum TestError: Error {
        case error
    }
    
    private struct TestAddressManager: AddressManager {
        func accounts(_ cb: @escaping (Result<[Account], Error>) -> Void) {}
        
        func new(for account: Account, change: Bool) throws -> Address {
            throw TestError.error
        }
        
        func get(cached account: Account) throws -> [Address] {
            throw TestError.error
        }
        
        func get(for account: Account,
                 _ cb: @escaping (Result<[Address], Error>) -> Void) {}
        
        func fetch(for accounts: [Account],
                   _ cb: @escaping (Result<Void, Error>) -> Void) {}
        
        func fetchedAccounts() -> [Account] {
            []
        }
        
        func extended(addresses: [Address]) throws -> [ExtendedAddress] {
            let address = addresses[0]
            guard address == testAddress else {
                throw TestError.error
            }
            return [testExtendedAddress]
        }
    }
    
    private struct TestSigner: SignatureProvider {
        func accounts(_ cb: @escaping (Result<[Account], Error>) -> Void) {}
        
        func sign(tx: ExtendedTransaction,
                  _ cb: @escaping (Result<Transaction, Error>) -> Void) {
            guard try! tx.tx.bytes() == testTransaction.body.bytes(),
                  tx.addresses[0] == testExtendedAddress else {
                return
            }
            cb(.success(testTransaction))
        }
    }
    
    private struct NetworkProviderMock: NetworkProvider {
        func getBalance(for address: Address, _ cb: @escaping (Result<UInt64, Error>) -> Void) {}
        
        func getTransactions(for address: Address,
                             _ cb: @escaping (Result<[AddressTransaction], Error>) -> Void) {}
        
        func getTransactionCount(for address: Address,
                                 _ cb: @escaping (Result<Int, Error>) -> Void) {}
        
        func getTransaction(hash: String,
                            _ cb: @escaping (Result<ChainTransaction, Error>) -> Void) {
            guard hash == testTransactionHashString else {
                return
            }
            cb(.success(testChainTransaction))
        }
        
        func getUtxos(for addresses: [Address],
                      page: Int,
                      _ cb: @escaping (Result<[UTXO], Error>) -> Void) {}
        
        func getUtxos(for transaction: TransactionHash,
                      _ cb: @escaping (Result<[UTXO], Error>) -> Void) {}
        
        func submit(tx: Transaction,
                    _ cb: @escaping (Result<String, Error>) -> Void) {
            guard try! tx.bytes() == testTransaction.bytes() else {
                return
            }
            cb(.success(testTransactionHashString))
        }
    }
    
    func testGetTransaction() throws {
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
            addresses: SimpleAddressManager(),
            utxos: NonCachingUtxoProvider(),
            signer: TestSigner(),
            network: NetworkProviderMock()
        )
        cardano.tx.get(hash: Self.testTransactionHashString) { res in
            let chainTransaction = try! res.get()
            XCTAssertEqual(chainTransaction, Self.testChainTransaction)
            success.fulfill()
        }
        wait(for: [success], timeout: 10)
    }
    
    func testSubmit() throws {
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
            addresses: SimpleAddressManager(),
            utxos: NonCachingUtxoProvider(),
            signer: TestSigner(),
            network: NetworkProviderMock()
        )
        cardano.tx.submit(tx: Self.testTransaction) { res in
            let transactionHash = try! res.get()
            XCTAssertEqual(transactionHash, Self.testTransactionHashString)
            success.fulfill()
        }
        wait(for: [success], timeout: 10)
    }
    
    func testSignAndSubmit() throws {
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
            addresses: TestAddressManager(),
            utxos: NonCachingUtxoProvider(),
            signer: TestSigner(),
            network: NetworkProviderMock()
        )
        cardano.tx.signAndSubmit(
            tx: Self.testTransaction.body,
            with: [Self.testAddress],
            metadata: nil
        ) { res in
            let transactionHash = try! res.get()
            XCTAssertEqual(transactionHash, Self.testTransactionHashString)
            success.fulfill()
        }
        wait(for: [success], timeout: 10)
    }
}
