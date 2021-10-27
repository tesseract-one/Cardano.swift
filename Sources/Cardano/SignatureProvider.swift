//
//  SignatureProvider.swift
//  
//
//  Created by Yehor Popovych on 27.10.2021.
//

import Foundation
#if !COCOAPODS
import CardanoCore
#endif

public struct ExtendedAddress {
    public let address: Address
    public let path: Bip32Path
    
    public init(address: Address, path: Bip32Path) {
        self.address = address
        self.path = path
    }
}

public struct ExtendedTransaction {
    public let tx: TransactionBody
    public let addresses: [ExtendedAddress]
    public let metadata: TransactionMetadata?
}

public protocol SignatureProvider {
    func accounts(_ cb: @escaping (Result<[Account], Error>) -> Void)
    func sign(tx: ExtendedTransaction, _ cb: @escaping (Result<Transaction, Error>) -> Void)
}
