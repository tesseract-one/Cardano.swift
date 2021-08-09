//
//  EnterpriseAddress.swift
//  
//
//  Created by Ostap Danylovych on 09.08.2021.
//

import Foundation
import CCardano

public struct EnterpriseAddress {
    private var network: NetworkId
    public private(set) var payment: StakeCredential
    
    init(enterpriseAddress: CCardano.EnterpriseAddress) {
        network = enterpriseAddress.network
        payment = enterpriseAddress.payment.copied()
    }
    
    public init(network: NetworkId, payment: StakeCredential) {
        self.network = network
        self.payment = payment
    }
    
    public func toAddress() throws -> Address {
        fatalError()
    }
    
    func withCEnterpriseAddress<T>(
        fn: @escaping (CCardano.EnterpriseAddress) throws -> T
    ) rethrows -> T {
        try payment.withCCredential { payment in
            try fn(CCardano.EnterpriseAddress(network: network, payment: payment))
        }
    }
}

extension CCardano.EnterpriseAddress: CPtr {
    typealias Val = EnterpriseAddress
    
    func copied() -> EnterpriseAddress {
        EnterpriseAddress(enterpriseAddress: self)
    }
    
    mutating func free() {}
}
