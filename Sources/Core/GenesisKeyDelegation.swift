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
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { res, err in
                cardano_genesis_hash_from_bytes(bytes, res, err)
            }
        }.get()
    }
    
    public func data() throws -> Data {
        var data = try RustResult<CData>.wrap { res, err in
            cardano_genesis_hash_to_bytes(self, res, err)
        }.get()
        return data.owned()
    }
    
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

extension GenesisDelegateHash {
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { res, err in
                cardano_genesis_delegate_hash_from_bytes(bytes, res, err)
            }
        }.get()
    }
    
    public func data() throws -> Data {
        var data = try RustResult<CData>.wrap { res, err in
            cardano_genesis_delegate_hash_to_bytes(self, res, err)
        }.get()
        return data.owned()
    }
}

public typealias VRFKeyHash = CCardano.VRFKeyHash

extension VRFKeyHash: CType {}

extension VRFKeyHash {
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { res, err in
                cardano_vrf_key_hash_from_bytes(bytes, res, err)
            }
        }.get()
    }
    
    public func data() throws -> Data {
        var data = try RustResult<CData>.wrap { res, err in
            cardano_vrf_key_hash_to_bytes(self, res, err)
        }.get()
        return data.owned()
    }
}

public typealias GenesisKeyDelegation = CCardano.GenesisKeyDelegation

extension GenesisKeyDelegation: CType {}
