//
//  TransactionBuilder.swift
//  
//
//  Created by Ostap Danylovych on 07.07.2021.
//

import Foundation
import CCardano

extension Set where Element == Ed25519KeyHash {
    func withCArray<T>(fn: @escaping (CArray_Ed25519KeyHash) throws -> T) rethrows -> T {
        try Array(self).withCArray(fn: fn)
    }
}

extension CArray_ScriptHash: CArray {
    typealias CElement = CCardano.ScriptHash

    mutating func free() {}
}

extension Set where Element == ScriptHash {
    func withCArray<T>(fn: @escaping (CArray_ScriptHash) throws -> T) rethrows -> T {
        try Array(self).withCArr(fn: fn)
    }
}

extension CArray_CData: CArray {
    typealias CElement = CData

    mutating func free() {}
}

extension Set where Element == Data {
    func withCArray<T>(fn: @escaping (CArray_CData) throws -> T) rethrows -> T {
        try Array(self).withCArray(with: { try $0.withCData(fn: $1) }, fn: fn)
    }
}

public struct MockWitnessSet {
    public private(set) var vkeys: Set<Ed25519KeyHash>
    public private(set) var scripts: Set<ScriptHash>
    public private(set) var bootstraps: Set<Data>
    
    init(mockWitnessSet: CCardano.MockWitnessSet) {
        vkeys = Set(mockWitnessSet.vkeys.copied())
        scripts = Set(mockWitnessSet.scripts.copied())
        bootstraps = Set(mockWitnessSet.bootstraps.copied().map { $0.copied() })
    }
    
    func clonedCMockWitnessSet() throws -> CCardano.MockWitnessSet {
        try withCMockWitnessSet { try $0.clone() }
    }
    
    func withCMockWitnessSet<T>(
        fn: @escaping (CCardano.MockWitnessSet) throws -> T
    ) rethrows -> T {
        try vkeys.withCArray { vkeys in
            try scripts.withCArray { scripts in
                try bootstraps.withCArray { bootstraps in
                    try fn(CCardano.MockWitnessSet(
                        vkeys: vkeys,
                        scripts: scripts,
                        bootstraps: bootstraps
                    ))
                }
            }
        }
    }
}

extension CCardano.MockWitnessSet: CPtr {
    typealias Val = MockWitnessSet
    
    func copied() -> MockWitnessSet {
        MockWitnessSet(mockWitnessSet: self)
    }
    
    mutating func free() {
        cardano_mock_witness_set_free(&self)
    }
}

extension CCardano.MockWitnessSet {
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_mock_witness_set_clone(self, result, error)
        }.get()
    }
}

public struct TxBuilderInput {
    public private(set) var input: TransactionInput
    public private(set) var amount: Value
    
    init(txBuilderInput: CCardano.TxBuilderInput) {
        input = txBuilderInput.input
        amount = txBuilderInput.amount.copied()
    }
    
    func clonedCTxBuilderInput() throws -> CCardano.TxBuilderInput {
        try withCTxBuilderInput { try $0.clone() }
    }
    
    func withCTxBuilderInput<T>(
        fn: @escaping (CCardano.TxBuilderInput) throws -> T
    ) rethrows -> T {
        try amount.withCValue { amount in
            try fn(CCardano.TxBuilderInput(input: input, amount: amount))
        }
    }
}

extension CCardano.TxBuilderInput: CPtr {
    typealias Val = TxBuilderInput
    
    func copied() -> TxBuilderInput {
        TxBuilderInput(txBuilderInput: self)
    }
    
    mutating func free() {
        cardano_tx_builder_input_free(&self)
    }
}

extension CCardano.TxBuilderInput {
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_tx_builder_input_clone(self, result, error)
        }.get()
    }
}

extension CArray_TxBuilderInput: CArray {
    typealias CElement = CCardano.TxBuilderInput

    mutating func free() {}
}

extension Array where Element == TxBuilderInput {
    func withCArray<T>(fn: @escaping (CArray_TxBuilderInput) throws -> T) rethrows -> T {
        try withCArray(with: { try $0.withCTxBuilderInput(fn: $1) }, fn: fn)
    }
}

extension COption_Coin: COption {
    typealias Tag = COption_Coin_Tag
    typealias Value = Coin

    func someTag() -> Tag {
        Some_Coin
    }

