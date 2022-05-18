//
//  MoveInstantaneousRewardsCert.swift
//  
//
//  Created by Ostap Danylovych on 24.06.2021.
//

import Foundation
import CCardano
import BigInt

extension CKeyValue_StakeCredential__CInt128: CType {}

extension CKeyValue_StakeCredential__CInt128: CKeyValue {
    typealias Key = CCardano.StakeCredential
    typealias Value = CInt128
}

extension CArray_CKeyValue_StakeCredential__CInt128: CArray {
    typealias CElement = CKeyValue_StakeCredential__CInt128
    typealias Val = [CKeyValue_StakeCredential__CInt128]

    mutating func free() {}
}

extension Dictionary where Key == StakeCredential, Value == BigInt {
    func withCKVArray<T>(fn: @escaping (CArray_CKeyValue_StakeCredential__CInt128) throws -> T) rethrows -> T {
        try withCKVArray(
            withKey: { try $0.withCCredential(fn: $1) },
            withValue: { try $1($0.cInt128) },
            fn: fn
        )
    }
}

public struct MIRToStakeCredentials {
    public let rewards: Dictionary<StakeCredential, BigInt>
    
    init(mirToStakeCredentials: CCardano.MIRToStakeCredentials) {
        rewards = Dictionary(
            uniqueKeysWithValues: mirToStakeCredentials.rewards.copiedDictionary().map { key, value in
                (key.copied(), value.bigInt)
            }
        )
    }
    
    func clonedCMIRToStakeCredentials() throws -> CCardano.MIRToStakeCredentials {
        try withCMIRToStakeCredentials { try $0.clone() }
    }
    
    func withCMIRToStakeCredentials<T>(
        fn: @escaping (CCardano.MIRToStakeCredentials) throws -> T
    ) rethrows -> T {
        try rewards.withCKVArray {
            try fn(CCardano.MIRToStakeCredentials(rewards: $0))
        }
    }
}

extension CCardano.MIRToStakeCredentials: CPtr {
    typealias Val = MIRToStakeCredentials
    
    func copied() -> MIRToStakeCredentials {
        MIRToStakeCredentials(mirToStakeCredentials: self)
    }
    
    mutating func free() {
        cardano_mir_to_stake_credentials_free(&self)
    }
}

extension CCardano.MIRToStakeCredentials {
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_mir_to_stake_credentials_clone(self, result, error)
        }.get()
    }
}

public enum MIREnum {
    case toOtherPot(UInt64)
    case toStakeCredentials(MIRToStakeCredentials)

    init(mirEnum: CCardano.MIREnum) {
        switch mirEnum.tag {
        case ToOtherPot: self = .toOtherPot(mirEnum.to_other_pot)
        case ToStakeCredentials: self = .toStakeCredentials(mirEnum.to_stake_credentials.copied())
        default: fatalError("Unknown MIREnum type")
        }
    }

    func withCMIREnum<T>(
        fn: @escaping (CCardano.MIREnum) throws -> T
    ) rethrows -> T {
        switch self {
        case .toOtherPot(let coin):
            var mirEnum = CCardano.MIREnum()
            mirEnum.tag = ToOtherPot
            mirEnum.to_other_pot = coin
            return try fn(mirEnum)
        case .toStakeCredentials(let mirToStakeCredentials):
            return try mirToStakeCredentials.withCMIRToStakeCredentials { mirToStakeCredentials in
                var mirEnum = CCardano.MIREnum()
                mirEnum.tag = ToStakeCredentials
                mirEnum.to_stake_credentials = mirToStakeCredentials
                return try fn(mirEnum)
            }
        }
    }
}

extension CCardano.MIREnum: CPtr {
    typealias Val = MIREnum
    
    func copied() -> MIREnum {
        MIREnum(mirEnum: self)
    }
    
    mutating func free() {
        cardano_mir_enum_free(&self)
    }
}

extension CCardano.MIREnum {
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_mir_enum_clone(self, result, error)
        }.get()
    }
}

public enum MIRPot {
    case reserves
    case treasury

    init(mirPot: CCardano.MIRPot) {
        switch mirPot {
        case Reserves: self = .reserves
        case Treasury: self = .treasury
        default: fatalError("Unknown MIRPot type")
        }
    }

