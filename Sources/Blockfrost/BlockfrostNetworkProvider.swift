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
    
    public init(config: BlockfrostConfig) {
        self.config = config
        addressesApi = CardanoAddressesAPI(config: config)
    }
    
    private func getUtxos(for addresses: [Address],
                          index: Int,
                          all: [UTXO],
                          page: Int,
                          _ cb: @escaping (Result<[UTXO], Error>) -> Void) {
        do {
            let _ = addressesApi.getAddressUtxos(
                address: try addresses[index].bech32(),
                page: page
            ) { res in
                do {
                    let utxos = try res.get().map { try UTXO(address: addresses[index], blockfrost: $0) }
                    if index == addresses.count {
                        cb(.success(all + utxos))
                    } else {
                        getUtxos(for: addresses, index: index + 1, all: all + utxos, page: page, cb)
                    }
                } catch {
                    config.apiResponseQueue.async {
                        cb(.failure(error))
                    }
                }
            }
        } catch {
            config.apiResponseQueue.async {
                cb(.failure(error))
            }
        }
    }
    
    public func getTransaction(hash: String, _ cb: @escaping (Result<Any, Error>) -> Void) {
        fatalError("Not implemented")
    }
    
    public func getUtxos(for addresses: [Address],
                         page: Int,
                         _ cb: @escaping (Result<[UTXO], Error>) -> Void) {
        getUtxos(for: addresses, index: 0, all: [], page: page, cb)
    }
    
    public func submit(tx: TransactionBody,
                       metadata: TransactionMetadata?,
                       _ cb: @escaping (Result<Transaction, Error>) -> Void) {
        fatalError("Not implemented")
    }
}
