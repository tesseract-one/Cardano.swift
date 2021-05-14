//
//  BaseAddress.swift
//  
//
//  Created by Ostap Danylovych on 11.05.2021.
//

import Foundation
import CCardano

public typealias BaseAddress = CCardano.BaseAddress

extension BaseAddress {
    public init(address: Address) throws {
        self = try address.withCAddress { addr in
            try RustResult<Self>.wrap { result, error in
                cardano_base_address_from_address(addr, result, error)
            }.get()
        }
    }
    
    public init(network: NetworkId, payment: StakeCredential, stake: StakeCredential) throws {
        self = try RustResult<Self>.wrap { result, error in
            cardano_base_address_new(network, payment, stake, result, error)
        }.get()
    }
    
    public func toAddress() throws -> Address {
        var address = try RustResult<Self>.wrap { result, error in
            cardano_base_address_to_address(self, result, error)
        }.get()
        return try Address(address: &address)
    }
}
