//
//  CardanoBalanceApiTests.swift
//  
//
//  Created by Ostap Danylovych on 06.11.2021.
//

import Foundation
import XCTest
@testable import Cardano
import Bip39

final class CardanoBalanceApiTests: XCTestCase {
    private static let testAmount: UInt64 = 100
    private let testMnemonic = try! Mnemonic()
    
    private var testAccount: Account {
        let keychain = try! Keychain(mnemonic: testMnemonic.mnemonic(), password: Data())
        return try! keychain.addAccount(index: 0)
    }
    
    private var testAddress: Address {
        return try! testAccount.baseAddress(
            index: 0,
            change: false,
            networkID: NetworkInfo.testnet.network_id
        ).address
    }
    
    private enum TestError: Error {
        case error
    }
    
    private struct TestSigner: SignatureProvider {
        func accounts(_ cb: @escaping (Result<[Account], Error>) -> Void) {}
        
        func sign(tx: ExtendedTransaction,
                  _ cb: @escaping (Result<Transaction, Error>) -> Void) {}
    }
    
    private struct TestAddressManager: AddressManager {
        private let account: Account
        private let address: Address
        
        init(account: Account, address: Address) {
            self.account = account
            self.address = address
        }
        
        func accounts(_ cb: @escaping (Result<[Account], Error>) -> Void) {}
        
        func new(for account: Account, change: Bool) throws -> Address {
            throw TestError.error
        }
        
        func get(cached account: Account, change: Bool) throws -> [Address] {
            guard account == self.account else {
                throw TestError.error
            }
            return [address]
        }
        
        func get(for account: Account, change: Bool,
                 _ cb: @escaping (Result<[Address], Error>) -> Void) {
            guard account == self.account else {
                cb(.failure(TestError.error))
                return
            }
            cb(.success([address]))
        }
        
        func fetch(for accounts: [Account],
                   _ cb: @escaping (Result<Void, Error>) -> Void) {}
        
        func fetchedAccounts() -> [Account] {
            []
        }
        
        func extended(addresses: [Address]) throws -> [ExtendedAddress] {
            throw TestError.error
        }
    }
    
    private struct NetworkProviderMock: NetworkProvider {
        private let address: Address
        
        init(address: Address) {
            self.address = address
        }
        
        func getBalance(for address: Address, _ cb: @escaping (Result<UInt64, Error>) -> Void) {
            guard address == self.address else {
                cb(.failure(TestError.error))
                return
            }
            cb(.success(testAmount))
        }
        
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
                    _ cb: @escaping (Result<String, Error>) -> Void) {}
    }
    
    func testAdaInAccount() throws {
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
            addresses: TestAddressManager(account: testAccount, address: testAddress),
            utxos: NonCachingUtxoProvider(),
            signer: TestSigner(),
            network: NetworkProviderMock(address: testAddress)
        )
        let balance = try CardanoBalanceApi(cardano: cardano)
        balance.ada(in: testAccount) { res in
            let amount = try! res.get()
            XCTAssertEqual(amount, Self.testAmount)
            success.fulfill()
        }
        wait(for: [success], timeout: 10)
    }
    
    func testAdaInAccountUpdate() throws {
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
            addresses: TestAddressManager(account: testAccount, address: testAddress),
            utxos: NonCachingUtxoProvider(),
            signer: TestSigner(),
            network: NetworkProviderMock(address: testAddress)
        )
        let balance = try CardanoBalanceApi(cardano: cardano)
        balance.ada(in: testAccount, update: true) { res in
            let amount = try! res.get()
            XCTAssertEqual(amount, Self.testAmount)
            success.fulfill()
        }
        wait(for: [success], timeout: 10)
    }
    
    func testAdaInAddress() throws {
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
            network: NetworkProviderMock(address: testAddress)
        )
        let balance = try CardanoBalanceApi(cardano: cardano)
        balance.ada(in: testAddress) { res in
            let amount = try! res.get()
            XCTAssertEqual(amount, Self.testAmount)
            success.fulfill()
        }
        wait(for: [success], timeout: 10)
    }
}
