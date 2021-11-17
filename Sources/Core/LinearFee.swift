//
//  LinearFee.swift
//  
//
//  Created by Ostap Danylovych on 13.05.2021.
//

import Foundation
import CCardano

public typealias LinearFee = CCardano.LinearFee

extension LinearFee: CType {}

extension LinearFee: Equatable, Hashable {
    public static func == (lhs: LinearFee, rhs: LinearFee) -> Bool {
        lhs.coefficient == rhs.coefficient && lhs.constant == rhs.constant
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(constant)
        hasher.combine(coefficient)
    }
}

extension LinearFee {
    public init(coefficient: Coin, constant: Coin) throws {
        self = try RustResult<Self>.wrap { result, error in
            cardano_linear_fee_new(coefficient, constant, result, error)
        }.get()
    }
}