    func noneTag() -> Tag {
        None_Coin
    }
}

public struct TransactionBuilder {
    public private(set) var minimumUtxoVal: BigNum
    public private(set) var poolDeposit: BigNum
    public private(set) var keyDeposit: BigNum
    public private(set) var feeAlgo: LinearFee
    public private(set) var inputs: Array<TxBuilderInput>
    public private(set) var outputs: TransactionOutputs
    public var fee: Coin?
    public var ttl: Slot?
    public private(set) var certs: Certificates?
    public private(set) var withdrawals: Withdrawals?
    public private(set) var metadata: TransactionMetadata?
    public var validityStartInterval: Slot?
    public private(set) var inputTypes: MockWitnessSet
    public private(set) var mint: Mint?
    
    init(transactionBuilder: CCardano.TransactionBuilder) {
        minimumUtxoVal = transactionBuilder.minimum_utxo_val
        poolDeposit = transactionBuilder.pool_deposit
        keyDeposit = transactionBuilder.key_deposit
        feeAlgo = transactionBuilder.fee_algo
        inputs = transactionBuilder.inputs.copied().map { $0.copied() }
        outputs = transactionBuilder.outputs.copied().map { $0.copied() }
        fee = transactionBuilder.fee.get()
        ttl = transactionBuilder.ttl.get()
        certs = transactionBuilder.certs.get()?.copied().map { $0.copied() }
        withdrawals = transactionBuilder.withdrawals.get().map {
            Dictionary(uniqueKeysWithValues: $0.copiedDictionary().map { key, value in
                (key.copied(), value)
            })
        }
        metadata = transactionBuilder.metadata.get()?.copied()
        validityStartInterval = transactionBuilder.validity_start_interval.get()
        inputTypes = transactionBuilder.input_types.copied()
        mint = transactionBuilder.mint.get()?.copiedDictionary().mapValues { $0.copiedDictionary() }
    }
    
    public init(linearFee: LinearFee, minimumUtxoVal: Coin, poolDeposit: BigNum, keyDeposit: BigNum) throws {
        var transactionBuilder = try CCardano.TransactionBuilder(
            linearFee: linearFee,
            minimumUtxoVal: minimumUtxoVal,
            poolDeposit: poolDeposit,
            keyDeposit: keyDeposit
        )
        self = transactionBuilder.owned()
    }
    
    public mutating func addKeyInput(hash: Ed25519KeyHash, input: TransactionInput, amount: Value) throws {
        self = try withCTransactionBuilder {
            try $0.addKeyInput(hash: hash, input: input, amount: amount)
        }
    }
    
    public mutating func addScriptInput(hash: ScriptHash, input: TransactionInput, amount: Value) throws {
        self = try withCTransactionBuilder {
            try $0.addScriptInput(hash: hash, input: input, amount: amount)
        }
    }
    
    public mutating func addBootstrapInput(hash: ByronAddress, input: TransactionInput, amount: Value) throws {
        self = try withCTransactionBuilder {
            try $0.addBootstrapInput(hash: hash, input: input, amount: amount)
        }
    }
    
    public mutating func addInput(address: Address, input: TransactionInput, amount: Value) throws {
        self = try withCTransactionBuilder {
            try $0.addInput(address: address, input: input, amount: amount)
        }
    }
    
    public func feeForInput(address: Address, input: TransactionInput, amount: Value) throws -> Coin {
        try withCTransactionBuilder {
            try $0.feeForInput(address: address, input: input, amount: amount)
        }
    }
    
    public mutating func addOutput(output: TransactionOutput) throws {
        self = try withCTransactionBuilder { try $0.addOutput(output: output) }
    }
    
    public func feeForOutput(output: TransactionOutput) throws -> Coin {
        try withCTransactionBuilder { try $0.feeForOutput(output: output) }
    }
    
    public mutating func setCerts(certs: Certificates) throws {
        self = try withCTransactionBuilder { try $0.setCerts(certs: certs) }
    }
    
    public mutating func setWithdrawals(withdrawals: Withdrawals) throws {
        self = try withCTransactionBuilder {
            try $0.setWithdrawals(withdrawals: withdrawals)
        }
    }
    
    public mutating func setMetadata(metadata: TransactionMetadata) throws {
        self = try withCTransactionBuilder { try $0.setMetadata(metadata: metadata) }
    }
    
