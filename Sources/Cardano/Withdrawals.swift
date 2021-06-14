//
//  Withdrawals.swift
//  
//
//  Created by Ostap Danylovych on 11.06.2021.
//

import Foundation
import CCardano

public typealias Withdrawals = Dictionary<RewardAddress, Coin>

extension CCardano.WithdrawalsKeyValue: CType {}

extension CCardano.WithdrawalsKeyValue: CKeyValue {
    typealias Key = RewardAddress
    typealias Value = Coin
}

extension CCardano.Withdrawals: CArray {
    typealias CElement = CCardano.WithdrawalsKeyValue

    mutating func free() {
        cardano_withdrawals_free(&self)
    }
}
