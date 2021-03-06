//
//  TransactionMetadata.swift
//  
//
//  Created by Ostap Danylovych on 02.07.2021.
//

import Foundation
import CCardano

public typealias TimelockStart = CCardano.TimelockStart

extension TimelockStart: CType {}

public typealias TimelockExpiry = CCardano.TimelockExpiry

extension TimelockExpiry: CType {}

public typealias ScriptPubkey = CCardano.ScriptPubkey

extension ScriptPubkey: CType {}

public struct ScriptAll {
    public private(set) var nativeScripts: NativeScripts
    
    init(scriptAll: CCardano.ScriptAll) {
        nativeScripts = scriptAll.native_scripts.copied().map { $0.copied() }
    }
    
    public init(nativeScripts: NativeScripts) {
        self.nativeScripts = nativeScripts
    }
    
    func clonedCScriptAll() throws -> CCardano.ScriptAll {
        try withCScriptAll { try $0.clone() }
    }

    func withCScriptAll<T>(
        fn: @escaping (CCardano.ScriptAll) throws -> T
    ) rethrows -> T {
        try nativeScripts.withCArray { nativeScripts in
            try fn(CCardano.ScriptAll(native_scripts: nativeScripts))
        }
    }
}

extension CCardano.ScriptAll: CPtr {
    typealias Val = ScriptAll

    func copied() -> ScriptAll {
        ScriptAll(scriptAll: self)
    }

    mutating func free() {
        cardano_script_all_free(&self)
    }
}

extension CCardano.ScriptAll {
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_script_all_clone(self, result, error)
        }.get()
    }
}

public struct ScriptAny {
    public private(set) var nativeScripts: NativeScripts
    
    init(scriptAny: CCardano.ScriptAny) {
        nativeScripts = scriptAny.native_scripts.copied().map { $0.copied() }
    }
    
    public init(nativeScripts: NativeScripts) {
        self.nativeScripts = nativeScripts
    }
    
    func clonedCScriptAny() throws -> CCardano.ScriptAny {
        try withCScriptAny { try $0.clone() }
    }

    func withCScriptAny<T>(
        fn: @escaping (CCardano.ScriptAny) throws -> T
    ) rethrows -> T {
        try nativeScripts.withCArray { nativeScripts in
            try fn(CCardano.ScriptAny(native_scripts: nativeScripts))
        }
    }
}

extension CCardano.ScriptAny: CPtr {
    typealias Val = ScriptAny

    func copied() -> ScriptAny {
        ScriptAny(scriptAny: self)
    }

    mutating func free() {
        cardano_script_any_free(&self)
    }
}

extension CCardano.ScriptAny {
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_script_any_clone(self, result, error)
        }.get()
    }
}

public struct ScriptNOfK {
    public private(set) var n: UInt32
    public private(set) var nativeScripts: NativeScripts
    
    init(scriptNOfK: CCardano.ScriptNOfK) {
        n = scriptNOfK.n
        nativeScripts = scriptNOfK.native_scripts.copied().map { $0.copied() }
    }
    
    public init(n: UInt32, nativeScripts: NativeScripts) {
        self.n = n
        self.nativeScripts = nativeScripts
    }
    
    func clonedCScriptNOfK() throws -> CCardano.ScriptNOfK {
        try withCScriptNOfK { try $0.clone() }
    }

    func withCScriptNOfK<T>(
        fn: @escaping (CCardano.ScriptNOfK) throws -> T
    ) rethrows -> T {
        try nativeScripts.withCArray { nativeScripts in
            try fn(CCardano.ScriptNOfK(n: n, native_scripts: nativeScripts))
        }
    }
}

extension CCardano.ScriptNOfK: CPtr {
    typealias Val = ScriptNOfK

    func copied() -> ScriptNOfK {
        ScriptNOfK(scriptNOfK: self)
    }

    mutating func free() {
        cardano_script_n_of_k_free(&self)
    }
}

extension CCardano.ScriptNOfK {
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_script_n_of_k_clone(self, result, error)
        }.get()
    }
}

public enum NativeScript {
    case scriptPubkey(ScriptPubkey)
    case scriptAll(ScriptAll)
    case scriptAny(ScriptAny)
    case scriptNOfK(ScriptNOfK)
    case timelockStart(TimelockStart)
    case timelockExpiry(TimelockExpiry)
    
    init(nativeScript: CCardano.NativeScript) {
        switch nativeScript.tag {
        case ScriptPubkeyKind: self = .scriptPubkey(nativeScript.script_pubkey_kind)
        case ScriptAllKind: self = .scriptAll(nativeScript.script_all_kind.copied())
        case ScriptAnyKind: self = .scriptAny(nativeScript.script_any_kind.copied())
        case ScriptNOfKKind: self = .scriptNOfK(nativeScript.script_n_of_k_kind.copied())
        case TimelockStartKind: self = .timelockStart(nativeScript.timelock_start_kind)
        case TimelockExpiryKind: self = .timelockExpiry(nativeScript.timelock_expiry_kind)
        default: fatalError("Unknown NativeScript type")
        }
    }
    
