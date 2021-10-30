//
//  ByronAddress.swift
//  
//
//  Created by Yehor Popovych on 23.02.2021.
//

import Foundation
import CCardano

public struct ByronAddress: Hashable {
    private var _address: String
    
    init(address: CCardano.ByronAddress) {
        _address = address._0.copied()
    }
    
    public init(bytes: Data) throws {
        var address = try CCardano.ByronAddress(bytes: bytes)
        self = address.owned()
    }
    
    public init(base58: String) throws {
        var address = try CCardano.ByronAddress(base58: base58)
        self = address.owned()
    }
    
    public init(key: Bip32PublicKey, protocolMagic: UInt32) throws {
        var address = try CCardano.ByronAddress(key: key, protocolMagic: protocolMagic)
        self = address.owned()
    }
    
    public func base58() throws -> String {
        try withCAddress { try $0.base58() }
    }
    
    public func byronProtocolMagic() throws -> UInt32 {
        try withCAddress { try $0.byronProtocolMagic() }
    }
    
    public func networkId() throws -> UInt8 {
        try withCAddress { try $0.networkId() }
    }
    
    public func bytes() throws -> Data {
        try withCAddress { try $0.bytes() }
    }
    
    static public func isValid(s: String) throws -> Bool {
        try CCardano.ByronAddress.isValid(s: s)
    }
    
    public func toAddress() -> Address {
        return .byron(self)
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
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { res, err in
                cardano_byron_address_from_bytes(bytes, res, err)
            }
        }.get()
    }
    
    public init(base58: String) throws {
        self = try base58.withCharPtr { b58 in
            RustResult<CCardano.ByronAddress>.wrap { result, error in
                cardano_byron_address_from_base58(b58, result, error)
            }
        }.get()
    }
    
    public init(key: Bip32PublicKey, protocolMagic: UInt32) throws {
        self = try RustResult<Self>.wrap { result, error in
            cardano_byron_address_icarus_from_key(key, protocolMagic, result, error)
        }.get()
    }
    
    public func byronProtocolMagic() throws -> UInt32 {
        try RustResult<UInt32>.wrap { result, error in
            cardano_byron_address_byron_protocol_magic(self, result, error)
        }.get()
    }
    
    public func networkId() throws -> UInt8 {
        try RustResult<UInt8>.wrap { result, error in
            cardano_byron_address_network_id(self, result, error)
        }.get()
    }
    
    static public func isValid(s: String) throws -> Bool {
        try s.withCharPtr { s in
            RustResult<Bool>.wrap { result, error in
                cardano_byron_address_is_valid(s, result, error)
            }
        }.get()
    }
    
    public func bytes() throws -> Data {
        var data = try RustResult<CData>.wrap { res, err in
            cardano_byron_address_to_bytes(self, res, err)
        }.get()
        return data.owned()
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
