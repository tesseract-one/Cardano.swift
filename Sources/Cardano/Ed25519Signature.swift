//
//  Ed25519Signature.swift
//  
//
//  Created by Ostap Danylovych on 13.05.2021.
//

import Foundation
import CCardano

public class Ed25519Signature {
    private var signature: CCardano.Ed25519Signature
    
    public init(signature: CCardano.Ed25519Signature) {
        self.signature = signature
    }
    
    public convenience init(data: Data) throws {
        try self.init(signature: CCardano.Ed25519Signature(data: data))
    }
    
    public func data() throws -> Data {
        try signature.data()
    }
    
    public func hex() throws -> String {
        try signature.hex()
    }
    
    public func clone() throws -> Ed25519Signature {
        return try Ed25519Signature(signature: signature.clone())
    }
    
    deinit {
        signature.free()
    }
}

extension CCardano.Ed25519Signature {
    public init(data: Data) throws {
        self = try data.withCData { bytes in
            RustResult<Self>.wrap { result, error in
                cardano_ed25519_signature_from_bytes(bytes, result, error)
            }
        }.get()
    }
    
    public func data() throws -> Data {
        var data = try RustResult<Self>.wrap { result, error in
            cardano_ed25519_signature_to_bytes(self, result, error)
        }.get()
        return data.data()
    }
    
    public func hex() throws -> String {
        let chars = try RustResult<Self>.wrap { result, error in
            cardano_ed25519_signature_to_hex(self, result, error)
        }.get()
        return chars!.string()
    }
    
    public func clone() throws -> Self {
        try RustResult<CCardano.Ed25519Signature>.wrap { result, error in
            cardano_ed25519_signature_clone(self, result, error)
        }.get()
    }
    
    public mutating func free() {
        cardano_ed25519_signature_free(&self)
    }
}
