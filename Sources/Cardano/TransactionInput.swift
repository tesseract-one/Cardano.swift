//
//  TransactionInput.swift
//  
//
//  Created by Ostap Danylovych on 09.06.2021.
//

import Foundation
import CCardano

public typealias TransactionInput = CCardano.TransactionInput

extension TransactionInput: CType {}

extension TransactionInput {
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { result, error in
                cardano_transaction_input_from_bytes(bytes, result, error)
            }
        }.get()
    }
    
    public func bytes() throws -> Data {
        var bytes = try RustResult<CData>.wrap { result, error in
            cardano_transaction_input_to_bytes(self, result, error)
        }.get()
        return bytes.owned()
    }
}

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