    public func getExplicitInput() throws -> Value {
        try withCTransactionBuilder { try $0.getExplicitInput() }
    }
    
    public func getImplicitInput() throws -> Value {
        try withCTransactionBuilder { try $0.getImplicitInput() }
    }
    
    public func getExplicitOutput() throws -> Value {
        try withCTransactionBuilder { try $0.getExplicitOutput() }
    }
    
    public func getDeposit() throws -> Coin {
        try withCTransactionBuilder { try $0.getDeposit() }
    }
    
    public mutating func addChangeIfNeeded(address: Address) throws -> Bool {
        let result = try withCTransactionBuilder {
            try $0.addChangeIfNeeded(address: address)
        }
        self = result.0
        return result.1
    }
    
    public func build() throws -> TransactionBody {
        try withCTransactionBuilder { try $0.build() }
    }
    
    public func minFee() throws -> Coin {
        try withCTransactionBuilder { try $0.minFee() }
    }
    
    func clonedCTransactionBuilder() throws -> CCardano.TransactionBuilder {
        try withCTransactionBuilder { try $0.clone() }
    }
    
    func withCTransactionBuilder<T>(
        fn: @escaping (CCardano.TransactionBuilder) throws -> T
    ) rethrows -> T {
        try inputs.withCArray { inputs in
            try outputs.withCArray { outputs in
                try certs.withCOption(
                    with: { try $0.withCArray(fn: $1) }
                ) { certs in
                    try withdrawals.withCOption(
                        with: { try $0.withCKVArray(fn: $1) }
                    ) { withdrawals in
                        try metadata.withCOption(
                            with: { try $0.withCTransactionMetadata(fn: $1) }
                        ) { metadata in
                            try inputTypes.withCMockWitnessSet { inputTypes in
                                try mint.withCOption(
                                    with: { try $0.withCKVArray(fn: $1) }
                                ) { mint in
                                    try fn(CCardano.TransactionBuilder(
                                        minimum_utxo_val: minimumUtxoVal,
                                        pool_deposit: poolDeposit,
                                        key_deposit: keyDeposit,
                                        fee_algo: feeAlgo,
                                        inputs: inputs,
                                        outputs: outputs,
                                        fee: fee.cOption(),
                                        ttl: ttl.cOption(),
                                        certs: certs,
                                        withdrawals: withdrawals,
                                        metadata: metadata,
                                        validity_start_interval: validityStartInterval.cOption(),
                                        input_types: inputTypes,
                                        mint: mint
                                    ))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

extension CCardano.TransactionBuilder: CPtr {
    typealias Val = TransactionBuilder
    
    func copied() -> TransactionBuilder {
        TransactionBuilder(transactionBuilder: self)
    }
    
    mutating func free() {
        cardano_transaction_builder_free(&self)
    }
}

extension CCardano.TransactionBuilderBool: CType {}

extension CCardano.TransactionBuilder {
    public init(linearFee: LinearFee, minimumUtxoVal: Coin, poolDeposit: BigNum, keyDeposit: BigNum) throws {
        self = try RustResult<Self>.wrap { result, error in
            cardano_transaction_builder_new(linearFee, minimumUtxoVal, poolDeposit, keyDeposit, result, error)
        }.get()
    }
    
    public func addKeyInput(hash: Ed25519KeyHash, input: TransactionInput, amount: Value) throws -> TransactionBuilder {
        var transactionBuilder = try amount.withCValue { amount in
            RustResult<Self>.wrap { result, error in
                cardano_transaction_builder_add_key_input(self, hash, input, amount, result, error)
            }
        }.get()
        return transactionBuilder.owned()
    }
    
    public func addScriptInput(hash: ScriptHash, input: TransactionInput, amount: Value) throws -> TransactionBuilder {
        var transactionBuilder = try amount.withCValue { amount in
            RustResult<Self>.wrap { result, error in
                cardano_transaction_builder_add_script_input(self, hash, input, amount, result, error)
            }
        }.get()
        return transactionBuilder.owned()
    }
    
    public func addBootstrapInput(hash: ByronAddress, input: TransactionInput, amount: Value) throws -> TransactionBuilder {
        var transactionBuilder = try hash.withCAddress { hash in
            amount.withCValue { amount in
                RustResult<Self>.wrap { result, error in
                    cardano_transaction_builder_add_bootstrap_input(self, hash, input, amount, result, error)
                }
            }
        }.get()
        return transactionBuilder.owned()
    }
    
    public func addInput(address: Address, input: TransactionInput, amount: Value) throws -> TransactionBuilder {
        var transactionBuilder = try address.withCAddress { address in
            amount.withCValue { amount in
                RustResult<Self>.wrap { result, error in
                    cardano_transaction_builder_add_input(self, address, input, amount, result, error)
                }
            }
        }.get()
        return transactionBuilder.owned()
    }
    
    public func feeForInput(address: Address, input: TransactionInput, amount: Value) throws -> Coin {
        try address.withCAddress { address in
            amount.withCValue { amount in
                RustResult<Coin>.wrap { result, error in
                    cardano_transaction_builder_fee_for_input(self, address, input, amount, result, error)
                }
            }
        }.get()
    }
    
    public func addOutput(output: TransactionOutput) throws -> TransactionBuilder {
        var transactionBuilder = try output.withCTransactionOutput { output in
            RustResult<Self>.wrap { result, error in
                cardano_transaction_builder_add_output(self, output, result, error)
            }
        }.get()
        return transactionBuilder.owned()
    }
    
    public func feeForOutput(output: TransactionOutput) throws -> Coin {
        try output.withCTransactionOutput { output in
            RustResult<Coin>.wrap { result, error in
                cardano_transaction_builder_fee_for_output(self, output, result, error)
            }
        }.get()
    }
    
    public func setCerts(certs: Certificates) throws -> TransactionBuilder {
        var transactionBuilder = try certs.withCArray { certs in
            RustResult<Self>.wrap { result, error in
                cardano_transaction_builder_set_certs(self, certs, result, error)
            }
        }.get()
        return transactionBuilder.owned()
    }
    
    public func setWithdrawals(withdrawals: Withdrawals) throws -> TransactionBuilder {
        var transactionBuilder = try withdrawals.withCKVArray { withdrawals in
            RustResult<Self>.wrap { result, error in
                cardano_transaction_builder_set_withdrawals(self, withdrawals, result, error)
            }
        }.get()
        return transactionBuilder.owned()
    }
    
    public func setMetadata(metadata: TransactionMetadata) throws -> TransactionBuilder {
        var transactionBuilder = try metadata.withCTransactionMetadata { metadata in
            RustResult<Self>.wrap { result, error in
                cardano_transaction_builder_set_metadata(self, metadata, result, error)
            }
        }.get()
        return transactionBuilder.owned()
    }
    
    public func getExplicitInput() throws -> Value {
        var value = try RustResult<Value>.wrap { result, error in
            cardano_transaction_builder_get_explicit_input(self, result, error)
        }.get()
        return value.owned()
    }
    
    public func getImplicitInput() throws -> Value {
        var value = try RustResult<Value>.wrap { result, error in
            cardano_transaction_builder_get_implicit_input(self, result, error)
        }.get()
        return value.owned()
    }
    
    public func getExplicitOutput() throws -> Value {
        var value = try RustResult<Value>.wrap { result, error in
            cardano_transaction_builder_get_explicit_output(self, result, error)
        }.get()
        return value.owned()
    }
    
    public func getDeposit() throws -> Coin {
        try RustResult<Coin>.wrap { result, error in
            cardano_transaction_builder_get_deposit(self, result, error)
        }.get()
    }
    
    public func addChangeIfNeeded(address: Address) throws -> (TransactionBuilder, Bool) {
        var transactionBuilderBool = try address.withCAddress { address in
            RustResult<Bool>.wrap { result, error in
                cardano_transaction_builder_add_change_if_needed(self, address, result, error)
            }
        }.get()
        return (transactionBuilderBool._0.owned(), transactionBuilderBool._1)
    }

    public func build() throws -> TransactionBody {
        var transactionBody = try RustResult<TransactionBody>.wrap { result, error in
            cardano_transaction_builder_build(self, result, error)
        }.get()
        return transactionBody.owned()
    }
    
    public func minFee() throws -> Coin {
        try RustResult<Coin>.wrap { result, error in
            cardano_transaction_builder_min_fee(self, result, error)
        }.get()
    }
    
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_transaction_builder_clone(self, result, error)
        }.get()
    }
}
