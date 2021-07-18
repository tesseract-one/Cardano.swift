//
//  MoveInstantaneousRewardsCert.swift
//  
//
//  Created by Ostap Danylovych on 24.06.2021.
//

import Foundation
import CCardano

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

extension CKeyValue_StakeCredential__Coin: CType {}

extension CKeyValue_StakeCredential__Coin: CKeyValue {
    typealias Key = CCardano.StakeCredential
    typealias Value = Coin
}

extension CArray_CKeyValue_StakeCredential__Coin: CArray {
    typealias CElement = CKeyValue_StakeCredential__Coin

    mutating func free() {}
}

extension Dictionary where Key == StakeCredential, Value == Coin {
    func withCKVArray<T>(fn: @escaping (CArray_CKeyValue_StakeCredential__Coin) throws -> T) rethrows -> T {
        try Array(self).withContiguousStorageIfAvailable { storage in
            let mapped = storage.map { CKeyValue_StakeCredential__Coin(
                key: $0.key.withCCredential { $0 },
                val: $0.value
            ) }
            return try mapped.withUnsafeBufferPointer {
                try fn(CArray_CKeyValue_StakeCredential__Coin(ptr: $0.baseAddress, len: UInt($0.count)))
            }
        }!
    }
}

public struct MoveInstantaneousReward {
    private var pot: MIRPot
    public var rewards: Dictionary<StakeCredential, Coin>
    
    init(moveInstantaneousReward: CCardano.MoveInstantaneousReward) {
        pot = MIRPot(mirPot: moveInstantaneousReward.pot)
        let rewards = moveInstantaneousReward.rewards.copiedDictionary().map { key, value in
            (key.copied(), value)
        }
        self.rewards = Dictionary(uniqueKeysWithValues: rewards)
    }
    
    public init(pot: MIRPot) {
        self.pot = pot
        rewards = [:]
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
        try fn(CCardano.MoveInstantaneousReward(
            pot: pot.withCMIRPot { $0 }, rewards: rewards.withCKVArray { $0 }
        ))
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
