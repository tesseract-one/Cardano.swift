//
//  ExtendedTransaction.swift
//  
//
//  Created by Ostap Danylovych on 29.10.2021.
//

import Foundation

public struct ExtendedTransaction {
    public let tx: TransactionBody
    public let addresses: [ExtendedAddress]
    public let metadata: TransactionMetadata?
    
    public init(tx: TransactionBody, addresses: [ExtendedAddress], metadata: TransactionMetadata?) {
        self.tx = tx
        self.addresses = addresses
        self.metadata = metadata
    }
}
