//
//  StakeRegistration.swift
//  
//
//  Created by Ostap Danylovych on 20.06.2021.
//

import Foundation
import CCardano

public typealias StakeRegistration = CCardano.StakeRegistration

extension StakeRegistration: CType {}

extension StakeRegistration {
    public var stakeCredential: StakeCredential {
        StakeCredential(credential: stake_credential)
    }
    
    public init(stakeCredential: StakeCredential) {
        self = stakeCredential.withCCredential { stakeCredential in
            Self(stake_credential: stakeCredential)
        }
    }
}
