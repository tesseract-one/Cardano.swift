//
//  BaseAddress.swift
//  
//
//  Created by Ostap Danylovych on 11.05.2021.
//

import Foundation
import CCardano

public typealias BaseAddress = CCardano.BaseAddress

extension BaseAddress: CType {}

extension BaseAddress {
    public init?(address: Address) {
        switch address {
        case .base(let addr): self = addr
        default: return nil
        }
    }
    
    public init(network: NetworkId, payment: StakeCredential, stake: StakeCredential) {
        self = payment.withCCredential { payment in
            stake.withCCredential { stake in
                Self(network: network, payment: payment, stake: stake)
            }
        }
    }
    
    public func payment() -> StakeCredential {
        payment.copied()
    }
    
    public func stake() -> StakeCredential {
        stake.copied()
    }
    
    public func toAddress() throws -> Address {
        return .base(self)
    }
}
