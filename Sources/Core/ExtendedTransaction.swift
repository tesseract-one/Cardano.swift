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
    public let auxiliaryData: AuxiliaryData?
    
    public init(tx: TransactionBody, addresses: [ExtendedAddress], auxiliaryData: AuxiliaryData?) {
        self.tx = tx
        self.addresses = addresses
        self.auxiliaryData = auxiliaryData
    }
}
