//
//  Transaction.swift
//  
//
//  Created by Ostap Danylovych on 03.07.2021.
//

import Foundation
import CCardano

extension COption_AuxiliaryData: COption {
    typealias Tag = COption_AuxiliaryData_Tag
    typealias Value = CCardano.AuxiliaryData

    func someTag() -> Tag {
        Some_AuxiliaryData
    }

    func noneTag() -> Tag {
        None_AuxiliaryData
    }
}

public struct Transaction {
    public let body: TransactionBody
    public let witnessSet: TransactionWitnessSet
    public let isValid: Bool
    public let auxiliaryData: AuxiliaryData?
    
    init(transaction: CCardano.Transaction) {
        body = transaction.body.copied()
        witnessSet = transaction.witness_set.copied()
        isValid = transaction.is_valid
        auxiliaryData = transaction.auxiliary_data.get()?.copied()
    }
    
    public init(body: TransactionBody, witnessSet: TransactionWitnessSet, auxiliaryData: AuxiliaryData?) {
        self.body = body
        self.witnessSet = witnessSet
        isValid = true
        self.auxiliaryData = auxiliaryData
    }
    
    public init(bytes: Data) throws {
        var transaction = try CCardano.Transaction(bytes: bytes)
        self = transaction.owned()
    }
    
    public func bytes() throws -> Data {
        try withCTransaction { try $0.bytes() }
    }
    
    public func minFee(linearFee: LinearFee) throws -> Coin {
        try withCTransaction { try $0.minFee(linearFee: linearFee) }
    }
    
    func clonedCTransaction() throws -> CCardano.Transaction {
        try withCTransaction { try $0.clone() }
    }
    
    func withCTransaction<T>(
        fn: @escaping (CCardano.Transaction) throws -> T
    ) rethrows -> T {
        try auxiliaryData.withCOption(
            with: { try $0.withCAuxiliaryData(fn: $1) }
        ) { auxiliaryData in
            try body.withCTransactionBody { body in
                try witnessSet.withCTransactionWitnessSet { witnessSet in
                    try fn(CCardano.Transaction(
                        body: body,
                        witness_set: witnessSet,
                        is_valid: isValid,
                        auxiliary_data: auxiliaryData
                    ))
                }
            }
        }
    }
}

extension CCardano.Transaction: CPtr {
    typealias Val = Transaction
    
    func copied() -> Transaction {
        Transaction(transaction: self)
    }
    
    mutating func free() {
        cardano_transaction_free(&self)
    }
}

extension CCardano.Transaction {
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { result, error in
                cardano_transaction_from_bytes(bytes, result, error)
            }
        }.get()
    }
    
    public func minFee(linearFee: LinearFee) throws -> Coin {
        try RustResult<Coin>.wrap { result, error in
            cardano_transaction_min_fee(self, linearFee, result, error)
        }.get()
    }

    public func bytes() throws -> Data {
        var bytes = try RustResult<CData>.wrap { result, error in
            cardano_transaction_to_bytes(self, result, error)
        }.get()
        return bytes.owned()
    }

    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_transaction_clone(self, result, error)
        }.get()
    }
}
