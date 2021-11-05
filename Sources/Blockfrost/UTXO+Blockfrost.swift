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
    private static func toValue(utxoAmount: [[String: String]]) throws -> Value {
        var coin: UInt64 = 0
        var multiasset: MultiAsset = [:]
        try utxoAmount.forEach { assetData in
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
        return value
    }
    
    public init(address: Address, blockfrost utxo: AddressUtxoContent) throws {
        self.init(
            address: address,
            txHash: try TransactionHash(bytes: Data(hex: utxo.txHash)!),
            index: TransactionIndex(utxo.outputIndex),
            value: try Self.toValue(utxoAmount: utxo.amount.map {
                $0.value as! [String: String]
            })
        )
    }
    
    public init(blockfrost utxo: TxContentUtxoInputs) throws {
        self.init(
            address: try Address(bech32: utxo.address),
            txHash: try TransactionHash(bytes: Data(hex: utxo.txHash)!),
            index: TransactionIndex(utxo.outputIndex),
            value: try Self.toValue(utxoAmount: utxo.amount.map { [
                "unit": $0.unit, "quantity": $0.quantity
            ] })
        )
    }
}
