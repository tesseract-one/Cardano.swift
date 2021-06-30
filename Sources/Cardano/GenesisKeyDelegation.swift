//
//  GenesisKeyDelegation.swift
//  
//
//  Created by Ostap Danylovych on 24.06.2021.
//

import Foundation
import CCardano

public typealias GenesisHash = CCardano.GenesisHash

extension GenesisHash: CType {}

extension GenesisHash {
    public var bytesArray: [UInt8] {
        withUnsafeBytes(of: bytes) { ptr in
            Array(ptr.bindMemory(to: UInt8.self).prefix(Int(self.len)))
        }
    }
}

extension GenesisHash: Equatable {
    public static func == (lhs: GenesisHash, rhs: GenesisHash) -> Bool {
        lhs.len == rhs.len && lhs.bytesArray == rhs.bytesArray
    }
}

extension GenesisHash: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(len)
        hasher.combine(bytesArray)
    }
}

public typealias GenesisDelegateHash = CCardano.GenesisDelegateHash

extension GenesisDelegateHash: CType {}

public typealias VRFKeyHash = CCardano.VRFKeyHash

extension VRFKeyHash: CType {}

public typealias GenesisKeyDelegation = CCardano.GenesisKeyDelegation

extension GenesisKeyDelegation: CType {}
