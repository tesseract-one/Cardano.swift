//
//  PrivateKey.swift
//  
//
//  Created by Ostap Danylovych on 14.05.2021.
//

import Foundation
import CCardano

public enum PrivateKey {
    case extended(Data)
    case normal(Data)
    
    init(privateKey: inout CCardano.PrivateKey) throws {
        defer { privateKey.free() }
        switch privateKey.tag {
        case Extended: self = .extended(privateKey.extended.copied())
        case Normal: self = .normal(privateKey.normal.copied())
        default: throw CardanoRustError.unknown
        }
    }
    
    var isExtended: Bool {
        get {
            if case .extended = self { return true }
            return false
        }
    }
    
    var isNormal: Bool {
        get {
            if case .normal = self { return true }
            return false
        }
    }
    
    public init(extendedBytes bytes: Data) throws {
        var privateKey = try CCardano.PrivateKey(extendedBytes: bytes)
        try self.init(privateKey: &privateKey)
    }
    
    public init(normalBytes bytes: Data) throws {
        var privateKey = try CCardano.PrivateKey(normalBytes: bytes)
        try self.init(privateKey: &privateKey)
    }
    
    public func toPublic() throws -> PublicKey {
        try withCPrivateKey { try $0.toPublic() }
    }
    
    public func bytes() throws -> Data {
        try withCPrivateKey { try $0.bytes() }
    }
    
    public func sign(message: Data) throws -> Ed25519Signature {
        try withCPrivateKey { try $0.sign(message: message) }
    }
    
    func clonedCPrivateKey() throws -> CCardano.PrivateKey {
        try withCPrivateKey { try $0.clone() }
    }
    
    func withCPrivateKey<T>(
        fn: @escaping (CCardano.PrivateKey) throws -> T
    ) rethrows -> T {
        switch self {
        case .extended(let data):
            return try data.withCData { data in
                var privateKey = CCardano.PrivateKey()
                privateKey.tag = Extended
                privateKey.extended = data
                return try fn(privateKey)
            }
        case .normal(let data):
            return try data.withCData { data in
                var privateKey = CCardano.PrivateKey()
                privateKey.tag = Normal
                privateKey.normal = data
                return try fn(privateKey)
            }
        }
    }
}

extension CCardano.PrivateKey {
    public init(extendedBytes bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { result, error in
                cardano_private_key_from_extended_bytes(bytes, result, error)
            }
        }.get()
    }
    
    public init(normalBytes bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { result, error in
                cardano_private_key_from_normal_bytes(bytes, result, error)
            }
        }.get()
    }
    
    public func toPublic() throws -> PublicKey {
        try PublicKey(publicKey: RustResult<CCardano.PublicKey>.wrap { result, error in
            cardano_private_key_to_public(self, result, error)
        }.get())
    }
    
    public func bytes() throws -> Data {
        var data = try RustResult<CData>.wrap { result, error in
            cardano_private_key_as_bytes(self, result, error)
        }.get()
        return data.data()
    }
    
    public func sign(message: Data) throws -> Ed25519Signature {
        try Ed25519Signature(signature: message.withCData { message in
            RustResult<Ed25519Signature>.wrap { result, error in
                cardano_private_key_sign(self, message, result, error)
            }
        }.get())
    }
    
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_private_key_clone(self, result, error)
        }.get()
    }
    
    public mutating func free() {
        cardano_private_key_free(&self)
    }
}
