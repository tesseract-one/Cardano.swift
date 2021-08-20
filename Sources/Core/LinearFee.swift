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

extension LinearFee {
    public init(coefficient: Coin, constant: Coin) throws {
        self = try RustResult<Self>.wrap { result, error in
            cardano_linear_fee_new(coefficient, constant, result, error)
        }.get()
    }
}
