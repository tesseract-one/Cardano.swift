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

    mutating func free() {
        cardano_withdrawals_free(&self)
    }
}

extension Withdrawals {
    func withCKVArray<T>(fn: @escaping (CCardano.Withdrawals) throws -> T) rethrows -> T {
        try Array(self).withContiguousStorageIfAvailable { storage in
            let mapped = storage.map { CCardano.Withdrawals.CElement(
                key: $0.key.withCRewardAddress { $0 },
                val: $0.value
            ) }
            return try mapped.withUnsafeBufferPointer {
                try fn(CCardano.Withdrawals(ptr: $0.baseAddress, len: UInt($0.count)))
            }
        }!
    }
}
