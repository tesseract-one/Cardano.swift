//
//  PrivateKey.swift
//  
//
//  Created by Ostap Danylovych on 14.05.2021.
//

import Foundation
import CCardano

public class PrivateKey {
    private var privateKey: CCardano.PrivateKey
    
    init(privateKey: CCardano.PrivateKey) {
        self.privateKey = privateKey
    }
    
    public convenience init(extendedBytes bytes: Data) throws {
        try self.init(privateKey: CCardano.PrivateKey(extendedBytes: bytes))
    }
    
    public convenience init(normalBytes bytes: Data) throws {
        try self.init(privateKey: CCardano.PrivateKey(normalBytes: bytes))
    }
    
    public func toPublic() throws -> PublicKey {
        try privateKey.toPublic()
    }
    
    public func bytes() throws -> Data {
        try privateKey.bytes()
    }
    
    public func sign(message: Data) throws -> Ed25519Signature {
        try privateKey.sign(message: message)
    }
    
    public func clone() throws -> PrivateKey {
        return try PrivateKey(privateKey: privateKey.clone())
    }
    
    deinit {
        privateKey.free()
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
