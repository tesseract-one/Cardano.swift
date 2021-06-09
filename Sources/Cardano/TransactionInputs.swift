//
//  TransactionInputs.swift
//  
//
//  Created by Ostap Danylovych on 09.06.2021.
//

import Foundation
import CCardano

public typealias TransactionInputs = Array<TransactionInput>

extension CCardano.TransactionInputs: CArray {
    typealias CElement = CCardano.TransactionInput

    mutating func free() {
        cardano_transaction_inputs_free(&self)
    }
}

extension TransactionInputs {
    func withCArray<T>(fn: @escaping (CCardano.TransactionInputs) throws -> T) rethrows -> T {
        try withContiguousStorageIfAvailable { storage in
            try fn(CCardano.TransactionInputs(ptr: storage.baseAddress, len: UInt(storage.count)))
        }!
    }
}
