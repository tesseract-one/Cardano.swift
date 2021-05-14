//
//  Ed25519Signature.swift
//  
//
//  Created by Ostap Danylovych on 13.05.2021.
//

import Foundation
import CCardano

public struct Ed25519Signature {
    private var _signature: Data
    
    init(signature: CCardano.Ed25519Signature) {
        _signature = signature._0.copied()
    }
    
    public init(data: Data) throws {
        var signature = try CCardano.Ed25519Signature(data: data)
        self = signature.owned()
    }
    
    public func data() throws -> Data {
        try withCSignature { try $0.data() }
    }
    
    public func hex() throws -> String {
        try withCSignature { try $0.hex() }
    }
    
    func clonedCSignature() throws -> CCardano.Ed25519Signature {
        try withCSignature { try $0.clone() }
    }
    
    func withCSignature<T>(
        fn: @escaping (CCardano.Ed25519Signature) throws -> T
    ) rethrows -> T {
        try _signature.withCData { data in
            try fn(CCardano.Ed25519Signature(_0: data))
        }
    }
}

extension CCardano.Ed25519Signature: CPtr {
    typealias Value = Ed25519Signature
    
    func copied() -> Ed25519Signature {
        Ed25519Signature(signature: self)
    }
    
    mutating func free() {
        cardano_ed25519_signature_free(&self)
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
        var data = try RustResult<CData>.wrap { result, error in
            cardano_ed25519_signature_to_bytes(self, result, error)
        }.get()
        return data.owned()
    }
    
    public func hex() throws -> String {
        var chars = try RustResult<CharPtr>.wrap { result, error in
            cardano_ed25519_signature_to_hex(self, result, error)
        }.get()
        return chars.owned()
    }
    
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_ed25519_signature_clone(self, result, error)
        }.get()
    }
}
