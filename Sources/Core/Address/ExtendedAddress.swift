//
//  ExtendedAddress.swift
//  
//
//  Created by Ostap Danylovych on 29.10.2021.
//

import Foundation

public struct ExtendedAddress: Hashable {
    public let address: Address
    public let path: Bip32Path
    
    public init(address: Address, path: Bip32Path) {
        self.address = address
        self.path = path
    }
}
