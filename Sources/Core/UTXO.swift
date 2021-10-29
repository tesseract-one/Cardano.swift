//
//  UTXO.swift
//  
//
//  Created by Yehor Popovych on 27.10.2021.
//

import Foundation

public struct UTXO {
    public let address: Address
    public let txHash: TransactionHash
    public let index: TransactionIndex
    public let value: Value
    
    public init(address: Address, txHash: TransactionHash, index: TransactionIndex, value: Value) {
        self.address = address
        self.txHash = txHash
        self.index = index
        self.value = value
    }
}
