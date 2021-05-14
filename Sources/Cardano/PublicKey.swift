//
//  PublicKey.swift
//  
//
//  Created by Ostap Danylovych on 13.05.2021.
//

import Foundation
import CCardano

public struct PublicKey {
    private var _publicKey: String
    
    init(publicKey: CCardano.PublicKey) {
        _publicKey = publicKey._0.copied()
    }
    
    public init(bech32: String) throws {
        var publicKey = try CCardano.PublicKey(bech32: bech32)
        self = publicKey.owned()
    }
    
    public init(bytes: Data) throws {
        var publicKey = try CCardano.PublicKey(bytes: bytes)
        self = publicKey.owned()
    }
    
    public func bech32() throws -> String {
        try withCPublicKey { try $0.bech32() }
    }
    
    public func bytes() throws -> Data {
        try withCPublicKey { try $0.bytes() }
    }
    
    public func hash() throws -> Ed25519KeyHash {
        try withCPublicKey { try $0.hash() }
    }
    
    func clonedCPublicKey() throws -> CCardano.PublicKey {
        try withCPublicKey { try $0.clone() }
    }
    
    func withCPublicKey<T>(
        fn: @escaping (CCardano.PublicKey) throws -> T
    ) rethrows -> T {
        try _publicKey.withCharPtr { strPtr in
            try fn(CCardano.PublicKey(_0: strPtr))
        }
    }
}

extension CCardano.PublicKey: CPtr {
    typealias Value = PublicKey
    
    func copied() -> PublicKey {
        PublicKey(publicKey: self)
    }
    
    mutating func free() {
        cardano_public_key_free(&self)
    }
}

extension CCardano.PublicKey {
    public init(bech32: String) throws {
        self = try bech32.withCharPtr { bech32 in
            RustResult<Self>.wrap { result, error in
                cardano_public_key_from_bech32(bech32, result, error)
            }
        }.get()
    }
    
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { address, error in
                cardano_public_key_from_bytes(bytes, address, error)
            }
        }.get()
    }
    
    public func bech32() throws -> String {
        var str = try RustResult<CharPtr>.wrap { result, error in
            cardano_public_key_to_bech32(self, result, error)
        }.get()
        return str.owned()
    }
    
    public func bytes() throws -> Data {
        var data = try RustResult<CData>.wrap { data, error in
            cardano_public_key_as_bytes(self, data, error)
        }.get()
        return data.owned()
    }
    
    public func hash() throws -> Ed25519KeyHash {
        try RustResult<Ed25519KeyHash>.wrap { result, error in
            cardano_public_key_hash(self, result, error)
        }.get()
    }
    
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_public_key_clone(self, result, error)
        }.get()
    }
}
