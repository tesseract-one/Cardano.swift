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
    
    private func getUtxos(for addresses: [Address],
                          index: Int,
                          all: [UTXO],
                          page: Int,
                          _ cb: @escaping (Result<[UTXO], Error>) -> Void) throws {
        let _ = blockfrost.getAddressUtxos(
            address: try addresses[index].bech32(),
            page: page
        ) { res in
            do {
                let utxos = try res.get().map { try UTXO(blockfrostUtxo: $0) }
                if index == addresses.count {
                    cb(.success(all + utxos))
                } else {
                    try getUtxos(for: addresses, index: index + 1, all: all + utxos, page: page, cb)
                }
            } catch {
                cb(.failure(error))
            }
        }
    }
    
    public func getTransaction(hash: String, _ cb: @escaping (Result<Any, Error>) -> Void) {
        fatalError("Not implemented")
    }
    
    public func getUtxos(for addresses: [Address],
                         page: Int,
                         _ cb: @escaping (Result<[UTXO], Error>) -> Void) throws {
        try getUtxos(for: addresses, index: 0, all: [], page: page, cb)
    }
    
    public func submit(tx: TransactionBody,
                       metadata: TransactionMetadata?,
                       _ cb: @escaping (Result<Transaction, Error>) -> Void) {
        fatalError("Not implemented")
    }
}

extension UTXO {
    init(blockfrostUtxo: AddressUtxoContent) throws {
        var value = Value(coin: 0)
        value.multiasset = try Dictionary(uniqueKeysWithValues: blockfrostUtxo.amount.map {
            $0.value as! [String: String]
        }.map { dict in
            let unit = dict["unit"]!
            let quantity = UInt64(dict["quantity"]!)!
            switch unit {
            case "lovelace":
                // TODO: policyid, assetname
                return (PolicyID(), [AssetName(): quantity])
            default:
                let unit = Data(hex: unit)!
                let policyID = try PolicyID(bytes: unit.subdata(in: (0..<28)))
                let assetName = try AssetName(name: unit.subdata(in: (28..<unit.count)))
                return (policyID, [assetName: quantity])
            }
        })
        self.init(
            txHash: try TransactionHash(bytes: Data(hex: blockfrostUtxo.txHash)!),
            index: TransactionIndex(blockfrostUtxo.outputIndex),
            value: value
        )
    }
}
