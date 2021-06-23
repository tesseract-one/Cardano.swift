//
//  MoveInstantaneousRewardsCert.swift
//  
//
//  Created by Ostap Danylovych on 24.06.2021.
//

import Foundation
import CCardano

public struct MoveInstantaneousReward {
    private var _data: Data
    
    init(moveInstantaneousReward: CCardano.MoveInstantaneousReward) {
        _data = moveInstantaneousReward._0.copied()
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
        try _data.withCData { data in
            try fn(CCardano.MoveInstantaneousReward(_0: data))
        }
    }
}

extension CCardano.MoveInstantaneousReward: CPtr {
    typealias Value = MoveInstantaneousReward
    
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
    typealias Value = MoveInstantaneousRewardsCert
    
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
