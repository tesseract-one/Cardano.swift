//
//  ByronAddress.swift
//  
//
//  Created by Yehor Popovych on 23.02.2021.
//

import Foundation
import CCardano

public class ByronAddress {
    private var address: CCardano.ByronAddress
    
    public init(address: CCardano.ByronAddress) {
        self.address = address
    }
    
    public convenience init(base58: String) throws {
        try self.init(address: CCardano.ByronAddress(base58: base58))
    }
    
    public func base58() throws -> String {
        try address.base58()
    }
    
    public func clone() throws -> ByronAddress {
        return try ByronAddress(address: address.clone())
    }
    
    public func cAddress() throws -> CCardano.ByronAddress {
        try address.clone()
    }
    
    deinit {
        address.free()
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
        try RustResult<CharPtr>.wrap { result, error in
            cardano_byron_address_to_base58(self, result, error)
        }.get()!.string()
    }
    
    public func clone() throws -> Self {
        try RustResult<CCardano.ByronAddress>.wrap { result, error in
            cardano_byron_address_clone(self, result, error)
        }.get()
    }
    
    public mutating func free() {
        cardano_byron_address_free(&self)
    }
}
