//
//  Account.swift
//  
//
//  Created by Yehor Popovych on 27.10.2021.
//

import Foundation

public struct Account {
    public let pubKey: Bip32PublicKey
    public let index: UInt32
    
    public init(bytes: Data, index: UInt32) throws {
        pubKey = try Bip32PublicKey(bytes: bytes)
        self.index = index
    }
    
    public var path: Bip32Path {
        try! Bip32Path.prefix.appending(index, hard: true)
    }
}
