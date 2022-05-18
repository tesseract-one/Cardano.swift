//
//  TransactionBody.swift
//  
//
//  Created by Ostap Danylovych on 30.06.2021.
//

import Foundation
import CCardano
import BigInt

public typealias ProposedProtocolParameterUpdates = Dictionary<GenesisHash, ProtocolParamUpdate>

extension CCardano.ProposedProtocolParameterUpdatesKeyValue: CType {}

extension CCardano.ProposedProtocolParameterUpdatesKeyValue: CKeyValue {
    typealias Key = GenesisHash
    typealias Value = CCardano.ProtocolParamUpdate
}

extension CCardano.ProposedProtocolParameterUpdates: CArray {
    typealias CElement = CCardano.ProposedProtocolParameterUpdatesKeyValue
    typealias Val = [CCardano.ProposedProtocolParameterUpdatesKeyValue]

    mutating func free() {
        cardano_proposed_protocol_parameter_updates_free(&self)
    }
}

extension ProposedProtocolParameterUpdates {
    func withCKVArray<T>(fn: @escaping (CCardano.ProposedProtocolParameterUpdates) throws -> T) rethrows -> T {
        try withCKVArray(withValue: { try $0.withCProtocolParamUpdate(fn: $1) }, fn: fn)
    }
}

public struct Update {
    public private(set) var proposedProtocolParameterUpdates: ProposedProtocolParameterUpdates
    public private(set) var epoch: Epoch
    
    init(update: CCardano.Update) {
        proposedProtocolParameterUpdates = update.proposed_protocol_parameter_updates.copiedDictionary().mapValues {
            $0.copied()
        }
        epoch = update.epoch
    }
    
    public init(proposedProtocolParameterUpdates: ProposedProtocolParameterUpdates, epoch: Epoch) {
        self.proposedProtocolParameterUpdates = proposedProtocolParameterUpdates
        self.epoch = epoch
    }
    
    func clonedCUpdate() throws -> CCardano.Update {
        try withCUpdate { try $0.clone() }
    }
    
    func withCUpdate<T>(
        fn: @escaping (CCardano.Update) throws -> T
    ) rethrows -> T {
        try proposedProtocolParameterUpdates.withCKVArray { pppu in
            try fn(CCardano.Update(proposed_protocol_parameter_updates: pppu, epoch: epoch))
        }
    }
}

extension CCardano.Update: CPtr {
    typealias Val = Update
    
    func copied() -> Update {
        Update(update: self)
    }
    
    mutating func free() {
        cardano_update_free(&self)
    }
}

extension CCardano.Update {
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_update_clone(self, result, error)
        }.get()
    }
}

public typealias AuxiliaryDataHash = CCardano.AuxiliaryDataHash

extension AuxiliaryDataHash: CType {}

extension AuxiliaryDataHash {
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { res, err in
                cardano_auxiliary_data_hash_from_bytes(bytes, res, err)
            }
        }.get()
    }
    
    public func data() throws -> Data {
        var data = try RustResult<CData>.wrap { res, err in
            cardano_auxiliary_data_hash_to_bytes(self, res, err)
        }.get()
        return data.owned()
    }
}

public typealias MintAssets = Dictionary<AssetName, BigInt>

extension CCardano.MintAssetsKeyValue: CType {}

extension CCardano.MintAssetsKeyValue: CKeyValue {
    typealias Key = AssetName
    typealias Value = CInt128
}

extension CCardano.MintAssets: CArray {
    typealias CElement = CCardano.MintAssetsKeyValue
    typealias Val = [CCardano.MintAssetsKeyValue]

    mutating func free() {
        cardano_mint_assets_free(&self)
    }
}

extension MintAssets {
    func withCKVArray<T>(fn: @escaping (CCardano.MintAssets) throws -> T) rethrows -> T {
        try withCKVArray(withValue: { try $1($0.cInt128) }, fn: fn)
    }
}

public typealias Mint = Dictionary<PolicyID, MintAssets>

extension CCardano.MintKeyValue: CType {}

extension CCardano.MintKeyValue: CKeyValue {
    typealias Key = PolicyID
    typealias Value = CCardano.MintAssets
}

extension CCardano.Mint: CArray {
    typealias CElement = CCardano.MintKeyValue
    typealias Val = [CCardano.MintKeyValue]

    mutating func free() {
        cardano_mint_free(&self)
    }
}

