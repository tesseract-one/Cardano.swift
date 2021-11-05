//
//  BlockfrostNetworkProvider.swift
//  
//
//  Created by Ostap Danylovych on 28.10.2021.
//

import Foundation
import BlockfrostSwiftSDK
#if !COCOAPODS
import Cardano
#endif

public struct BlockfrostNetworkProvider: NetworkProvider {
    private let config: BlockfrostConfig
    private let addressesApi: CardanoAddressesAPI
    private let transactionsApi: CardanoTransactionsAPI
    
    public init(config: BlockfrostConfig) {
        self.config = config
        addressesApi = CardanoAddressesAPI(config: config)
        transactionsApi = CardanoTransactionsAPI(config: config)
    }
    
    public func getTransactions(for address: Address,
                                _ cb: @escaping (Result<[AddressTransaction], Error>) -> Void) {
        do {
            let _ = addressesApi.getAddressTransactionsAll(address: try address.bech32()) { res in
                cb(res.map { transactions in
                    transactions.map { AddressTransaction(blockfrost: $0) }
                })
            }
        } catch {
            self.config.apiResponseQueue.async {
                cb(.failure(error))
            }
        }
    }
    
    public func getTransactionCount(for address: Address,
                                    _ cb: @escaping (Result<Int, Error>) -> Void) {
        do {
            let _ = addressesApi.getAddressDetails(address: try address.bech32()) { res in
                cb(res.map { $0.txCount })
            }
        } catch {
            self.config.apiResponseQueue.async {
                cb(.failure(error))
            }
        }
    }
    
    public func getTransaction(hash: String,
                               _ cb: @escaping (Result<ChainTransaction, Error>) -> Void) {
        let _ = transactionsApi.getTransaction(hash: hash) { res in
            cb(res.map { ChainTransaction(blockfrost: $0) })
        }
    }
    
    public func getUtxos(for addresses: [Address],
                         page: Int,
                         _ cb: @escaping (Result<[UTXO], Error>) -> Void) {
        let b32Addresses: Array<(Address, String)>
        do {
            b32Addresses = try addresses.map { try ($0, $0.bech32()) }
        } catch {
            self.config.apiResponseQueue.async {
                cb(.failure(error))
            }
            return
        }
        b32Addresses.asyncMap { (addrAndB32, mapped) in
            let (address, b32) = addrAndB32
            let _ = self.addressesApi.getAddressUtxos(
                address: b32,
                page: page
            ) { res in
                let result = res.flatMap { res in
                    Result { try res.map { try UTXO(address: address, blockfrost: $0) } }
                }
                mapped(result)
            }
        }.exec { (res: Result<[[UTXO]], Error>) in
            cb(res.map { utxo in utxo.flatMap { $0 } })
        }
    }
    
    public func getUtxos(for transaction: TransactionHash,
                         _ cb: @escaping (Result<[UTXO], Error>) -> Void) {
        do {
            let _ = transactionsApi.getTransactionUtxos(hash: try transaction.bytes().hex()) { res in
                cb(res.flatMap { txContentUtxo in
                    Result { try txContentUtxo.inputs.map { try UTXO(blockfrost: $0) } }
                })
            }
        } catch {
            self.config.apiResponseQueue.async {
                cb(.failure(error))
            }
        }
    }
    
    public func submit(tx: Transaction,
                       _ cb: @escaping (Result<String, Error>) -> Void) {
        do {
            let _ = transactionsApi.submitTransaction(transaction: try tx.bytes(), completion: cb)
        } catch {
            self.config.apiResponseQueue.async {
                cb(.failure(error))
            }
        }
    }
}
