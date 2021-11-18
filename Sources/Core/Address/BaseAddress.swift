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
    
    public init(network: UInt8, payment: StakeCredential, stake: StakeCredential) {
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
    
    public func toAddress() -> Address {
        return .base(self)
    }
}

extension BaseAddress: Equatable {
    public static func == (lhs: BaseAddress, rhs: BaseAddress) -> Bool {
        lhs.network == rhs.network
        && lhs.payment == rhs.payment
        && lhs.stake == rhs.stake
    }
}

extension BaseAddress: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(network)
        hasher.combine(payment)
        hasher.combine(stake)
    }
}
