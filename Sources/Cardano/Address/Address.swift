//
//  Address.swift
//  
//
//  Created by Yehor Popovych on 22.02.2021.
//

import Foundation
import CCardano

public typealias PointerAddress = CCardano.PointerAddress
public typealias EnterpriseAddress = CCardano.EnterpriseAddress
public typealias RewardAddress = CCardano.RewardAddress

public enum Address {
    case base(BaseAddress)
    case pointer(PointerAddress)
    case enterprise(EnterpriseAddress)
    case reward(RewardAddress)
    case byron(ByronAddress)
    
    init(address: inout CCardano.Address) throws {
        defer { address.free() }
        switch address.tag {
        case Base: self = .base(address.base)
        case Byron:
            var baddr = try address.byron.clone()
            self = .byron(ByronAddress(address: &baddr))
        case Ptr: self = .pointer(address.ptr)
        case Enterprise: self = .enterprise(address.enterprise)
        case Reward: self = .reward(address.reward)
        default: throw CardanoRustError.unknown
        }
    }
    
    public init(bytes: Data) throws {
        var address = try CCardano.Address(bytes: bytes)
        try self.init(address: &address)
    }

    public init(bech32: String) throws {
        var address = try CCardano.Address(bech32: bech32)
        try self.init(address: &address)
    }
    
    var byron: ByronAddress? {
        guard case .byron(let addr) = self else {
            return nil
        }
        return addr
    }
    
    var base: BaseAddress? {
        guard case .base(let addr) = self else {
            return nil
        }
        return addr
    }
    
    var pointer: PointerAddress? {
        guard case .pointer(let addr) = self else {
            return nil
        }
        return addr
    }
    
    var reward: RewardAddress? {
        guard case .reward(let addr) = self else {
            return nil
        }
        return addr
    }
    
    var enterprise: EnterpriseAddress? {
        guard case .enterprise(let addr) = self else {
            return nil
        }
        return addr
    }
    
    public func bytes() throws -> Data {
        try withCAddress { try $0.bytes() }
    }

    public func bech32(prefix: Optional<String> = nil) throws -> String {
        try withCAddress { try $0.bech32(prefix: prefix) }
    }

    public func networkId() throws -> NetworkId {
        try withCAddress { try $0.networkId() }
    }
    
    func clonedCAddress() throws -> CCardano.Address {
        try withCAddress { try $0.clone() }
    }
    
    func withCAddress<T>(
        fn: @escaping (CCardano.Address) throws -> T
    ) rethrows -> T {
        switch self {
        case .base(let base):
            var address = CCardano.Address()
            address.tag = Base
            address.base = base
            return try fn(address)
        case .byron(let byron):
            return try byron.withCAddress { byron in
                var address = CCardano.Address()
                address.tag = Byron
                address.byron = byron
                return try fn(address)
            }
        case .pointer(let ptr):
            var address = CCardano.Address()
            address.tag = Ptr
            address.ptr = ptr
            return try fn(address)
        case .enterprise(let ent):
            var address = CCardano.Address()
            address.tag = Enterprise
            address.enterprise = ent
            return try fn(address)
        case .reward(let rew):
            var address = CCardano.Address()
            address.tag = Reward
            address.reward = rew
            return try fn(address)
        }
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
