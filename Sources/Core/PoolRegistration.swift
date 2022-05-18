//
//  PoolRegistration.swift
//  
//
//  Created by Ostap Danylovych on 23.06.2021.
//

import Foundation
import CCardano

public typealias UnitInterval = CCardano.UnitInterval

extension UnitInterval: CType {}

public typealias Ipv4 = CCardano.Ipv4

extension Ipv4: CType {}

extension Ipv4 {
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { res, err in
                cardano_ipv4_from_bytes(bytes, res, err)
            }
        }.get()
    }
    
    public func data() throws -> Data {
        var data = try RustResult<CData>.wrap { res, err in
            cardano_ipv4_to_bytes(self, res, err)
        }.get()
        return data.owned()
    }
}

public typealias Ipv6 = CCardano.Ipv6

extension Ipv6: CType {}

extension Ipv6 {
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { res, err in
                cardano_ipv6_from_bytes(bytes, res, err)
            }
        }.get()
    }
    
    public func data() throws -> Data {
        var data = try RustResult<CData>.wrap { res, err in
            cardano_ipv6_to_bytes(self, res, err)
        }.get()
        return data.owned()
    }
}

extension COption_Port: COption {
    typealias Tag = COption_Port_Tag
    typealias Value = CCardano.Port

    func someTag() -> Tag {
        Some_Port
    }

    func noneTag() -> Tag {
        None_Port
    }
}

extension COption_Ipv4: COption {
    typealias Tag = COption_Ipv4_Tag
    typealias Value = CCardano.Ipv4

    func someTag() -> Tag {
        Some_Ipv4
    }

    func noneTag() -> Tag {
        None_Ipv4
    }
}

extension COption_Ipv6: COption {
    typealias Tag = COption_Ipv6_Tag
    typealias Value = CCardano.Ipv6

    func someTag() -> Tag {
        Some_Ipv6
    }

    func noneTag() -> Tag {
        None_Ipv6
    }
}

public typealias Port = CCardano.Port

public struct SingleHostAddr {
    public private(set) var port: Port?
    public private(set) var ipv4: Ipv4?
    public private(set) var ipv6: Ipv6?
    
    init(singleHostAddr: CCardano.SingleHostAddr) {
        port = singleHostAddr.port.get()
        ipv4 = singleHostAddr.ipv4.get()
        ipv6 = singleHostAddr.ipv6.get()
    }
    
    public init(port: Port, ipv4: Ipv4, ipv6: Ipv6) {
        self.port = port
        self.ipv4 = ipv4
        self.ipv6 = ipv6
    }
    
    func withCSingleHostAddr<T>(
        fn: @escaping (CCardano.SingleHostAddr) throws -> T
    ) rethrows -> T {
        try fn(CCardano.SingleHostAddr(
            port: port.cOption(),
            ipv4: ipv4.cOption(),
            ipv6: ipv6.cOption()
        ))
    }
}

extension CCardano.SingleHostAddr: CPtr {
    typealias Val = SingleHostAddr
    
    func copied() -> SingleHostAddr {
        SingleHostAddr(singleHostAddr: self)
    }
    
    mutating func free() {}
}

public struct DNSRecordAorAAAA {
    public private(set) var record: String

    init(dnsRecordAorAAAA: CCardano.DNSRecordAorAAAA) {
        record = dnsRecordAorAAAA._0.copied()
    }

    public init(dnsName: String) {
        record = dnsName
    }

    func clonedCDNSRecordAorAAAA() throws -> CCardano.DNSRecordAorAAAA {
        try withCDNSRecordAorAAAA { try $0.clone() }
    }

    func withCDNSRecordAorAAAA<T>(
        fn: @escaping (CCardano.DNSRecordAorAAAA) throws -> T
    ) rethrows -> T {
        try record.withCString { record in
            try fn(CCardano.DNSRecordAorAAAA(_0: record))
        }
    }
}

extension CCardano.DNSRecordAorAAAA: CPtr {
    typealias Val = DNSRecordAorAAAA

    func copied() -> DNSRecordAorAAAA {
        DNSRecordAorAAAA(dnsRecordAorAAAA: self)
    }

