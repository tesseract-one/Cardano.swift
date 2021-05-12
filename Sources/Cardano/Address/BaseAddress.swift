//
//  BaseAddress.swift
//  
//
//  Created by Ostap Danylovych on 11.05.2021.
//

import Foundation
import CCardano

public class BaseAddress {
    private var address: CCardano.BaseAddress

    public init(address: CCardano.BaseAddress) {
        self.address = address
    }
    
    public convenience init(address: CCardano.Address) throws {
        try self.init(address: CCardano.BaseAddress(address: address))
    }
    
    public static func new(network: NetworkId, payment: StakeCredential, stake: StakeCredential) throws -> BaseAddress {
        try BaseAddress(address: CCardano.BaseAddress.new(network: network, payment: payment, stake: stake))
    }
    
    public func paymentCred() throws -> StakeCredential {
        try address.paymentCred()
    }
    
    public func stakeCred() throws -> StakeCredential {
        try address.stakeCred()
    }
    
    public func toAddress() throws -> CCardano.Address {
        try address.toAddress()
    }
    
    public func cAddress() throws -> CCardano.BaseAddress {
        try address.clone()
    }
}

extension CCardano.BaseAddress {
    public init(address: CCardano.Address) throws {
        self = try RustResult<CCardano.BaseAddress>.wrap { result, error in
            cardano_base_address_from_address(address, result, error)
        }.get()
    }
    
    public static func new(network: NetworkId, payment: StakeCredential, stake: StakeCredential) throws -> Self {
        try RustResult<CCardano.BaseAddress>.wrap { result, error in
            cardano_base_address_new(network, payment, stake, result, error)
        }.get()
    }
    
    public func paymentCred() throws -> StakeCredential {
        try RustResult<CCardano.BaseAddress>.wrap { result, error in
            cardano_base_address_payment_cred(self, result, error)
        }.get()
    }
    
    public func stakeCred() throws -> StakeCredential {
        try RustResult<CCardano.BaseAddress>.wrap { result, error in
            cardano_base_address_stake_cred(self, result, error)
        }.get()
    }
    
    public func toAddress() throws -> CCardano.Address {
        try RustResult<CCardano.BaseAddress>.wrap { result, error in
            cardano_base_address_to_address(self, result, error)
        }.get()
    }
    
    public func clone() throws -> Self {
        try RustResult<CCardano.BaseAddress>.wrap { result, error in
            cardano_base_address_clone(self, result, error)
        }.get()
    }
}
