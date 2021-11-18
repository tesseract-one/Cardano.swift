//
//  RewardAddress.swift
//  
//
//  Created by Ostap Danylovych on 09.08.2021.
//

import Foundation
import CCardano

public struct RewardAddress: Equatable, Hashable {
    private var network: UInt8
    public private(set) var payment: StakeCredential
    
    init(rewardAddress: CCardano.RewardAddress) {
        network = rewardAddress.network
        payment = rewardAddress.payment.copied()
    }
    
    public init(network: UInt8, payment: StakeCredential) {
        self.network = network
        self.payment = payment
    }
    
    public func toAddress() -> Address {
        return .reward(self)
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
