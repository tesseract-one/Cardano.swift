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
    private static let testChangeAmount: UInt64 = 1
    private static let testMnemonic = try! Mnemonic()
    
    private static var testAccount: Account {
        let keychain = try! Keychain(mnemonic: testMnemonic.mnemonic(), password: Data())
        return try! keychain.addAccount(index: 0)
    }
    
    private static var testAddress: Address {
        try! testAccount.baseAddress(
            index: 0,
            change: false,
            networkID: NetworkInfo.testnet.network_id
        ).address
    }
    
    private static var testChangeAddress: Address {
        try! testAccount.baseAddress(
            index: 1,
            change: true,
            networkID: NetworkInfo.testnet.network_id
        ).address
    }
    
    private enum TestError: Error {
        case error(from: String)
    }
    
    private struct TestSigner: SignatureProvider {
        func accounts(_ cb: @escaping (Result<[Account], Error>) -> Void) {}
        
        func sign(tx: ExtendedTransaction,
                  _ cb: @escaping (Result<Transaction, Error>) -> Void) {}
    }
    
    private struct TestAddressManager: AddressManager {
        func accounts(_ cb: @escaping (Result<[Account], Error>) -> Void) {}
        
        func new(for account: Account, change: Bool) throws -> Address {
            throw TestError.error(from: "new")
        }
        
        func get(cached account: Account) throws -> [Address] {
            guard account == testAccount else {
                throw TestError.error(from: "get cached account")
            }
            return [testAddress, testChangeAddress]
        }
        
        func get(for account: Account,
                 _ cb: @escaping (Result<[Address], Error>) -> Void) {
            guard account == testAccount else {
                cb(.failure(TestError.error(from: "get for account")))
                return
            }
            cb(.success([testAddress, testChangeAddress]))
        }
        
        func fetch(for accounts: [Account],
                   _ cb: @escaping (Result<Void, Error>) -> Void) {}
        
        func fetch(_ cb: @escaping (Result<Void, Error>) -> Void) {}
        
        func fetchedAccounts() -> [Account] {
            []
        }
        
        func extended(addresses: [Address]) throws -> [ExtendedAddress] {
            throw TestError.error(from: "extended")
        }
    }
    
    private struct NetworkProviderMock: NetworkProvider {
        func getSlotNumber(_ cb: @escaping (Result<Int?, Error>) -> Void) {}
        
        func getBalance(for address: Address, _ cb: @escaping (Result<UInt64, Error>) -> Void) {
            guard [testAddress, testChangeAddress].contains(address) else {
                cb(.failure(TestError.error(from: "getBalance")))
                return
            }
            if address == testAddress {
                cb(.success(testAmount))
            } else if address == testChangeAddress {
                cb(.success(testChangeAmount))
            }
        }
        
        func getTransactions(for address: Address,
                             _ cb: @escaping (Result<[AddressTransaction], Error>) -> Void) {}
        
        func getTransactionCount(for address: Address,
                                 _ cb: @escaping (Result<Int, Error>) -> Void) {}
        
        func getTransaction(hash: TransactionHash,
                            _ cb: @escaping (Result<ChainTransaction?, Error>) -> Void) {}
        
        func getUtxos(for addresses: [Address],
                      page: Int,
                      _ cb: @escaping (Result<[UTXO], Error>) -> Void) {}
        
        func getUtxos(for transaction: TransactionHash,
                      _ cb: @escaping (Result<[UTXO], Error>) -> Void) {}
        
        func submit(tx: Transaction,
                    _ cb: @escaping (Result<TransactionHash, Error>) -> Void) {}
    }

    func testAdaInAccount() throws {
        let success = expectation(description: "success")
        let cardano = try Cardano(
            info: .testnet,
            signer: TestSigner(),
            network: NetworkProviderMock(),
            addresses: TestAddressManager(),
            utxos: NonCachingUtxoProvider()
        )
        cardano.balance.ada(in: Self.testAccount) { res in
            let amount = try! res.get()
            XCTAssertEqual(amount, Self.testAmount + Self.testChangeAmount)
            success.fulfill()
        }
        wait(for: [success], timeout: 10)
    }

    func testAdaInAccountUpdate() throws {
        let success = expectation(description: "success")
        let cardano = try Cardano(
            info: .testnet,
            signer: TestSigner(),
            network: NetworkProviderMock(),
            addresses: TestAddressManager(),
            utxos: NonCachingUtxoProvider()
        )
        cardano.balance.ada(in: Self.testAccount, update: true) { res in
            let amount = try! res.get()
            XCTAssertEqual(amount, Self.testAmount + Self.testChangeAmount)
            success.fulfill()
        }
        wait(for: [success], timeout: 10)
    }

    func testAdaInAddress() throws {
        let success = expectation(description: "success")
        let cardano = try Cardano(
            info: .testnet,
            signer: TestSigner(),
            network: NetworkProviderMock(),
            addresses: SimpleAddressManager(),
            utxos: NonCachingUtxoProvider()
        )
        cardano.balance.ada(in: Self.testAddress) { res in
            let amount = try! res.get()
            XCTAssertEqual(amount, Self.testAmount)
            success.fulfill()
        }
        wait(for: [success], timeout: 10)
    }
}
