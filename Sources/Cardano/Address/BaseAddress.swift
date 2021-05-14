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
        let address: Optional<Self> = try? address.withCAddress { addr in
            try RustResult<Self>.wrap { result, error in
                cardano_base_address_from_address(addr, result, error)
            }.get()
        }
        guard let addr = address else {
            return nil
        }
        self = addr
    }
    
    public init(network: NetworkId, payment: StakeCredential, stake: StakeCredential) throws {
        self = try RustResult<Self>.wrap { result, error in
            cardano_base_address_new(network, payment, stake, result, error)
        }.get()
    }
    
    public func toAddress() throws -> Address {
        let address = try RustResult<Self>.wrap { result, error in
            cardano_base_address_to_address(self, result, error)
        }.get()
        return Address(address: address)
    }
}
