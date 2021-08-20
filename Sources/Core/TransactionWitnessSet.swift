//
//  TransactionWitnessSet.swift
//  
//
//  Created by Ostap Danylovych on 16.06.2021.
//

import Foundation
import CCardano

extension COption_Vkeywitnesses: COption {
    typealias Tag = COption_Vkeywitnesses_Tag
    typealias Value = CCardano.Vkeywitnesses

    func someTag() -> Tag {
        Some_Vkeywitnesses
    }

    func noneTag() -> Tag {
        None_Vkeywitnesses
    }
}

extension COption_BootstrapWitnesses: COption {
    typealias Tag = COption_BootstrapWitnesses_Tag
    typealias Value = CCardano.BootstrapWitnesses
    
    func someTag() -> Tag {
        Some_BootstrapWitnesses
    }
    
    func noneTag() -> Tag {
        None_BootstrapWitnesses
    }
}

public struct TransactionWitnessSet {
    public var vkeys: Vkeywitnesses?
    public var scripts: NativeScripts?
    public var bootstraps: BootstrapWitnesses?
    
    init(transactionWitnessSet: CCardano.TransactionWitnessSet) {
        vkeys = transactionWitnessSet.vkeys.get()?.copied()
        scripts = transactionWitnessSet.scripts.get()?.copied().map { $0.copied() }
        bootstraps = transactionWitnessSet.bootstraps.get()?.copied().map { $0.copied() }
    }
    
    public init() {}
    
    func clonedCTransactionWitnessSet() throws -> CCardano.TransactionWitnessSet {
        try withCTransactionWitnessSet { try $0.clone() }
    }
    
    func withCTransactionWitnessSet<T>(
        fn: @escaping (CCardano.TransactionWitnessSet) throws -> T
    ) rethrows -> T {
        try vkeys.withCOption(
            with: { try $0.withCArray(fn: $1) }
        ) { vkeys in
            try scripts.withCOption(
                with: { try $0.withCArray(fn: $1) }
            ) { scripts in
                try bootstraps.withCOption(
                    with: { try $0.withCArray(fn: $1) }
                ) { bootstraps in
                    try fn(CCardano.TransactionWitnessSet(
                        vkeys: vkeys,
                        scripts: scripts,
                        bootstraps: bootstraps
                    ))
                }
            }
        }
    }
}

extension CCardano.TransactionWitnessSet: CPtr {
    typealias Val = TransactionWitnessSet
    
    func copied() -> TransactionWitnessSet {
        TransactionWitnessSet(transactionWitnessSet: self)
    }
    
    mutating func free() {
        cardano_transaction_witness_set_free(&self)
    }
}

extension CCardano.TransactionWitnessSet {
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_transaction_witness_set_clone(self, result, error)
        }.get()
    }
}
