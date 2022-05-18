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
    
    public func stake() throws -> StakeCredential {
        let path = try self.path
            .appending(2)
            .appending(0)
        let stake = try publicKey
            .derive(index: path.path[3])
            .derive(index: path.path[4])
        return StakeCredential.keyHash(try stake.toRawKey().hash())
    }
    
    public func baseAddress(index: UInt32,
                            change: Bool,
                            networkID: UInt8) throws -> ExtendedAddress {
        let path = try self.path
            .appending(change ? 1 : 0)
            .appending(index)
        let payment = StakeCredential.keyHash(
            try publicKey
                .derive(index: path.path[3])
                .derive(index: path.path[4])
                .toRawKey()
                .hash()
        )
        return ExtendedAddress(
            address: BaseAddress(
                network: networkID,
                payment: payment,
                stake: try stake()
            ).toAddress(),
            path: path
        )
    }
}