    mutating func free() {
        cardano_dns_record_aor_aaaa_free(&self)
    }
}

extension CCardano.DNSRecordAorAAAA {
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_dns_record_aor_aaaa_clone(self, result, error)
        }.get()
    }
}

public struct SingleHostName {
    public private(set) var port: Port?
    public private(set) var dnsName: DNSRecordAorAAAA

    init(singleHostName: CCardano.SingleHostName) {
        port = singleHostName.port.get()
        dnsName = singleHostName.dns_name.copied()
    }

    public init(port: Port?, dnsName: DNSRecordAorAAAA) {
        self.port = port
        self.dnsName = dnsName
    }

    func clonedCSingleHostName() throws -> CCardano.SingleHostName {
        try withCSingleHostName { try $0.clone() }
    }

    func withCSingleHostName<T>(
        fn: @escaping (CCardano.SingleHostName) throws -> T
    ) rethrows -> T {
        try dnsName.withCDNSRecordAorAAAA { dnsName in
            try fn(CCardano.SingleHostName(port: port.cOption(), dns_name: dnsName))
        }
    }
}

extension CCardano.SingleHostName: CPtr {
    typealias Val = SingleHostName

    func copied() -> SingleHostName {
        SingleHostName(singleHostName: self)
    }

    mutating func free() {
        cardano_single_host_name_free(&self)
    }
}

extension CCardano.SingleHostName {
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_single_host_name_clone(self, result, error)
        }.get()
    }
}

public struct DNSRecordSRV {
    public private(set) var record: String

    init(dnsRecordSRV: CCardano.DNSRecordSRV) {
        record = dnsRecordSRV._0.copied()
    }

    public init(dnsName: String) {
        record = dnsName
    }

    func clonedCDNSRecordSRV() throws -> CCardano.DNSRecordSRV {
        try withCDNSRecordSRV { try $0.clone() }
    }

    func withCDNSRecordSRV<T>(
        fn: @escaping (CCardano.DNSRecordSRV) throws -> T
    ) rethrows -> T {
        try record.withCString { record in
            try fn(CCardano.DNSRecordSRV(_0: record))
        }
    }
}

extension CCardano.DNSRecordSRV: CPtr {
    typealias Val = DNSRecordSRV

    func copied() -> DNSRecordSRV {
        DNSRecordSRV(dnsRecordSRV: self)
    }

    mutating func free() {
        cardano_dns_record_srv_free(&self)
    }
}

extension CCardano.DNSRecordSRV {
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_dns_record_srv_clone(self, result, error)
        }.get()
    }
}

public struct MultiHostName {
    public private(set) var dnsName: DNSRecordSRV

    init(multiHostName: CCardano.MultiHostName) {
        dnsName = multiHostName.dns_name.copied()
    }

    public init(dnsName: DNSRecordSRV) {
        self.dnsName = dnsName
    }

    func clonedCMultiHostName() throws -> CCardano.MultiHostName {
        try withCMultiHostName { try $0.clone() }
    }

    func withCMultiHostName<T>(
        fn: @escaping (CCardano.MultiHostName) throws -> T
    ) rethrows -> T {
        try dnsName.withCDNSRecordSRV { dnsName in
            try fn(CCardano.MultiHostName(dns_name: dnsName))
        }
    }
}

extension CCardano.MultiHostName: CPtr {
    typealias Val = MultiHostName

    func copied() -> MultiHostName {
        MultiHostName(multiHostName: self)
    }

    mutating func free() {
        cardano_multi_host_name_free(&self)
    }
}

extension CCardano.MultiHostName {
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_multi_host_name_clone(self, result, error)
        }.get()
    }
}

public enum Relay {
    case singleHostAddr(SingleHostAddr)
    case singleHostName(SingleHostName)
    case multiHostName(MultiHostName)
    
    init(relay: CCardano.Relay) {
        switch relay.tag {
        case SingleHostAddrKind: self = .singleHostAddr(relay.single_host_addr_kind.copied())
        case SingleHostNameKind: self = .singleHostName(relay.single_host_name_kind.copied())
        case MultiHostNameKind: self = .multiHostName(relay.multi_host_name_kind.copied())
        default: fatalError("Unknown Relay type")
        }
    }
    
