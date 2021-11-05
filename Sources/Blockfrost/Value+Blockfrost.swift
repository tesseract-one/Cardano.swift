//
//  Value+Blockfrost.swift
//  
//
//  Created by Ostap Danylovych on 05.11.2021.
//

import Foundation
#if !COCOAPODS
import Cardano
#endif

extension Value {
    public init(blockfrost amount: [(unit: String, quantity: String)]) throws {
        var coin: UInt64 = 0
        var multiasset: MultiAsset = [:]
        try amount.forEach { asset in
            switch asset.unit {
            case "lovelace":
                coin = UInt64(asset.quantity)!
            default:
                let unit = Data(hex: asset.unit)!
                let policyID = try PolicyID(bytes: unit.subdata(in: (0..<28)))
                let assetName = try AssetName(name: unit.subdata(in: (28..<unit.count)))
                multiasset[policyID] = [assetName: UInt64(asset.quantity)!]
            }
        }
        self.init(coin: coin)
        if !multiasset.isEmpty {
            self.multiasset = multiasset
        }
    }
}
