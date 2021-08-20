//
//  StakeDelegation.swift
//  
//
//  Created by Ostap Danylovych on 20.06.2021.
//

import Foundation
import CCardano

public typealias StakeDelegation = CCardano.StakeDelegation

extension StakeDelegation: CType {}

extension StakeDelegation {
    public var stakeCredential: StakeCredential {
        StakeCredential(credential: stake_credential)
    }
    
    public var poolKeyhash: Ed25519KeyHash {
        pool_keyhash
    }
    
    public init(stakeCredential: StakeCredential, poolKeyhash: Ed25519KeyHash) {
        self = stakeCredential.withCCredential { stakeCredential in
            Self(stake_credential: stakeCredential, pool_keyhash: poolKeyhash)
        }
    }
}