    func clonedCNativeScript() throws -> CCardano.NativeScript {
        try withCNativeScript { try $0.clone() }
    }
    
    func withCNativeScript<T>(
        fn: @escaping (CCardano.NativeScript) throws -> T
    ) rethrows -> T {
        switch self {
        case .scriptPubkey(let scriptPubkey):
            var nativeScript = CCardano.NativeScript()
            nativeScript.tag = ScriptPubkeyKind
            nativeScript.script_pubkey_kind = scriptPubkey
            return try fn(nativeScript)
        case .scriptAll(let scriptAll):
            return try scriptAll.withCScriptAll { scriptAll in
                var nativeScript = CCardano.NativeScript()
                nativeScript.tag = ScriptAllKind
                nativeScript.script_all_kind = scriptAll
                return try fn(nativeScript)
            }
        case .scriptAny(let scriptAny):
            return try scriptAny.withCScriptAny { scriptAny in
                var nativeScript = CCardano.NativeScript()
                nativeScript.tag = ScriptAnyKind
                nativeScript.script_any_kind = scriptAny
                return try fn(nativeScript)
            }
        case .scriptNOfK(let scriptNOfK):
            return try scriptNOfK.withCScriptNOfK { scriptNOfK in
                var nativeScript = CCardano.NativeScript()
                nativeScript.tag = ScriptNOfKKind
                nativeScript.script_n_of_k_kind = scriptNOfK
                return try fn(nativeScript)
            }
        case .timelockStart(let timelockStart):
            var nativeScript = CCardano.NativeScript()
            nativeScript.tag = TimelockStartKind
            nativeScript.timelock_start_kind = timelockStart
            return try fn(nativeScript)
        case .timelockExpiry(let timelockExpiry):
            var nativeScript = CCardano.NativeScript()
            nativeScript.tag = TimelockExpiryKind
            nativeScript.timelock_expiry_kind = timelockExpiry
            return try fn(nativeScript)
        }
    }
}

extension CCardano.NativeScript: CPtr {
    typealias Val = NativeScript
    
    func copied() -> NativeScript {
        NativeScript(nativeScript: self)
    }
    
    mutating func free() {
        cardano_native_script_free(&self)
    }
}

extension CCardano.NativeScript {
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_native_script_clone(self, result, error)
        }.get()
    }
}

public typealias NativeScripts = Array<NativeScript>

extension CCardano.NativeScripts: CArray {
    typealias CElement = CCardano.NativeScript

    mutating func free() {
        cardano_native_scripts_free(&self)
    }
}

extension NativeScripts {
    func withCArray<T>(fn: @escaping (CCardano.NativeScripts) throws -> T) rethrows -> T {
        try withContiguousStorageIfAvailable { storage in
            let mapped = storage.map { $0.withCNativeScript { $0 } }
            return try mapped.withUnsafeBufferPointer {
                try fn(CCardano.NativeScripts(ptr: $0.baseAddress, len: UInt($0.count)))
            }
        }!
    }
}

extension COption_NativeScripts: COption {
    typealias Tag = COption_NativeScripts_Tag
    typealias Value = CCardano.NativeScripts

    func someTag() -> Tag {
        Some_NativeScripts
    }

    func noneTag() -> Tag {
        None_NativeScripts
    }
}

public struct TransactionMetadata {
    public private(set) var general: GeneralTransactionMetadata
    public var nativeScripts: NativeScripts?
    
    init(transactionMetadata: CCardano.TransactionMetadata) {
        general = transactionMetadata.general.copiedDictionary().mapValues { $0.copied() }
        nativeScripts = transactionMetadata.native_scripts.get()?.copied().map { $0.copied() }
    }
    
    public init(general: GeneralTransactionMetadata) {
        self.general = general
    }
    
    func clonedCTransactionMetadata() throws -> CCardano.TransactionMetadata {
        try withCTransactionMetadata { try $0.clone() }
    }

    func withCTransactionMetadata<T>(
        fn: @escaping (CCardano.TransactionMetadata) throws -> T
    ) rethrows -> T {
        try fn(CCardano.TransactionMetadata(
            general: general.withCKVArray { $0 },
            native_scripts: nativeScripts.cOption { $0.withCArray { $0 }}
        ))
    }
}

extension CCardano.TransactionMetadata: CPtr {
    typealias Val = TransactionMetadata

    func copied() -> TransactionMetadata {
        TransactionMetadata(transactionMetadata: self)
    }

    mutating func free() {
        cardano_transaction_metadata_free(&self)
    }
}

extension CCardano.TransactionMetadata {
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_transaction_metadata_clone(self, result, error)
        }.get()
    }
}
