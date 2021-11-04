//
//  Account.swift
//  
//
//  Created by Yehor Popovych on 27.10.2021.
//

import Foundation

public struct Account: Hashable {
    public let publicKey: Bip32PublicKey
    public let index: UInt32
    
    public init(publicKey: Bip32PublicKey, index: UInt32) {
        self.publicKey = publicKey
        self.index = index
    }
    
    public var path: Bip32Path {
        try! Bip32Path.prefix.appending(index, hard: true)
    }
    
    public func derive(index: UInt32, change: Bool) -> ExtendedAddress {
        fatalError("Not implemented")
    }
}
