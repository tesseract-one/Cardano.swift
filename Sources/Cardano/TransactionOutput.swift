//
//  TransactionOutput.swift
//  
//
//  Created by Ostap Danylovych on 30.06.2021.
//

import Foundation
import CCardano

public typealias TransactionOutput = CCardano.TransactionOutput

extension TransactionOutput: CType {}

extension TransactionOutput {
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { result, error in
                cardano_transaction_output_from_bytes(bytes, result, error)
            }
        }.get()
    }
    
    public func bytes() throws -> Data {
        var bytes = try RustResult<Self>.wrap { result, error in
            cardano_transaction_output_to_bytes(self, result, error)
        }.get()
        return bytes.owned()
    }
}

public typealias TransactionOutputs = Array<TransactionOutput>

extension CCardano.TransactionOutputs: CArray {
    typealias CElement = CCardano.TransactionOutput

    mutating func free() {
        cardano_transaction_outputs_free(&self)
    }
}

extension TransactionOutputs {
    func withCArray<T>(fn: @escaping (CCardano.TransactionOutputs) throws -> T) rethrows -> T {
        try withContiguousStorageIfAvailable { storage in
            try fn(CCardano.TransactionOutputs(ptr: storage.baseAddress, len: UInt(storage.count)))
        }!
    }
}
