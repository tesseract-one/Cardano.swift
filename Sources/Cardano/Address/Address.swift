//
//  Address.swift
//  
//
//  Created by Yehor Popovych on 22.02.2021.
//

import Foundation
import CCardano

public typealias Pointer = CCardano.Pointer

public struct EnterpriseAddress {
    public init(network: NetworkId, payment: StakeCredential) {
        fatalError()
    }
    
    public func toAddress() throws -> Address {
        fatalError()
    }
}

public struct PointerAddress {
    public init(network: NetworkId, payment: StakeCredential, stake: Pointer) {
        fatalError()
    }
    
    public func toAddress() throws -> Address {
        fatalError()
    }
}

public struct RewardAddress: Equatable, Hashable {
    private var network: NetworkId
    public private(set) var payment: StakeCredential
    
    init(rewardAddress: CCardano.RewardAddress) {
        network = rewardAddress.network
        payment = rewardAddress.payment.copied()
    }
    
    public init(network: NetworkId, payment: StakeCredential) {
        self.network = network
        self.payment = payment
    }
    
    public func toAddress() throws -> Address {
        fatalError()
    }
    
    func withCRewardAddress<T>(
        fn: @escaping (CCardano.RewardAddress) throws -> T
    ) rethrows -> T {
        try payment.withCCredential { payment in
            try fn(CCardano.RewardAddress(network: network, payment: payment))
        }
    }
}

extension CCardano.RewardAddress: Equatable {
    public static func == (lhs: CCardano.RewardAddress, rhs: CCardano.RewardAddress) -> Bool {
        return lhs.copied() == rhs.copied()
    }
}

extension CCardano.RewardAddress: Hashable {
    public func hash(into hasher: inout Hasher) {
        self.copied().hash(into: &hasher)
    }
}

extension CCardano.RewardAddress: CPtr {
    typealias Val = RewardAddress
    
    func copied() -> RewardAddress {
        RewardAddress(rewardAddress: self)
    }
    
    mutating func free() {}
}

public enum Address {
    case base(BaseAddress)
    case pointer(PointerAddress)
    case enterprise(EnterpriseAddress)
    case reward(RewardAddress)
    case byron(ByronAddress)
    
    init(address: CCardano.Address) {
        switch address.tag {
        case Base: self = .base(address.base)
        case Byron: self = .byron(address.byron.copied())
        case Ptr: fatalError()
        case Enterprise: fatalError()
        case Reward: self = .reward(address.reward.copied())
        default: fatalError("Unknown address type")
        }
    }
    
    public init(bytes: Data) throws {
        var address = try CCardano.Address(bytes: bytes)
        self = address.owned()
    }

    public init(bech32: String) throws {
        var address = try CCardano.Address(bech32: bech32)
        self = address.owned()
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
        case .pointer(_):
            var address = CCardano.Address()
            address.tag = Ptr
            fatalError()
        case .enterprise(_):
            var address = CCardano.Address()
            address.tag = Enterprise
            fatalError()
        case .reward(let rew):
            return try rew.withCRewardAddress { rew in
                var address = CCardano.Address()
                address.tag = Reward
                address.reward = rew
                return try fn(address)
            }
        }
    }
}

extension NetworkId: CType {}

extension CCardano.Address: CPtr {
    typealias Val = Address
    
    func copied() -> Address { Address(address: self) }
    
    mutating func free() {
        cardano_address_free(&self)
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
        return data.owned()
    }
    
    public func bech32(prefix: Optional<String> = nil) throws -> String {
        var chars = try prefix.withCharPtr { chPtr in
            RustResult<CharPtr>.wrap { out, error in
                cardano_address_to_bech32(self, chPtr, out, error)
            }
        }.get()
        return chars.owned()
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
}

public func variableNatEncode(num: UInt64) -> Data {
    fatalError()
}

public func variableNatDecode(bytes: Data) -> (UInt64, UInt32) {
    fatalError()
}
