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
    typealias Key = CCardano.RewardAddress
    typealias Value = Coin
}

extension CCardano.Withdrawals: CArray {
    typealias CElement = CCardano.WithdrawalsKeyValue
    typealias Val = [CCardano.WithdrawalsKeyValue]

    mutating func free() {
        cardano_withdrawals_free(&self)
    }
}

extension Withdrawals {
    func withCKVArray<T>(fn: @escaping (CCardano.Withdrawals) throws -> T) rethrows -> T {
        try withCKVArray(withKey: { try $0.withCRewardAddress(fn: $1) }, fn: fn)
    }
}
