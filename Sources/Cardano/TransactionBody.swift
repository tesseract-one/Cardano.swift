//
//  TransactionBody.swift
//  
//
//  Created by Ostap Danylovych on 30.06.2021.
//

import Foundation
import CCardano

public typealias ProposedProtocolParameterUpdates = Dictionary<GenesisHash, ProtocolParamUpdate>

extension CCardano.ProposedProtocolParameterUpdatesKeyValue: CType {}

extension CCardano.ProposedProtocolParameterUpdatesKeyValue: CKeyValue {
    typealias Key = GenesisHash
    typealias Value = CCardano.ProtocolParamUpdate
}

extension CCardano.ProposedProtocolParameterUpdates: CArray {
    typealias CElement = CCardano.ProposedProtocolParameterUpdatesKeyValue

    mutating func free() {
        cardano_proposed_protocol_parameter_updates_free(&self)
    }
}

extension ProposedProtocolParameterUpdates {
    func withCKVArray<T>(fn: @escaping (CCardano.ProposedProtocolParameterUpdates) throws -> T) rethrows -> T {
        try withContiguousStorageIfAvailable { storage in
            let mapped = storage.map {CCardano.ProposedProtocolParameterUpdates.CElement(
                key: $0.key,
                val: $0.value.withCProtocolParamUpdate { $0 }
            )}
            return try mapped.withUnsafeBufferPointer {
                try fn(CCardano.ProposedProtocolParameterUpdates(ptr: $0.baseAddress, len: UInt($0.count)))
            }
        }!
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

public typealias MetadataHash = CCardano.MetadataHash

extension MetadataHash: CType {}

public typealias MintAssets = Dictionary<AssetName, UInt64>

extension CCardano.MintAssets: CArray {
    typealias CElement = CCardano.MintAssetsKeyValue

    mutating func free() {
        cardano_mint_assets_free(&self)
    }
}

extension MintAssets {
    func withCKVArray<T>(fn: @escaping (CCardano.MintAssets) throws -> T) rethrows -> T {
        try withContiguousStorageIfAvailable { storage in
            let mapped = storage.map { CCardano.MintAssets.CElement($0) }
            return try mapped.withUnsafeBufferPointer {
                try fn(CCardano.MintAssets(ptr: $0.baseAddress, len: UInt($0.count)))
            }
        }!
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

    mutating func free() {
        cardano_mint_free(&self)
    }
}

extension Mint {
    func withCKVArray<T>(fn: @escaping (CCardano.Mint) throws -> T) rethrows -> T {
        try withContiguousStorageIfAvailable { storage in
            let mapped = storage.map { el in
                el.value.withCKVArray { arr in
                    CCardano.Mint.CElement((el.key, arr))
                }
            }
            return try mapped.withUnsafeBufferPointer {
                try fn(CCardano.Mint(ptr: $0.baseAddress, len: UInt($0.count)))
            }
        }!
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

extension COption_MetadataHash: COption {
    typealias Tag = COption_MetadataHash_Tag
    typealias Value = MetadataHash

    func someTag() -> Tag {
        Some_MetadataHash
    }

    func noneTag() -> Tag {
        None_MetadataHash
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

public struct TransactionBody {
    public private(set) var inputs: TransactionInputs
    public private(set) var outputs: TransactionOutputs
    public private(set) var fee: Coin
    public private(set) var ttl: Slot?
    public private(set) var certs: Certificates?
    public private(set) var withdrawals: Withdrawals?
    public private(set) var update: Update?
    public private(set) var metadataHash: MetadataHash?
    public private(set) var validityStartInterval: Slot?
    public private(set) var mint: Mint?
    
    init(transactionBody: CCardano.TransactionBody) {
        inputs = transactionBody.inputs.copied()
        outputs = transactionBody.outputs.copied()
        fee = transactionBody.fee
        ttl = transactionBody.ttl.get()
        certs = transactionBody.certs.get()?.copied().map { $0.copied() }
        withdrawals = transactionBody.withdrawals.get()?.copiedDictionary()
        update = transactionBody.update.get()?.copied()
        metadataHash = transactionBody.metadata_hash.get()
        validityStartInterval = transactionBody.validity_start_interval.get()
        mint = transactionBody.mint.get()?.copiedDictionary().mapValues { $0.copiedDictionary() }
    }
    
    func clonedCTransactionBody() throws -> CCardano.TransactionBody {
        try withCTransactionBody { try $0.clone() }
    }
    
    func withCTransactionBody<T>(
        fn: @escaping (CCardano.TransactionBody) throws -> T
    ) rethrows -> T {
        try fn(CCardano.TransactionBody(
            inputs: inputs.withCArray { $0 },
            outputs: outputs.withCArray { $0 },
            fee: fee,
            ttl: ttl.cOption(),
            certs: certs.cOption { $0.withCArray { $0 } },
            withdrawals: withdrawals.cOption { $0.withCKVArray { $0 } },
            update: update.cOption { $0.withCUpdate { $0 } },
            metadata_hash: metadataHash.cOption(),
            validity_start_interval: validityStartInterval.cOption(),
            mint: mint.cOption { $0.withCKVArray { $0 } }
        ))
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
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_transaction_body_clone(self, result, error)
        }.get()
    }
}
