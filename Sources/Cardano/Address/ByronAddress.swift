//
//  ByronAddress.swift
//  
//
//  Created by Yehor Popovych on 23.02.2021.
//

import Foundation
import CCardano

public struct ByronAddress {
    private var _address: String
    
    init(address: CCardano.ByronAddress) {
        _address = address._0.copied()
    }
    
    public init(base58: String) throws {
        var address = try CCardano.ByronAddress(base58: base58)
        self = address.owned()
    }
    
    public func base58() throws -> String {
        try withCAddress { try $0.base58() }
    }
    
    func clonedCAddress() throws -> CCardano.ByronAddress {
        try withCAddress { try $0.clone() }
    }
    
    func withCAddress<T>(
        fn: @escaping (CCardano.ByronAddress) throws -> T
    ) rethrows -> T {
        try _address.withCString { strPtr in
            try fn(CCardano.ByronAddress(_0: strPtr))
        }
    }
}

extension CCardano.ByronAddress: CPtr {
    typealias Val = ByronAddress
    
    func copied() -> ByronAddress {
        ByronAddress(address: self)
    }
    
    mutating func free() {
        cardano_byron_address_free(&self)
    }
}

extension CCardano.ByronAddress {
    public init(base58: String) throws {
        self = try base58.withCharPtr { b58 in
            RustResult<CCardano.ByronAddress>.wrap { result, error in
                cardano_byron_address_from_base58(b58, result, error)
            }
        }.get()
    }
    
    public func base58() throws -> String {
        var base58 = try RustResult<CharPtr>.wrap { result, error in
            cardano_byron_address_to_base58(self, result, error)
        }.get()
        return base58.owned()
    }
    
    public func clone() throws -> Self {
        try RustResult<CCardano.ByronAddress>.wrap { result, error in
            cardano_byron_address_clone(self, result, error)
        }.get()
    }
}