    func clonedCRelay() throws -> CCardano.Relay {
        try withCRelay { try $0.clone() }
    }
    
    func withCRelay<T>(
        fn: @escaping (CCardano.Relay) throws -> T
    ) rethrows -> T {
        switch self {
        case .singleHostAddr(let singleHostAddr):
            return try singleHostAddr.withCSingleHostAddr { singleHostAddr in
                var relay = CCardano.Relay()
                relay.tag = SingleHostAddrKind
                relay.single_host_addr_kind = singleHostAddr
                return try fn(relay)
            }
        case .singleHostName(let singleHostName):
            return try singleHostName.withCSingleHostName { singleHostName in
                var relay = CCardano.Relay()
                relay.tag = SingleHostNameKind
                relay.single_host_name_kind = singleHostName
                return try fn(relay)
            }
        case .multiHostName(let multiHostName):
            return try multiHostName.withCMultiHostName { multiHostName in
                var relay = CCardano.Relay()
                relay.tag = MultiHostNameKind
                relay.multi_host_name_kind = multiHostName
                return try fn(relay)
            }
        }
    }
}

extension CCardano.Relay: CPtr {
    typealias Val = Relay
    
    func copied() -> Relay {
        Relay(relay: self)
    }
    
    mutating func free() {
        cardano_relay_free(&self)
    }
}

extension CCardano.Relay {
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_relay_clone(self, result, error)
        }.get()
    }
}

public typealias Relays = Array<Relay>

extension CCardano.Relays: CArray {
    typealias CElement = CCardano.Relay
    typealias Val = [CCardano.Relay]

    mutating func free() {
        cardano_relays_free(&self)
    }
}

extension Relays {
    func withCArray<T>(fn: @escaping (CCardano.Relays) throws -> T) rethrows -> T {
        try withCArray(with: { try $0.withCRelay(fn: $1) }, fn: fn)
    }
}

public struct URL {
    public private(set) var url: String

    init(url: CCardano.URL) {
        self.url = url._0.copied()
    }

    public init(url: String) {
        self.url = url
    }

    func clonedCURL() throws -> CCardano.URL {
        try withCURL { try $0.clone() }
    }

    func withCURL<T>(
        fn: @escaping (CCardano.URL) throws -> T
    ) rethrows -> T {
        try url.withCString { url in
            try fn(CCardano.URL(_0: url))
        }
    }
}

extension CCardano.URL: CPtr {
    typealias Val = URL

    func copied() -> URL {
        URL(url: self)
    }

    mutating func free() {
        cardano_url_free(&self)
    }
}

extension CCardano.URL {
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_url_clone(self, result, error)
        }.get()
    }
}

public typealias PoolMetadataHash = CCardano.PoolMetadataHash

extension PoolMetadataHash: CType {}

extension PoolMetadataHash {
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { res, err in
                cardano_pool_metadata_hash_from_bytes(bytes, res, err)
            }
        }.get()
    }
    
    public func data() throws -> Data {
        var data = try RustResult<CData>.wrap { res, err in
            cardano_pool_metadata_hash_to_bytes(self, res, err)
        }.get()
        return data.owned()
    }
}

public struct PoolMetadata {
    public private(set) var url: URL
    public private(set) var poolMetadataHash: PoolMetadataHash

    init(poolMetadata: CCardano.PoolMetadata) {
        url = poolMetadata.url.copied()
        poolMetadataHash = poolMetadata.pool_metadata_hash
    }

    public init(url: URL, poolMetadataHash: PoolMetadataHash) {
        self.url = url
        self.poolMetadataHash = poolMetadataHash
    }

    func clonedCPoolMetadata() throws -> CCardano.PoolMetadata {
        try withCPoolMetadata { try $0.clone() }
    }

    func withCPoolMetadata<T>(
        fn: @escaping (CCardano.PoolMetadata) throws -> T
    ) rethrows -> T {
        try url.withCURL { url in
            try fn(CCardano.PoolMetadata(url: url, pool_metadata_hash: poolMetadataHash))
        }
    }
}

