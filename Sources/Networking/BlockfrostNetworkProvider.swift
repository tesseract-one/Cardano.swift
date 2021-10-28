//
//  BlockfrostNetworkProvider.swift
//  
//
//  Created by Ostap Danylovych on 28.10.2021.
//

import Foundation
#if !COCOAPODS
import CardanoCore
import BlockfrostSwiftSDK
#endif

public struct BlockfrostNetworkProvider: NetworkProvider {
    private let blockfrost: CardanoAddressesAPI
    
    public init() {
        // TODO: url and project id
        BlockfrostStaticConfig.basePath = "https://cardano-testnet.blockfrost.io/api/v0"
        BlockfrostStaticConfig.projectId = "your-project-id"
        blockfrost = CardanoAddressesAPI()
    }
    
    public func getTransaction(hash: String, _ cb: @escaping (Result<Any, Error>) -> Void) {
        fatalError("Not implemented")
    }
    
    public func getUtxos(for addresses: [Address], _ cb: @escaping (Result<[UTXO], Error>) -> Void) throws {
        try addresses.forEach { address in
            blockfrost.getAddressUtxosAll(address: try address.bech32()) { res in
                res.map { utxos in
                    utxos.map { utxo in
                        
                    }
                }
            }
        }
    }
    
    public func submit(tx: TransactionBody, metadata: TransactionMetadata?, _ cb: @escaping (Result<Transaction, Error>) -> Void) {
        fatalError("Not implemented")
    }
}
