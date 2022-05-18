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

public enum ScriptHashNamespace {
    case nativeScript
    
    init(namespace: CCardano.ScriptHashNamespace) {
        switch namespace {
        case NativeScriptKind: self = .nativeScript
        default: fatalError("Unknown ScriptHashNamespace type")
        }
    }
    
    func withCScriptHashNamespace<T>(
        fn: @escaping (CCardano.ScriptHashNamespace) throws -> T
    ) rethrows -> T {
        switch self {
        case .nativeScript: return try fn(NativeScriptKind)
        }
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
    
    public func hash(namespace: ScriptHashNamespace) throws -> ScriptHash {
        try withCNativeScript { try $0.hash(namespace: namespace) }
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
    public func hash(namespace: ScriptHashNamespace) throws -> ScriptHash {
        try namespace.withCScriptHashNamespace { namespace in
            RustResult<ScriptHash>.wrap { result, error in
                cardano_native_script_hash(self, namespace, result, error)
            }
        }.get()
    }
    
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_native_script_clone(self, result, error)
        }.get()
    }
}

public typealias NativeScripts = Array<NativeScript>

extension CCardano.NativeScripts: CArray {
    typealias CElement = CCardano.NativeScript
    typealias Val = [CCardano.NativeScript]

    mutating func free() {
        cardano_native_scripts_free(&self)
    }
}

extension NativeScripts {
    func withCArray<T>(fn: @escaping (CCardano.NativeScripts) throws -> T) rethrows -> T {
        try withCArray(with: { try $0.withCNativeScript(fn: $1) }, fn: fn)
    }
}

public struct PlutusScript {
    public let data: Data
    
    init(plutusScript: CCardano.PlutusScript) {
        data = plutusScript._0.copied()
    }
    
    func clonedCPlutusScript() throws -> CCardano.PlutusScript {
        try withCPlutusScript { try $0.clone() }
    }
    
    func withCPlutusScript<T>(
        fn: @escaping (CCardano.PlutusScript) throws -> T
    ) rethrows -> T {
        try data.withCData { data in
            try fn(CCardano.PlutusScript(_0: data))
        }
    }
}

extension CCardano.PlutusScript: CPtr {
    typealias Val = PlutusScript
    
    func copied() -> PlutusScript {
        PlutusScript(plutusScript: self)
    }
    
    mutating func free() {
        cardano_plutus_script_free(&self)
    }
}

extension CCardano.PlutusScript {
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_plutus_script_clone(self, result, error)
        }.get()
    }
}

public typealias PlutusScripts = Array<PlutusScript>

extension CCardano.PlutusScripts: CArray {
    typealias CElement = CCardano.PlutusScript
    typealias Val = [CCardano.PlutusScript]

    mutating func free() {
        cardano_plutus_scripts_free(&self)
    }
}

extension PlutusScripts {
    func withCArray<T>(fn: @escaping (CCardano.PlutusScripts) throws -> T) rethrows -> T {
        try withCArray(with: { try $0.withCPlutusScript(fn: $1) }, fn: fn)
    }
}

extension COption_GeneralTransactionMetadata: COption {
    typealias Tag = COption_GeneralTransactionMetadata_Tag
    typealias Value = CCardano.GeneralTransactionMetadata

    func someTag() -> Tag {
        Some_GeneralTransactionMetadata
    }

    func noneTag() -> Tag {
        None_GeneralTransactionMetadata
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

extension COption_PlutusScripts: COption {
    typealias Tag = COption_PlutusScripts_Tag
    typealias Value = CCardano.PlutusScripts

    func someTag() -> Tag {
        Some_PlutusScripts
    }

    func noneTag() -> Tag {
        None_PlutusScripts
    }
}

public struct AuxiliaryData {
    public private(set) var metadata: GeneralTransactionMetadata?
    public var nativeScripts: NativeScripts?
    public var plutusScripts: PlutusScripts?
    
    init(auxiliaryData: CCardano.AuxiliaryData) {
        metadata = auxiliaryData.metadata.get()?.copiedDictionary().mapValues { $0.copied() }
        nativeScripts = auxiliaryData.native_scripts.get()?.copied().map { $0.copied() }
        plutusScripts = auxiliaryData.plutus_scripts.get()?.copied().map { $0.copied() }
    }
    
    public init() {
    }
    
    public init(bytes: Data) throws {
        var transaction = try CCardano.AuxiliaryData(bytes: bytes)
        self = transaction.owned()
    }
    
    public func bytes() throws -> Data {
        try withCAuxiliaryData { try $0.bytes() }
    }
    
    func clonedCAuxiliaryData() throws -> CCardano.AuxiliaryData {
        try withCAuxiliaryData { try $0.clone() }
    }

    func withCAuxiliaryData<T>(
        fn: @escaping (CCardano.AuxiliaryData) throws -> T
    ) rethrows -> T {
        try metadata.withCOption(with: { try $0.withCKVArray(fn: $1) }) { metadata in
            try nativeScripts.withCOption(
                with: { try $0.withCArray(fn: $1) }
            ) { nativeScripts in
                try plutusScripts.withCOption(
                    with: { try $0.withCArray(fn: $1) }
                ) { plutusScripts in
                    try fn(CCardano.AuxiliaryData(
                        metadata: metadata,
                        native_scripts: nativeScripts,
                        plutus_scripts: plutusScripts
                    ))
                }
            }
        }
    }
}

extension CCardano.AuxiliaryData: CPtr {
    typealias Val = AuxiliaryData

    func copied() -> AuxiliaryData {
        AuxiliaryData(auxiliaryData: self)
    }

    mutating func free() {
        cardano_auxiliary_data_free(&self)
    }
}

extension CCardano.AuxiliaryData {
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { result, error in
                cardano_auxiliary_data_from_bytes(bytes, result, error)
            }
        }.get()
    }
    
    public func bytes() throws -> Data {
        var bytes = try RustResult<CData>.wrap { result, error in
            cardano_auxiliary_data_to_bytes(self, result, error)
        }.get()
        return bytes.owned()
    }

    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_auxiliary_data_clone(self, result, error)
        }.get()
    }
}