extension CCardano.PoolMetadata: CPtr {
    typealias Val = PoolMetadata

    func copied() -> PoolMetadata {
        PoolMetadata(poolMetadata: self)
    }

    mutating func free() {
        cardano_pool_metadata_free(&self)
    }
}

extension CCardano.PoolMetadata {
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_pool_metadata_clone(self, result, error)
        }.get()
    }
}

extension COption_PoolMetadata: COption {
    typealias Tag = COption_PoolMetadata_Tag
    typealias Value = CCardano.PoolMetadata

    func someTag() -> Tag {
        Some_PoolMetadata
    }

    func noneTag() -> Tag {
        None_PoolMetadata
    }
}

public struct PoolParams {
    public private(set) var `operator`: Ed25519KeyHash
    public private(set) var vrfKeyhash: VRFKeyHash
    public private(set) var pledge: Coin
    public private(set) var cost: Coin
    public private(set) var margin: UnitInterval
    public private(set) var rewardAccount: RewardAddress
    public private(set) var poolOwners: Ed25519KeyHashes
    public private(set) var relays: Relays
    public private(set) var poolMetadata: PoolMetadata?

    init(poolParams: CCardano.PoolParams) {
        `operator` = poolParams.operator_
        vrfKeyhash = poolParams.vrf_keyhash
        pledge = poolParams.pledge
        cost = poolParams.cost
        margin = poolParams.margin
        rewardAccount = poolParams.reward_account.copied()
        poolOwners = poolParams.pool_owners.copied()
        relays = poolParams.relays.copied().map { $0.copied() }
        poolMetadata = poolParams.pool_metadata.get()?.copied()
    }

    public init(
        `operator`: Ed25519KeyHash,
        vrfKeyhash: VRFKeyHash,
        pledge: Coin,
        cost: Coin,
        margin: UnitInterval,
        rewardAccount: RewardAddress,
        poolOwners: Ed25519KeyHashes,
        relays: Relays,
        poolMetadata: PoolMetadata?
    ) {
        self.`operator` = `operator`
        self.vrfKeyhash = vrfKeyhash
        self.pledge = pledge
        self.cost = cost
        self.margin = margin
        self.rewardAccount = rewardAccount
        self.poolOwners = poolOwners
        self.relays = relays
        self.poolMetadata = poolMetadata
    }

    func clonedCPoolParams() throws -> CCardano.PoolParams {
        try withCPoolParams { try $0.clone() }
    }

    func withCPoolParams<T>(
        fn: @escaping (CCardano.PoolParams) throws -> T
    ) rethrows -> T {
        try rewardAccount.withCRewardAddress { rewardAccount in
            try poolOwners.withCArray { poolOwners in
                try relays.withCArray { relays in
                    try poolMetadata.withCOption(
                        with: { try $0.withCPoolMetadata(fn: $1) }
                    ) { poolMetadata in
                        try fn(CCardano.PoolParams(
                            operator_: `operator`,
                            vrf_keyhash: vrfKeyhash,
                            pledge: pledge,
                            cost: cost,
                            margin: margin,
                            reward_account: rewardAccount,
                            pool_owners: poolOwners,
                            relays: relays,
                            pool_metadata: poolMetadata
                        ))
                    }
                }
            }
        }
    }
}

extension CCardano.PoolParams: CPtr {
    typealias Val = PoolParams

    func copied() -> PoolParams {
        PoolParams(poolParams: self)
    }

    mutating func free() {
        cardano_pool_params_free(&self)
    }
}

extension CCardano.PoolParams {
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_pool_params_clone(self, result, error)
        }.get()
    }
}

public struct PoolRegistration {
    private var poolParams: PoolParams
    
    init(poolRegistration: CCardano.PoolRegistration) {
        poolParams = poolRegistration.pool_params.copied()
    }
    
    public init(poolParams: PoolParams) {
        self.poolParams = poolParams
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
        try poolParams.withCPoolParams { poolParams in
            try fn(CCardano.PoolRegistration(pool_params: poolParams))
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
