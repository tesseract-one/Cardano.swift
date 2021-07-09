//
//  PoolRegistration.swift
//  
//
//  Created by Ostap Danylovych on 23.06.2021.
//

import Foundation
import CCardano

public struct PoolRegistration {
    private var _data: Data
    
    init(poolRegistration: CCardano.PoolRegistration) {
        _data = poolRegistration._0.copied()
    }
    
    public init(bytes: Data) throws {
        var poolRegistration = try CCardano.PoolRegistration(bytes: bytes)
        self = poolRegistration.owned()
    }
    
    public func bytes() throws -> Data {
        try withCPoolRegistration { try $0.bytes() }
    }
    
    func clonedCPoolRegistration() throws -> CCardano.PoolRegistration {
        try withCPoolRegistration { try $0.clone() }
    }
    
    func withCPoolRegistration<T>(
        fn: @escaping (CCardano.PoolRegistration) throws -> T
    ) rethrows -> T {
        try _data.withCData { data in
            try fn(CCardano.PoolRegistration(_0: data))
        }
    }
}

extension CCardano.PoolRegistration: CPtr {
    typealias Val = PoolRegistration
    
    func copied() -> PoolRegistration {
        PoolRegistration(poolRegistration: self)
    }
    
    mutating func free() {
        cardano_pool_registration_free(&self)
    }
}

extension CCardano.PoolRegistration {
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { result, error in
                cardano_pool_registration_from_bytes(bytes, result, error)
            }
        }.get()
    }
    
    public func bytes() throws -> Data {
        var bytes = try RustResult<CData>.wrap { bytes, error in
            cardano_pool_registration_to_bytes(self, bytes, error)
        }.get()
        return bytes.owned()
    }
    
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_pool_registration_clone(self, result, error)
        }.get()
    }
}
