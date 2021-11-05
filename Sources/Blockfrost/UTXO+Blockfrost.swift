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
        self.init(
            address: address,
            txHash: try TransactionHash(bytes: Data(hex: utxo.txHash)!),
            index: TransactionIndex(utxo.outputIndex),
            value: try Value(blockfrost: utxo.amount.map {
                let dict = $0.value as! [String: String]
                return (unit: dict["unit"]!, quantity: dict["quantity"]!)
            })
        )
    }
    
    public init(blockfrost utxo: TxContentUtxoInputs) throws {
        self.init(
            address: try Address(bech32: utxo.address),
            txHash: try TransactionHash(bytes: Data(hex: utxo.txHash)!),
            index: TransactionIndex(utxo.outputIndex),
            value: try Value(blockfrost: utxo.amount.map {
                (unit: $0.unit, quantity: $0.quantity)
            })
        )
    }
}
