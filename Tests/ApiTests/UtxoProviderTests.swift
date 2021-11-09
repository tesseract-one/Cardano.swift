//
//  UtxoProviderTests.swift
//  
//
//  Created by Ostap Danylovych on 06.11.2021.
//

import Foundation
import XCTest
@testable import Cardano
import Bip39

final class UtxoProviderTests: XCTestCase {
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
    
    private static let testUtxo = UTXO(
        address: testAddress,
        txHash: try! TransactionHash(bytes: Data(count: 32)),
        index: 1,
        value: Value(coin: 1)
    )
    
    private enum TestError: Error {
        case error(from: String)
    }
    
    private struct TestSigner: SignatureProvider {
        func accounts(_ cb: @escaping (Result<[Account], Error>) -> Void) {}
        
        func sign(tx: ExtendedTransaction,
                  _ cb: @escaping (Result<Transaction, Error>) -> Void) {}
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
                      _ cb: @escaping (Result<[UTXO], Error>) -> Void) {
            guard addresses[0] == testAddress, page == 0 else {
                cb(.failure(TestError.error(from: "getUtxos for addresses")))
                return
            }
            cb(.success([testUtxo]))
        }
        
        func getUtxos(for transaction: TransactionHash,
                      _ cb: @escaping (Result<[UTXO], Error>) -> Void) {
            guard try! transaction.bytes() == testUtxo.txHash.bytes() else {
                cb(.failure(TestError.error(from: "getUtxos for transaction")))
                return
            }
            cb(.success([testUtxo]))
        }
        
        func submit(tx: Transaction,
                    _ cb: @escaping (Result<String, Error>) -> Void) {}
    }
    
    private func getUtxos(iterator: UtxoProviderAsyncIterator,
                          all: [UTXO],
                          _ cb: @escaping (Result<[UTXO], Error>) -> Void) {
        iterator.next { (res, iterator) in
            switch res {
            case .success(let utxos):
                let all = all + utxos
                guard let iterator = iterator else {
                    cb(.success(all))
                    return
                }
                self.getUtxos(iterator: iterator, all: all, cb)
            case .failure(let error):
                cb(.failure(error))
            }
        }
    }
    
    func testGetForAddresses() throws {
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
        getUtxos(iterator: cardano.utxos.get(for: [Self.testAddress], asset: nil), all: []) { res in
            let utxos = try! res.get()
            let utxo = utxos[0]
            XCTAssertEqual(utxo, Self.testUtxo)
            success.fulfill()
        }
        wait(for: [success], timeout: 10)
    }
    
    func testGetForTransaction() throws {
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
        cardano.utxos.get(for: Self.testUtxo.txHash) { res in
            let utxos = try! res.get()
            let utxo = utxos[0]
            XCTAssertEqual(utxo, Self.testUtxo)
            success.fulfill()
        }
        wait(for: [success], timeout: 10)
    }
}
