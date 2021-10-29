//
//  NonCachingUtxoProvider.swift
//  
//
//  Created by Ostap Danylovych on 29.10.2021.
//

import Foundation

public class NonCachingUtxoProvider: UtxoProvider, CardanoBootstrapAware {
    private weak var cardano: CardanoProtocol!
    
    public init() {}
    
    public func bootstrap(cardano: CardanoProtocol) throws {
        self.cardano = cardano
    }
    
    public func get(for addresses: [Address],
                    asset: (PolicyID, AssetName)?) -> UtxoProviderAsyncIterator {
        NonCachingUtxoProviderAsyncIterator(networkProvider: cardano.network,
                                            addresses: addresses,
                                            page: 0)
    }
    
    public func get(id: (tx: TransactionHash, index: TransactionIndex),
             _ cb: @escaping (Result<[UTXO], Error>) -> Void) {
        fatalError("Not implemented")
    }
}

public struct NonCachingUtxoProviderAsyncIterator: UtxoProviderAsyncIterator {
    private static let defaultCount = 100
    
    private let networkProvider: NetworkProvider
    private let addresses: [Address]
    private var page: Int
    
    public init(networkProvider: NetworkProvider, addresses: [Address], page: Int) {
        self.networkProvider = networkProvider
        self.addresses = addresses
        self.page = page
    }
    
    public func next(_ cb: @escaping (Result<[UTXO], Error>, Self?) -> Void) {
        networkProvider.getUtxos(for: addresses, page: page) { res in
            let _ = res.map { utxos in
                cb(res, utxos.count < Self.defaultCount ? nil : Self(
                    networkProvider: networkProvider,
                    addresses: addresses,
                    page: page + 1
                ))
            }
        }
    }
}
