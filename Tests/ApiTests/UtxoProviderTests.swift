//
//  UtxoProviderTests.swift
//  
//
//  Created by Ostap Danylovych on 06.11.2021.
//

import Foundation
import XCTest
@testable import Cardano

final class UtxoProviderTests: XCTestCase {
    private struct TestSigner: SignatureProvider {
        func accounts(_ cb: @escaping (Result<[Account], Error>) -> Void) {}
        
        func sign(tx: ExtendedTransaction,
                  _ cb: @escaping (Result<Transaction, Error>) -> Void) {}
    }
    
    private static var testAddress: Address {
        get throws {
            try Address(bech32: "addr_test1qz2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzer3jcu5d8ps7zex2k2xt3uqxgjqnnj83ws8lhrn648jjxtwq2ytjqp")
        }
    }
    
    private static var testUtxo: UTXO {
        get throws {
            UTXO(
                address: try testAddress,
                txHash: try TransactionHash(bytes: Data(count: 32)),
                index: 1,
                value: Value(coin: 1)
            )
        }
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
            guard try! addresses[0] == testAddress, page == 0 else {
                return
            }
            cb(.success([try! testUtxo]))
        }
        
        func getUtxos(for transaction: TransactionHash,
                      _ cb: @escaping (Result<[UTXO], Error>) -> Void) {
            guard try! transaction.bytes() == testUtxo.txHash.bytes() else {
                return
            }
            cb(.success([try! testUtxo]))
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
        getUtxos(iterator: cardano.utxos.get(for: [try Self.testAddress], asset: nil), all: []) { res in
            let utxos = try! res.get()
            let utxo = utxos[0]
            XCTAssertEqual(utxo, try! Self.testUtxo)
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
        cardano.utxos.get(for: try Self.testUtxo.txHash) { res in
            let utxos = try! res.get()
            let utxo = utxos[0]
            XCTAssertEqual(utxo, try! Self.testUtxo)
            success.fulfill()
        }
        wait(for: [success], timeout: 10)
    }
}
