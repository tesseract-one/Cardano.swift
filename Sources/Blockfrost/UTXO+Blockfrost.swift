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
        var coin: UInt64 = 0
        var multiasset: MultiAsset = [:]
        try utxo.amount.forEach {
            let assetData = $0.value as! [String: String]
            let unit = assetData["unit"]!
            let quantity = UInt64(assetData["quantity"]!)!
            switch unit {
            case "lovelace":
                coin = quantity
            default:
                let unit = Data(hex: unit)!
                let policyID = try PolicyID(bytes: unit.subdata(in: (0..<28)))
                let assetName = try AssetName(name: unit.subdata(in: (28..<unit.count)))
                multiasset[policyID] = [assetName: quantity]
            }
        }
        var value = Value(coin: coin)
        if !multiasset.isEmpty {
            value.multiasset = multiasset
        }
        self.init(
            address: address,
            txHash: try TransactionHash(bytes: Data(hex: utxo.txHash)!),
            index: TransactionIndex(utxo.outputIndex),
            value: value
        )
    }
}