    func withCMIRPot<T>(
        fn: @escaping (CCardano.MIRPot) throws -> T
    ) rethrows -> T {
        switch self {
        case .reserves: return try fn(Reserves)
        case .treasury: return try fn(Treasury)
        }
    }
}

public struct MoveInstantaneousReward {
    private var pot: MIRPot
    public var variant: MIREnum
    
    init(moveInstantaneousReward: CCardano.MoveInstantaneousReward) {
        pot = MIRPot(mirPot: moveInstantaneousReward.pot)
        variant = moveInstantaneousReward.variant.copied()
    }
    
    public init(pot: MIRPot, amount: Coin) {
        self.pot = pot
        variant = .toOtherPot(amount)
    }
    
    public init(pot: MIRPot, amounts: MIRToStakeCredentials) {
        self.pot = pot
        variant = .toStakeCredentials(amounts)
    }
    
    public init(bytes: Data) throws {
        var moveInstantaneousReward = try CCardano.MoveInstantaneousReward(bytes: bytes)
        self = moveInstantaneousReward.owned()
    }
    
    public func bytes() throws -> Data {
        try withCMoveInstantaneousReward { try $0.bytes() }
    }
    
    func clonedCMoveInstantaneousReward() throws -> CCardano.MoveInstantaneousReward {
        try withCMoveInstantaneousReward { try $0.clone() }
    }
    
    func withCMoveInstantaneousReward<T>(
        fn: @escaping (CCardano.MoveInstantaneousReward) throws -> T
    ) rethrows -> T {
        try pot.withCMIRPot { pot in
            try variant.withCMIREnum { variant in
                try fn(CCardano.MoveInstantaneousReward(pot: pot, variant: variant))
            }
        }
    }
}

extension CCardano.MoveInstantaneousReward: CPtr {
    typealias Val = MoveInstantaneousReward
    
    func copied() -> MoveInstantaneousReward {
        MoveInstantaneousReward(moveInstantaneousReward: self)
    }
    
    mutating func free() {
        cardano_move_instantaneous_reward_free(&self)
    }
}

extension CCardano.MoveInstantaneousReward {
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<CCardano.MoveInstantaneousReward>.wrap { result, error in
                cardano_move_instantaneous_reward_from_bytes(bytes, result, error)
            }
        }.get()
    }
    
    public func bytes() throws -> Data {
        var bytes = try RustResult<CData>.wrap { bytes, error in
            cardano_move_instantaneous_reward_to_bytes(self, bytes, error)
        }.get()
        return bytes.owned()
    }
    
    public func clone() throws -> Self {
        try RustResult<CCardano.MoveInstantaneousReward>.wrap { result, error in
            cardano_move_instantaneous_reward_clone(self, result, error)
        }.get()
    }
}

public struct MoveInstantaneousRewardsCert {
    public private(set) var moveInstantaneousReward: MoveInstantaneousReward
    
    init(mirsCert: CCardano.MoveInstantaneousRewardsCert) {
        moveInstantaneousReward = mirsCert.move_instantaneous_reward.copied()
    }
    
    public init(mir: MoveInstantaneousReward) throws {
        moveInstantaneousReward = mir
    }
    
    func clonedCMoveInstantaneousRewardsCert() throws -> CCardano.MoveInstantaneousRewardsCert {
        try withCMoveInstantaneousRewardsCert { try $0.clone() }
    }
    
    func withCMoveInstantaneousRewardsCert<T>(
        fn: @escaping (CCardano.MoveInstantaneousRewardsCert) throws -> T
    ) rethrows -> T {
        try moveInstantaneousReward.withCMoveInstantaneousReward { mir in
            try fn(CCardano.MoveInstantaneousRewardsCert(move_instantaneous_reward: mir))
        }
    }
}

extension CCardano.MoveInstantaneousRewardsCert: CPtr {
    typealias Val = MoveInstantaneousRewardsCert
    
    func copied() -> MoveInstantaneousRewardsCert {
        MoveInstantaneousRewardsCert(mirsCert: self)
    }
    
    mutating func free() {
        cardano_move_instantaneous_rewards_cert_free(&self)
    }
}

extension CCardano.MoveInstantaneousRewardsCert {
    public func clone() throws -> Self {
        try RustResult<CCardano.MoveInstantaneousRewardsCert>.wrap { result, error in
            cardano_move_instantaneous_rewards_cert_clone(self, result, error)
        }.get()
    }
}
