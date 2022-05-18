//
//  TransactionOutput.swift
//  
//
//  Created by Ostap Danylovych on 30.06.2021.
//

import Foundation
import CCardano

public typealias DataHash = CCardano.DataHash

extension DataHash: CType {}

extension DataHash {
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { res, err in
                cardano_data_hash_from_bytes(bytes, res, err)
            }
        }.get()
    }
    
    public func data() throws -> Data {
        var data = try RustResult<CData>.wrap { res, err in
            cardano_data_hash_to_bytes(self, res, err)
        }.get()
        return data.owned()
    }
    
    public var bytesArray: [UInt8] {
        withUnsafeBytes(of: _0) { ptr in
            Array(ptr.bindMemory(to: UInt8.self).prefix(32))
        }
    }
}

extension DataHash: Equatable {
    public static func == (lhs: DataHash, rhs: DataHash) -> Bool {
        lhs.bytesArray == rhs.bytesArray
    }
}

extension DataHash: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(bytesArray)
    }
}

extension COption_DataHash: COption {
    typealias Tag = COption_DataHash_Tag
    typealias Value = DataHash

    func someTag() -> Tag {
        Some_DataHash
    }

    func noneTag() -> Tag {
        None_DataHash
    }
}

public struct TransactionOutput: Equatable {
    public let address: Address
    public let amount: Value
    public var dataHash: DataHash?
    
    init(transactionOutput: CCardano.TransactionOutput) {
        address = transactionOutput.address.copied()
        amount = transactionOutput.amount.copied()
        dataHash = transactionOutput.data_hash.get()
    }
    
    public init(address: Address, amount: Value) {
        self.address = address
        self.amount = amount
    }
    
    func clonedCTransactionOutput() throws -> CCardano.TransactionOutput {
        try withCTransactionOutput { try $0.clone() }
    }

    func withCTransactionOutput<T>(
        fn: @escaping (CCardano.TransactionOutput) throws -> T
    ) rethrows -> T {
        try address.withCAddress { address in
            try amount.withCValue { amount in
                try fn(CCardano.TransactionOutput(
                    address: address,
                    amount: amount,
                    data_hash: dataHash.cOption()
                ))
            }
        }
    }
}

extension CCardano.TransactionOutput: CPtr {
    typealias Val = TransactionOutput

    func copied() -> TransactionOutput {
        TransactionOutput(transactionOutput: self)
    }

    mutating func free() {
        cardano_transaction_output_free(&self)
    }
}

extension CCardano.TransactionOutput {
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { result, error in
                cardano_transaction_output_from_bytes(bytes, result, error)
            }
        }.get()
    }
    
    public func bytes() throws -> Data {
        var bytes = try RustResult<CData>.wrap { result, error in
            cardano_transaction_output_to_bytes(self, result, error)
        }.get()
        return bytes.owned()
    }
    
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_transaction_output_clone(self, result, error)
        }.get()
    }
}

public typealias TransactionOutputs = Array<TransactionOutput>

extension CCardano.TransactionOutputs: CArray {
    typealias CElement = CCardano.TransactionOutput
    typealias Val = [CCardano.TransactionOutput]

    mutating func free() {
        cardano_transaction_outputs_free(&self)
    }
}

extension TransactionOutputs {
    func withCArray<T>(fn: @escaping (CCardano.TransactionOutputs) throws -> T) rethrows -> T {
        try withCArray(with: { try $0.withCTransactionOutput(fn: $1) }, fn: fn)
    }
}
