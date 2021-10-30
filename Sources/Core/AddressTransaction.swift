//
//  AddressTransaction.swift
//  
//
//  Created by Ostap Danylovych on 30.10.2021.
//

import Foundation

public struct AddressTransaction {
    public let txHash: String
    public let txIndex: Int
    public let blockHeight: Int
    
    public init(txHash: String, txIndex: Int, blockHeight: Int) {
        self.txHash = txHash
        self.txIndex = txIndex
        self.blockHeight = blockHeight
    }
}