extension Mint {
    func withCKVArray<T>(fn: @escaping (CCardano.Mint) throws -> T) rethrows -> T {
        try withCKVArray(withValue: { try $0.withCKVArray(fn: $1) }, fn: fn)
    }
}

public typealias ScriptDataHash = CCardano.ScriptDataHash

extension ScriptDataHash: CType {}

extension ScriptDataHash {
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { res, err in
                cardano_script_data_hash_from_bytes(bytes, res, err)
            }
        }.get()
    }
    
    public func data() throws -> Data {
        var data = try RustResult<CData>.wrap { res, err in
            cardano_script_data_hash_to_bytes(self, res, err)
        }.get()
        return data.owned()
    }
}

public typealias RequiredSigners = Ed25519KeyHashes

public enum NetworkId {
    case testnet
    case mainnet

    init(networkId: CCardano.NetworkId) {
        switch networkId {
        case Testnet: self = .testnet
        case Mainnet: self = .mainnet
        default: fatalError("Unknown NetworkId type")
        }
    }

    func withCNetworkId<T>(
        fn: @escaping (CCardano.NetworkId) throws -> T
    ) rethrows -> T {
        switch self {
        case .testnet: return try fn(Testnet)
        case .mainnet: return try fn(Mainnet)
        }
    }
}

extension COption_Slot: COption {
    typealias Tag = COption_Slot_Tag
    typealias Value = Slot

    func someTag() -> Tag {
        Some_Slot
    }

    func noneTag() -> Tag {
        None_Slot
    }
}

extension COption_Certificates: COption {
    typealias Tag = COption_Certificates_Tag
    typealias Value = CCardano.Certificates

    func someTag() -> Tag {
        Some_Certificates
    }

    func noneTag() -> Tag {
        None_Certificates
    }
}

extension COption_Withdrawals: COption {
    typealias Tag = COption_Withdrawals_Tag
    typealias Value = CCardano.Withdrawals

    func someTag() -> Tag {
        Some_Withdrawals
    }

    func noneTag() -> Tag {
        None_Withdrawals
    }
}

extension COption_Update: COption {
    typealias Tag = COption_Update_Tag
    typealias Value = CCardano.Update

    func someTag() -> Tag {
        Some_Update
    }

    func noneTag() -> Tag {
        None_Update
    }
}

extension COption_AuxiliaryDataHash: COption {
    typealias Tag = COption_AuxiliaryDataHash_Tag
    typealias Value = AuxiliaryDataHash

    func someTag() -> Tag {
        Some_AuxiliaryDataHash
    }

    func noneTag() -> Tag {
        None_AuxiliaryDataHash
    }
}

extension COption_Mint: COption {
    typealias Tag = COption_Mint_Tag
    typealias Value = CCardano.Mint

    func someTag() -> Tag {
        Some_Mint
    }

    func noneTag() -> Tag {
        None_Mint
    }
}

extension COption_ScriptDataHash: COption {
    typealias Tag = COption_ScriptDataHash_Tag
    typealias Value = CCardano.ScriptDataHash

    func someTag() -> Tag {
        Some_ScriptDataHash
    }

    func noneTag() -> Tag {
        None_ScriptDataHash
    }
}

extension COption_TransactionInputs: COption {
    typealias Tag = COption_TransactionInputs_Tag
    typealias Value = CCardano.TransactionInputs

    func someTag() -> Tag {
        Some_TransactionInputs
    }

    func noneTag() -> Tag {
        None_TransactionInputs
    }
}

extension COption_RequiredSigners: COption {
    typealias Tag = COption_RequiredSigners_Tag
    typealias Value = CCardano.RequiredSigners

    func someTag() -> Tag {
        Some_RequiredSigners
    }

    func noneTag() -> Tag {
        None_RequiredSigners
    }
}

extension COption_NetworkId: COption {
    typealias Tag = COption_NetworkId_Tag
    typealias Value = CCardano.NetworkId

    func someTag() -> Tag {
        Some_NetworkId
    }

    func noneTag() -> Tag {
        None_NetworkId
    }
}

public struct TransactionBody {
    public private(set) var inputs: TransactionInputs
    public private(set) var outputs: TransactionOutputs
    public private(set) var fee: Coin
    public private(set) var ttl: Slot?
    public var certs: Certificates?
    public var withdrawals: Withdrawals?
    public var update: Update?
    public var auxiliaryDataHash: AuxiliaryDataHash?
    public var validityStartInterval: Slot?
    public var mint: Mint?
    public var scriptDataHash: ScriptDataHash?
    public var collateral: TransactionInputs?
    public var requiredSigners: RequiredSigners?
    public var networkId: NetworkId?
    
