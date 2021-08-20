//
//  ProtocolParamUpdate.swift
//  
//
//  Created by Ostap Danylovych on 30.06.2021.
//

import Foundation
import CCardano

public typealias Rational = CCardano.Rational

public typealias Nonce = CCardano.Nonce

extension CCardano.Nonce: CType {}

extension CCardano.Nonce {
    public init(nonceHash: Data) throws {
        self = try nonceHash.withCData { nonceHash in
            RustResult<Self>.wrap { res, err in
                cardano_nonce_new_from_hash(nonceHash, res, err)
            }
        }.get()
    }
    
    public func bytes() throws -> Data {
        var data = try RustResult<CData>.wrap { res, err in
            cardano_nonce_to_bytes(self, res, err)
        }.get()
        return data.owned()
    }
}

public typealias ProtocolVersion = CCardano.ProtocolVersion

extension CCardano.ProtocolVersion: CType {}

public typealias ProtocolVersions = Array<ProtocolVersion>

extension CCardano.ProtocolVersions: CArray {
    typealias CElement = ProtocolVersion

    mutating func free() {
        cardano_protocol_versions_free(&self)
    }
}

extension ProtocolVersions {
    func withCArray<T>(fn: @escaping (CCardano.ProtocolVersions) throws -> T) rethrows -> T {
        try withCArr(fn: fn)
    }
}

extension COption_u32: COption {
    typealias Tag = COption_u32_Tag
    typealias Value = UInt32

    func someTag() -> Tag {
        Some_u32
    }

    func noneTag() -> Tag {
        None_u32
    }
}

extension COption_Epoch: COption {
    typealias Tag = COption_Epoch_Tag
    typealias Value = Epoch

    func someTag() -> Tag {
        Some_Epoch
    }

    func noneTag() -> Tag {
        None_Epoch
    }
}

extension COption_Rational: COption {
    typealias Tag = COption_Rational_Tag
    typealias Value = Rational

    func someTag() -> Tag {
        Some_Rational
    }

    func noneTag() -> Tag {
        None_Rational
    }
}

extension COption_UnitInterval: COption {
    typealias Tag = COption_UnitInterval_Tag
    typealias Value = UnitInterval

    func someTag() -> Tag {
        Some_UnitInterval
    }

    func noneTag() -> Tag {
        None_UnitInterval
    }
}

extension COption_Nonce: COption {
    typealias Tag = COption_Nonce_Tag
    typealias Value = Nonce

    func someTag() -> Tag {
        Some_Nonce
    }

    func noneTag() -> Tag {
        None_Nonce
    }
}

extension COption_ProtocolVersions: COption {
    typealias Tag = COption_ProtocolVersions_Tag
    typealias Value = CCardano.ProtocolVersions

    func someTag() -> Tag {
        Some_ProtocolVersions
    }

    func noneTag() -> Tag {
        None_ProtocolVersions
    }
}

public struct ProtocolParamUpdate {
    public var minfeeA: Coin?
    public var minfeeB: Coin?
    public var maxBlockBodySize: UInt32?
    public var maxTxSize: UInt32?
    public var maxBlockHeaderSize: UInt32?
    public var keyDeposit: Coin?
    public var poolDeposit: Coin?
    public var maxEpoch: Epoch?
    public var nOpt: UInt32?
    public var poolPledgeInfluence: Rational?
    public var expansionRate: UnitInterval?
    public var treasuryGrowthRate: UnitInterval?
    public var d: UnitInterval?
    public var extraEntropy: Nonce?
    public var protocolVersion: ProtocolVersions?
    public var minUtxoValue: Coin?
    
    init(protocolParamUpdate: CCardano.ProtocolParamUpdate) {
        minfeeA = protocolParamUpdate.minfee_a.get()
        minfeeB = protocolParamUpdate.minfee_b.get()
        maxBlockBodySize = protocolParamUpdate.max_block_body_size.get()
        maxTxSize = protocolParamUpdate.max_tx_size.get()
        maxBlockHeaderSize = protocolParamUpdate.max_block_header_size.get()
        keyDeposit = protocolParamUpdate.key_deposit.get()
        poolDeposit = protocolParamUpdate.pool_deposit.get()
        maxEpoch = protocolParamUpdate.max_epoch.get()
        nOpt = protocolParamUpdate.n_opt.get()
        poolPledgeInfluence = protocolParamUpdate.pool_pledge_influence.get()
        expansionRate = protocolParamUpdate.expansion_rate.get()
        treasuryGrowthRate = protocolParamUpdate.treasury_growth_rate.get()
        d = protocolParamUpdate.d.get()
        extraEntropy = protocolParamUpdate.extra_entropy.get()
        protocolVersion = protocolParamUpdate.protocol_version.get()?.copied()
        minUtxoValue = protocolParamUpdate.min_utxo_value.get()
    }
    
    public init() {}
    
    public init(bytes: Data) throws {
        var protocolParamUpdate = try CCardano.ProtocolParamUpdate(bytes: bytes)
        self = protocolParamUpdate.owned()
    }
    
    public func bytes() throws -> Data {
        try withCProtocolParamUpdate { try $0.bytes() }
    }
    
    func clonedCProtocolParamUpdate() throws -> CCardano.ProtocolParamUpdate {
        try withCProtocolParamUpdate { try $0.clone() }
    }
    
    func withCProtocolParamUpdate<T>(
        fn: @escaping (CCardano.ProtocolParamUpdate) throws -> T
    ) rethrows -> T {
        try protocolVersion.withCOption(
            with: { try $0.withCArray(fn: $1) }
        ) { protocolVersion in
            try fn(CCardano.ProtocolParamUpdate(
                minfee_a: minfeeA.cOption(),
                minfee_b: minfeeB.cOption(),
                max_block_body_size: maxBlockBodySize.cOption(),
                max_tx_size: maxTxSize.cOption(),
                max_block_header_size: maxBlockHeaderSize.cOption(),
                key_deposit: keyDeposit.cOption(),
                pool_deposit: poolDeposit.cOption(),
                max_epoch: maxEpoch.cOption(),
                n_opt: nOpt.cOption(),
                pool_pledge_influence: poolPledgeInfluence.cOption(),
                expansion_rate: expansionRate.cOption(),
                treasury_growth_rate: treasuryGrowthRate.cOption(),
                d: d.cOption(),
                extra_entropy: extraEntropy.cOption(),
                protocol_version: protocolVersion,
                min_utxo_value: minUtxoValue.cOption()
            ))
        }
    }
}

extension CCardano.ProtocolParamUpdate: CPtr {
    typealias Val = ProtocolParamUpdate
    
    func copied() -> ProtocolParamUpdate {
        ProtocolParamUpdate(protocolParamUpdate: self)
    }
    
    mutating func free() {
        cardano_protocol_param_update_free(&self)
    }
}

extension CCardano.ProtocolParamUpdate {
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { result, error in
                cardano_protocol_param_update_from_bytes(bytes, result, error)
            }
        }.get()
    }
    
    public func bytes() throws -> Data {
        var bytes = try RustResult<CData>.wrap { bytes, error in
            cardano_protocol_param_update_to_bytes(self, bytes, error)
        }.get()
        return bytes.owned()
    }
    
    public func clone() throws -> Self {
        try RustResult<CCardano.ProtocolParamUpdate>.wrap { result, error in
            cardano_protocol_param_update_clone(self, result, error)
        }.get()
    }
}
