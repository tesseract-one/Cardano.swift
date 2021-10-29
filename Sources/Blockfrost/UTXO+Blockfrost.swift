//
//  UTFO+Blockfrost.swift
//  
//
//  Created by Yehor Popovych on 29.10.2021.
//

import Foundation
import BlockfrostSwiftSDK
#if !COCOAPODS
import Cardano
#endif

extension UTXO {
    public init(address: Address, blockfrost utxo: AddressUtxoContent) throws {
        var value = Value(coin: 0)
        value.multiasset = try Dictionary(uniqueKeysWithValues: utxo.amount.map {
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
            address: address,
            txHash: try TransactionHash(bytes: Data(hex: utxo.txHash)!),
            index: TransactionIndex(utxo.outputIndex),
            value: value
        )
    }
}