    init(transactionBody: CCardano.TransactionBody) {
        inputs = transactionBody.inputs.copied()
        outputs = transactionBody.outputs.copied().map { $0.copied() }
        fee = transactionBody.fee
        ttl = transactionBody.ttl.get()
        certs = transactionBody.certs.get()?.copied().map { $0.copied() }
        withdrawals = transactionBody.withdrawals.get().map {
            Dictionary(uniqueKeysWithValues: $0.copiedDictionary().map { key, value in
                (key.copied(), value)
            })
        }
        update = transactionBody.update.get()?.copied()
        auxiliaryDataHash = transactionBody.auxiliary_data_hash.get()
        validityStartInterval = transactionBody.validity_start_interval.get()
        mint = transactionBody.mint.get()?.copiedDictionary().mapValues {
            $0.copiedDictionary().mapValues { $0.bigInt }
        }
        scriptDataHash = transactionBody.script_data_hash.get()
        collateral = transactionBody.collateral.get()?.copied()
        requiredSigners = transactionBody.required_signers.get()?.copied()
        if let networkId = transactionBody.network_id.get() {
            self.networkId = NetworkId(networkId: networkId)
        }
    }
    
    public init(
        inputs: TransactionInputs, outputs: TransactionOutputs, fee: Coin, ttl: Slot?
    ) {
        self.inputs = inputs
        self.outputs = outputs
        self.fee = fee
        self.ttl = ttl
    }
    
    public init(bytes: Data) throws {
        var transactionBody = try CCardano.TransactionBody(bytes: bytes)
        self = transactionBody.owned()
    }
    
    public func bytes() throws -> Data {
        try withCTransactionBody { try $0.bytes() }
    }

    func clonedCTransactionBody() throws -> CCardano.TransactionBody {
        try withCTransactionBody { try $0.clone() }
    }
    
    func withCTransactionBody<T>(
        fn: @escaping (CCardano.TransactionBody) throws -> T
    ) rethrows -> T {
        try inputs.withCArray { inputs in
            try outputs.withCArray { outputs in
                try certs.withCOption(
                    with: { try $0.withCArray(fn: $1) }
                ) { certs in
                    try withdrawals.withCOption(
                        with: { try $0.withCKVArray(fn: $1) }
                    ) { withdrawals in
                        try update.withCOption(
                            with: { try $0.withCUpdate(fn: $1) }
                        ) { update in
                            try mint.withCOption(
                                with: { try $0.withCKVArray(fn: $1) }
                            ) { mint in
                                try collateral.withCOption(
                                    with: { try $0.withCArray(fn: $1) }
                                ) { collateral in
                                    try requiredSigners.withCOption(
                                        with: { try $0.withCArray(fn: $1) }
                                    ) { requiredSigners in
                                        try networkId.withCOption(
                                            with: { try $0.withCNetworkId(fn: $1) }
                                        ) { networkId in
                                            try fn(CCardano.TransactionBody(
                                                inputs: inputs,
                                                outputs: outputs,
                                                fee: fee,
                                                ttl: ttl.cOption(),
                                                certs: certs,
                                                withdrawals: withdrawals,
                                                update: update,
                                                auxiliary_data_hash: auxiliaryDataHash.cOption(),
                                                validity_start_interval: validityStartInterval.cOption(),
                                                mint: mint,
                                                script_data_hash: scriptDataHash.cOption(),
                                                collateral: collateral,
                                                required_signers: requiredSigners,
                                                network_id: networkId
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
    }
}

extension CCardano.TransactionBody: CPtr {
    typealias Val = TransactionBody
    
    func copied() -> TransactionBody {
        TransactionBody(transactionBody: self)
    }
    
    mutating func free() {
        cardano_transaction_body_free(&self)
    }
}

extension CCardano.TransactionBody {
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { result, error in
                cardano_transaction_body_from_bytes(bytes, result, error)
            }
        }.get()
    }
    
    public func bytes() throws -> Data {
        var bytes = try RustResult<CData>.wrap { result, error in
            cardano_transaction_body_to_bytes(self, result, error)
        }.get()
        return bytes.owned()
    }

    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_transaction_body_clone(self, result, error)
        }.get()
    }
}
