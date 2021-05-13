//
//  PublicKey.swift
//  
//
//  Created by Ostap Danylovych on 13.05.2021.
//

import Foundation
import CCardano

public class PublicKey {
    private var publicKey: CCardano.PublicKey
    
    init(publicKey: CCardano.PublicKey) {
        self.publicKey = publicKey
    }
    
    public convenience init(bech32: String) throws {
        try self.init(publicKey: CCardano.PublicKey(bech32: bech32))
    }
    
    public convenience init(bytes: Data) throws {
        try self.init(publicKey: CCardano.PublicKey(bytes: bytes))
    }
    
    public func bech32() throws -> String {
        try publicKey.bech32()
    }
    
    public func bytes() throws -> Data {
        try publicKey.bytes()
    }
    
    public func hash() throws -> Ed25519KeyHash {
        try publicKey.hash()
    }
    
    public func clone() throws -> PublicKey {
        return try PublicKey(publicKey: publicKey.clone())
    }
    
    deinit {
        publicKey.free()
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
        try RustResult<CharPtr>.wrap { result, error in
            cardano_public_key_to_bech32(self, result, error)
        }.get()!.string()
    }
    
    public func bytes() throws -> Data {
        var data = try RustResult<CData>.wrap { data, error in
            cardano_public_key_as_bytes(self, data, error)
        }.get()
        return data.data()
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
    
    public mutating func free() {
        cardano_public_key_free(&self)
    }
}
