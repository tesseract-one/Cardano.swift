//
//  StakeCredential.swift
//  
//
//  Created by Yehor Popovych on 23.02.2021.
//

import Foundation
import CCardano

public typealias Ed25519KeyHash = CCardano.Ed25519KeyHash
public typealias ScriptHash = CCardano.ScriptHash

extension Ed25519KeyHash: CType {}

extension Ed25519KeyHash {
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { res, err in
                cardano_ed25519_key_hash_from_bytes(bytes, res, err)
            }
        }.get()
    }
    
    public func data() throws -> Data {
        var data = try RustResult<CData>.wrap { res, err in
            cardano_ed25519_key_hash_to_bytes(self, res, err)
        }.get()
        return data.owned()
    }
    
    public var bytesArray: [UInt8] {
        withUnsafeBytes(of: bytes) { ptr in
            Array(ptr.bindMemory(to: UInt8.self).prefix(Int(self.len)))
        }
    }
}

extension Ed25519KeyHash: Equatable {
    public static func == (lhs: Ed25519KeyHash, rhs: Ed25519KeyHash) -> Bool {
        lhs.len == rhs.len && lhs.bytesArray == rhs.bytesArray
    }
}

extension Ed25519KeyHash: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(len)
        hasher.combine(bytesArray)
    }
}

public typealias Ed25519KeyHashes = Array<Ed25519KeyHash>

extension CCardano.Ed25519KeyHashes: CArray {
    typealias CElement = Ed25519KeyHash
    typealias Val = [Ed25519KeyHash]

    mutating func free() {
        cardano_ed25519_key_hashes_free(&self)
    }
}

extension Ed25519KeyHashes {
    func withCArray<T>(fn: @escaping (CCardano.Ed25519KeyHashes) throws -> T) rethrows -> T {
        try withCArr(fn: fn)
    }
}

extension ScriptHash: CType {}

extension ScriptHash {
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { res, err in
                cardano_script_hash_from_bytes(bytes, res, err)
            }
        }.get()
    }
    
    public func data() throws -> Data {
        var data = try RustResult<CData>.wrap { res, err in
            cardano_script_hash_to_bytes(self, res, err)
        }.get()
        return data.owned()
    }
    
    public var bytesArray: [UInt8] {
        withUnsafeBytes(of: bytes) { ptr in
            Array(ptr.bindMemory(to: UInt8.self).prefix(Int(self.len)))
        }
    }
}

extension ScriptHash: Equatable {
    public static func == (lhs: ScriptHash, rhs: ScriptHash) -> Bool {
        lhs.len == rhs.len && lhs.bytesArray == rhs.bytesArray
    }
}

extension ScriptHash: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(len)
        hasher.combine(bytesArray)
    }
}

public enum StakeCredential: Equatable, Hashable {
    case keyHash(Ed25519KeyHash)
    case scriptHash(ScriptHash)
    
    public var kind: UInt8 {
        if case .keyHash = self { return 0 }
        return 1
    }
    
    public var scriptHash: ScriptHash? {
        if case .scriptHash(let hash) = self { return hash }
        return nil
    }
    
    public var keyHash: Ed25519KeyHash? {
        if case .keyHash(let hash) = self { return hash }
        return nil
    }
    
    public init(bytes: Data) throws {
        var cred = try CCardano.StakeCredential(bytes: bytes)
        self = cred.owned()
    }
    
    public func data() throws -> Data {
        try withCCredential { try $0.data() }
    }
    
    init(credential: CCardano.StakeCredential) {
        switch credential.tag {
        case Key: self = .keyHash(credential.key)
        case Script: self = .scriptHash(credential.script)
        default: fatalError("Unknown StakeCredential type")
        }
    }
    
    func withCCredential<T>(
        fn: @escaping (CCardano.StakeCredential) throws -> T
    ) rethrows -> T {
        var cred = CCardano.StakeCredential()
        switch self {
        case .keyHash(let hash):
            cred.key = hash
            cred.tag = Key
        case .scriptHash(let hash):
            cred.script = hash
            cred.tag = Script
        }
        return try fn(cred)
    }
}

extension CCardano.StakeCredential: CPtr {
    typealias Val = StakeCredential
    
    func copied() -> StakeCredential {
        StakeCredential(credential: self)
    }
    
    mutating func free() {}
}

extension CCardano.StakeCredential {
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { res, err in
                cardano_stake_credential_from_bytes(bytes, res, err)
            }
        }.get()
    }
    
    public func data() throws -> Data {
        var data = try RustResult<CData>.wrap { res, err in
            cardano_stake_credential_to_bytes(self, res, err)
        }.get()
        return data.owned()
    }
}

extension CCardano.StakeCredential: Equatable {
    public static func == (lhs: CCardano.StakeCredential, rhs: CCardano.StakeCredential) -> Bool {
        lhs.copied() == rhs.copied()
    }
}

extension CCardano.StakeCredential: Hashable {
    public func hash(into hasher: inout Hasher) {
        self.copied().hash(into: &hasher)
    }
}
