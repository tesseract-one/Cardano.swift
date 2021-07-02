//
//  Transaction.swift
//  
//
//  Created by Ostap Danylovych on 03.07.2021.
//

import Foundation
import CCardano

extension COption_TransactionMetadata: COption {
    typealias Tag = COption_TransactionMetadata_Tag
    typealias Value = CCardano.TransactionMetadata

    func someTag() -> Tag {
        Some_TransactionMetadata
    }

    func noneTag() -> Tag {
        None_TransactionMetadata
    }
}

public struct Transaction {
    public private(set) var body: TransactionBody
    public private(set) var witnessSet: TransactionWitnessSet
    public private(set) var metadata: TransactionMetadata?
    
    init(transaction: CCardano.Transaction) {
        body = transaction.body.copied()
        witnessSet = transaction.witness_set.copied()
        metadata = transaction.metadata.get()?.copied()
    }
    
    func clonedCTransaction() throws -> CCardano.Transaction {
        try withCTransaction { try $0.clone() }
    }
    
    func withCTransaction<T>(
        fn: @escaping (CCardano.Transaction) throws -> T
    ) rethrows -> T {
        try fn(CCardano.Transaction(
            body: body.withCTransactionBody { $0 },
            witness_set: witnessSet.withCTransactionWitnessSet { $0 },
            metadata: metadata.cOption { $0.withCTransactionMetadata { $0 } }
        ))
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
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_transaction_clone(self, result, error)
        }.get()
    }
}
