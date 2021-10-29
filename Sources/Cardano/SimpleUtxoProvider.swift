//
//  SimpleUtxoProvider.swift
//  
//
//  Created by Ostap Danylovych on 29.10.2021.
//

import Foundation
#if !COCOAPODS
import CardanoNetworking
#endif

public class SimpleUtxoProvider: UtxoProvider {
    private var networkProvider: NetworkProvider
    
    public init(networkProvider: NetworkProvider) {
        self.networkProvider = networkProvider
    }
    
    public func get(for addresses: [Address],
                    asset: (PolicyID, AssetName)?) -> UtxoProviderAsyncIterator {
        SimpleUtxoProviderAsyncIterator(networkProvider: networkProvider, addresses: addresses)
    }
    
    public func get(id: (tx: TransactionHash, index: TransactionIndex),
             _ cb: @escaping (Result<[UTXO], Error>) -> Void) {
        fatalError("Not implemented")
    }
}

public class SimpleUtxoProviderAsyncIterator: UtxoProviderAsyncIterator {
    private static let defaultCount = 100
    
    private let networkProvider: NetworkProvider
    private let addresses: [Address]
    private var page: Int
    
    public init(networkProvider: NetworkProvider, addresses: [Address]) {
        self.networkProvider = networkProvider
        self.addresses = addresses
        page = 0
    }
    
    public func next(_ cb: @escaping (Result<[UTXO], Error>, UtxoProviderAsyncIterator?) -> Void) throws {
        page += 1
        try networkProvider.getUtxos(for: addresses, page: page) { res in
            let _ = res.map { utxos in
                cb(res, utxos.count < Self.defaultCount ? nil : self)
            }
        }
    }
    
    public func next(limit: Int,
                     _ cb: @escaping (Result<[UTXO], Error>, UtxoProviderAsyncIterator?) -> Void) throws {
        fatalError("Not implemented")
    }
}
