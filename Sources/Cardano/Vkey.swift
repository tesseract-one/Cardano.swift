//
//  Vkey.swift
//  
//
//  Created by Ostap Danylovych on 07.06.2021.
//

import Foundation
import CCardano

public struct Vkey {
    public private(set) var publicKey: PublicKey
    
    init(vkey: CCardano.Vkey) {
        publicKey = vkey._0.copied()
    }
    
    public init(publicKey: PublicKey) throws {
        self.publicKey = publicKey
    }
    
    public init(bytes: Data) throws {
        var vkey = try CCardano.Vkey(bytes: bytes)
        self = vkey.owned()
    }
    
    public func bytes() throws -> Data {
        try withCVkey { try $0.bytes() }
    }
    
    func clonedCVkey() throws -> CCardano.Vkey {
        try withCVkey { try $0.clone() }
    }
    
    func withCVkey<T>(
        fn: @escaping (CCardano.Vkey) throws -> T
    ) rethrows -> T {
        try publicKey.withCPublicKey { publicKey in
            try fn(CCardano.Vkey(_0: publicKey))
        }
    }
}

extension CCardano.Vkey: CPtr {
    typealias Value = Vkey
    
    func copied() -> Vkey {
        Vkey(vkey: self)
    }
    
    mutating func free() {
        cardano_vkey_free(&self)
    }
}

extension CCardano.Vkey {
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { result, error in
                cardano_vkey_from_bytes(bytes, result, error)
            }
        }.get()
    }
    
    public func bytes() throws -> Data {
        var data = try RustResult<CData>.wrap { data, error in
            cardano_vkey_to_bytes(self, data, error)
        }.get()
        return data.owned()
    }
    
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_vkey_clone(self, result, error)
        }.get()
    }
}
