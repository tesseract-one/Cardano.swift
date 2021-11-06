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
    
    private static var testAccount: Account {
        get throws {
            let mnemonic = try Mnemonic()
            let keychain = try Keychain(mnemonic: mnemonic.mnemonic(), password: Data())
            return try keychain.addAccount(index: 0)
        }
    }
    
    private static var testAddress: Address {
        get throws {
            try testAccount.baseAddress(
                index: 0,
                change: false,
                networkID: NetworkInfo.testnet.network_id
            ).address
        }
    }
    
    private struct TestSigner: SignatureProvider {
        func accounts(_ cb: @escaping (Result<[Account], Error>) -> Void) {}
        
        func sign(tx: ExtendedTransaction,
                  _ cb: @escaping (Result<Transaction, Error>) -> Void) {}
    }
    
    private struct NetworkProviderMock: NetworkProvider {
        func getBalance(for address: Address, _ cb: @escaping (Result<UInt64, Error>) -> Void) {
            guard try! address == testAddress else {
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
            addresses: SimpleAddressManager(),
            utxos: NonCachingUtxoProvider(),
            signer: TestSigner(),
            network: NetworkProviderMock()
        )
        let balance = try CardanoBalanceApi(cardano: cardano)
        balance.ada(in: try Self.testAccount) { res in
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
            network: NetworkProviderMock()
        )
        let balance = try CardanoBalanceApi(cardano: cardano)
        balance.ada(in: try Self.testAddress) { res in
            let amount = try! res.get()
            XCTAssertEqual(amount, Self.testAmount)
            success.fulfill()
        }
        wait(for: [success], timeout: 10)
    }
}
