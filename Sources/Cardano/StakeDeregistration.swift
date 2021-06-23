//
//  StakeDeregistration.swift
//  
//
//  Created by Ostap Danylovych on 23.06.2021.
//

import Foundation
import CCardano

public typealias StakeDeregistration = CCardano.StakeDeregistration

extension StakeDeregistration: CType {}

extension StakeDeregistration {
    public var stakeCredential: StakeCredential {
        StakeCredential(credential: stake_credential)
    }
    
    public init(stakeCredential: StakeCredential) {
        self = stakeCredential.withCCredential { stakeCredential in
            Self(stake_credential: stakeCredential)
        }
    }
}
