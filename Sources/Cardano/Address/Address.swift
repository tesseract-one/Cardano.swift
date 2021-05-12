//
//  Address.swift
//  
//
//  Created by Yehor Popovych on 22.02.2021.
//

import Foundation
import CCardano

public class Address {
    private var address: CCardano.Address
    
    public init(address: CCardano.Address) {
        self.address = address
    }
    
    public convenience init(bytes: Data) throws {
        try self.init(address: CCardano.Address(bytes: bytes))
    }
    
    public convenience init(bech32: String) throws {
        try self.init(address: CCardano.Address(bech32: bech32))
    }
    
    public convenience init(kind: AddressKind) throws {
        try self.init(address: kind.cAddress())
    }
    
    public func kind() throws -> AddressKind {
        try AddressKind(address: address)
    }
    
    public func bytes() throws -> Data {
        try address.bytes()
    }
    
    public func bech32(prefix: Optional<String> = nil) throws -> String {
        try address.bech32(prefix: prefix)
    }
    
    public func networkId() throws -> NetworkId {
        try address.networkId()
    }
    
    public func getAddress() -> CCardano.Address {
        self.address
    }
    
    deinit {
        address.free()
    }
}

extension CCardano.Address {
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<CCardano.Address>.wrap { address, error in
                cardano_address_from_bytes(bytes, address, error)
            }
        }.get()
    }
    
    public init(bech32: String) throws {
        self = try bech32.withCharPtr { bech32 in
            RustResult<CCardano.Address>.wrap { address, error in
                cardano_address_from_bech32(bech32, address, error)
            }
        }.get()
    }
    
    public func bytes() throws -> Data {
        var data = try RustResult<CData>.wrap { data, error in
            cardano_address_to_bytes(self, data, error)
        }.get()
        return data.data()
    }
    
    public func bech32(prefix: Optional<String> = nil) throws -> String {
        let chars = try prefix.withCharPtr { chPtr in
            RustResult<CharPtr>.wrap { out, error in
                cardano_address_to_bech32(self, chPtr, out, error)
            }
        }.get()
        return chars!.string()
    }
    
    public func networkId() throws -> NetworkId {
        try RustResult<NetworkId>.wrap { id, error in
            cardano_address_network_id(self, id, error)
        }.get()
    }
    
    public func clone() throws -> CCardano.Address {
        try RustResult<CCardano.Address>.wrap { result, error in
            cardano_address_clone(self, result, error)
        }.get()
    }
    
    public mutating func free() {
        cardano_address_free(&self)
    }
}
