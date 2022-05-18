//
//  TransactionWitnessSet.swift
//  
//
//  Created by Ostap Danylovych on 16.06.2021.
//

import Foundation
import CCardano
import BigInt

public struct ConstrPlutusData: Hashable {
    public let alternative: BigNum
    public let data: PlutusList
    
    init(constrPlutusData: CCardano.ConstrPlutusData) {
        alternative = constrPlutusData.alternative
        data = constrPlutusData.data.copied().map { $0.copied() }
    }
    
    func clonedCConstrPlutusData() throws -> CCardano.ConstrPlutusData {
        try withCConstrPlutusData { try $0.clone() }
    }
    
    func withCConstrPlutusData<T>(
        fn: @escaping (CCardano.ConstrPlutusData) throws -> T
    ) rethrows -> T {
        try data.withCArray { data in
            try fn(CCardano.ConstrPlutusData(alternative: alternative, data: data))
        }
    }
}

extension CCardano.ConstrPlutusData: CPtr {
    typealias Val = ConstrPlutusData
    
    func copied() -> ConstrPlutusData {
        ConstrPlutusData(constrPlutusData: self)
    }
    
    mutating func free() {
        cardano_constr_plutus_data_free(&self)
    }
}

extension CCardano.ConstrPlutusData {
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_constr_plutus_data_clone(self, result, error)
        }.get()
    }
}

public typealias PlutusMap = Dictionary<PlutusData, PlutusData>

extension PlutusMapKeyValue: CType {}

extension PlutusMapKeyValue: CKeyValue {
    typealias Key = CCardano.PlutusData
    typealias Value = CCardano.PlutusData
}

extension CCardano.PlutusMap: CArray {
    typealias CElement = PlutusMapKeyValue
    typealias Val = [PlutusMapKeyValue]
    
    init(ptr: UnsafePointer<PlutusMapKeyValue>!, len: UInt) {
        self.init(cptr: UnsafeRawPointer(ptr), len: len)
    }
    
    var ptr: UnsafePointer<PlutusMapKeyValue>! {
        get { cptr.assumingMemoryBound(to: PlutusMapKeyValue.self) }
        set { cptr = UnsafeRawPointer(newValue) }
    }

    mutating func free() {
        cardano_plutus_map_free(&self)
    }
}

extension PlutusMap {
    func withCKVArray<T>(fn: @escaping (CCardano.PlutusMap) throws -> T) rethrows -> T {
        try withCKVArray(
            withKey: { try $0.withCPlutusData(fn: $1) },
            withValue: { try $0.withCPlutusData(fn: $1) },
            fn: fn
        )
    }
}

public typealias PlutusList = Array<PlutusData>

extension CCardano.PlutusList: CArray {
    typealias CElement = CCardano.PlutusData
    typealias Val = [CCardano.PlutusData]

    mutating func free() {
        cardano_plutus_list_free(&self)
    }
}

extension PlutusList {
    func withCArray<T>(fn: @escaping (CCardano.PlutusList) throws -> T) rethrows -> T {
        try withCArray(with: { try $0.withCPlutusData(fn: $1) }, fn: fn)
    }
}

public enum PlutusData: Equatable, Hashable {
    case constrPlutusData(ConstrPlutusData)
    case map(PlutusMap)
    case list(PlutusList)
    case integer(BigInt)
    case bytes(Data)
    
    init(plutusData: CCardano.PlutusData) {
        switch plutusData.tag {
        case ConstrPlutusDataKind: self = .constrPlutusData(plutusData.constr_plutus_data_kind.copied())
        case MapKind:
            let map = plutusData.map_kind.copiedOrderedDictionary()
                .map { key, value in (key.copied(), value.copied()) }
            self = .map(Dictionary(uniqueKeysWithValues: map))
        case ListKind:
            self = .list(plutusData.list_kind.copied().map {
                $0.copied()
            })
        case IntegerKind: self = .integer(plutusData.integer_kind.bigInt)
        case PlutusBytesKind: self = .bytes(plutusData.plutus_bytes_kind.copied())
        default: fatalError("Unknown PlutusData type")
        }
    }
    
    func clonedCPlutusData() throws -> CCardano.PlutusData {
        try withCPlutusData { try $0.clone() }
    }
    
    func withCPlutusData<T>(
        fn: @escaping (CCardano.PlutusData) throws -> T
    ) rethrows -> T {
        switch self {
        case .constrPlutusData(let constrPlutusData):
            return try constrPlutusData.withCConstrPlutusData { constrPlutusData in
                var plutusData = CCardano.PlutusData()
                plutusData.tag = ConstrPlutusDataKind
                plutusData.constr_plutus_data_kind = constrPlutusData
                return try fn(plutusData)
            }
        case .map(let map):
            return try map.withCKVArray { map in
                var plutusData = CCardano.PlutusData()
                plutusData.tag = MapKind
                plutusData.map_kind = map
                return try fn(plutusData)
            }
        case .list(let list):
            return try list.withCArray { list in
                var plutusData = CCardano.PlutusData()
                plutusData.tag = ListKind
                plutusData.list_kind = list
                return try fn(plutusData)
            }
        case .integer(let integer):
            return try integer.cBigInt { integer in
                var plutusData = CCardano.PlutusData()
                plutusData.tag = IntegerKind
                plutusData.integer_kind = integer
                return try fn(plutusData)
            }
        case .bytes(let bytes):
            return try bytes.withCData { bytes in
                var plutusData = CCardano.PlutusData()
                plutusData.tag = PlutusBytesKind
                plutusData.plutus_bytes_kind = bytes
                return try fn(plutusData)
            }
        }
    }
}

extension CCardano.PlutusData: CPtr {
    typealias Val = PlutusData
    
    func copied() -> PlutusData {
        PlutusData(plutusData: self)
    }
    
    mutating func free() {
        cardano_plutus_data_free(&self)
    }
}

extension CCardano.PlutusData {
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_plutus_data_clone(self, result, error)
        }.get()
    }
}

extension CCardano.PlutusData: Equatable {
    public static func == (
        lhs: CCardano.PlutusData,
        rhs: CCardano.PlutusData
    ) -> Bool {
        lhs.copied() == rhs.copied()
    }
}

extension CCardano.PlutusData: Hashable {
    public func hash(into hasher: inout Hasher) {
        self.copied().hash(into: &hasher)
    }
}

public enum RedeemerTag {
    case spend
    case mint
    case cert
    case reward

    init(redeemerTag: CCardano.RedeemerTag) {
        switch redeemerTag {
        case SpendKind: self = .spend
        case MintKind: self = .mint
        case CertKind: self = .cert
        case RewardKind: self = .reward
        default: fatalError("Unknown RedeemerTag type")
        }
    }

    func withCRedeemerTag<T>(
        fn: @escaping (CCardano.RedeemerTag) throws -> T
    ) rethrows -> T {
        switch self {
        case .spend: return try fn(SpendKind)
        case .mint: return try fn(MintKind)
        case .cert: return try fn(CertKind)
        case .reward: return try fn(RewardKind)
        }
    }
}

public struct Redeemer {
    public let tag: RedeemerTag
    public let index: BigNum
    public let data: PlutusData
    public let exUnits: ExUnits
    
    init(redeemer: CCardano.Redeemer) {
        tag = RedeemerTag(redeemerTag: redeemer.tag)
        index = redeemer.index
        data = redeemer.data.copied()
        exUnits = redeemer.ex_units
    }
    
    func clonedCRedeemer() throws -> CCardano.Redeemer {
        try withCRedeemer { try $0.clone() }
    }
    
    func withCRedeemer<T>(
        fn: @escaping (CCardano.Redeemer) throws -> T
    ) rethrows -> T {
        try tag.withCRedeemerTag { tag in
            try data.withCPlutusData { data in
                try fn(CCardano.Redeemer(
                    tag: tag,
                    index: index,
                    data: data,
                    ex_units: exUnits
                ))
            }
        }
    }
}

extension CCardano.Redeemer: CPtr {
    typealias Val = Redeemer
    
    func copied() -> Redeemer {
        Redeemer(redeemer: self)
    }
    
    mutating func free() {
        cardano_redeemer_free(&self)
    }
}

extension CCardano.Redeemer {
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_redeemer_clone(self, result, error)
        }.get()
    }
}

public typealias Redeemers = Array<Redeemer>

extension CCardano.Redeemers: CArray {
    typealias CElement = CCardano.Redeemer
    typealias Val = [CCardano.Redeemer]

    mutating func free() {
        cardano_redeemers_free(&self)
    }
}

extension Redeemers {
    func withCArray<T>(fn: @escaping (CCardano.Redeemers) throws -> T) rethrows -> T {
        try withCArray(with: { try $0.withCRedeemer(fn: $1) }, fn: fn)
    }
}

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

extension COption_PlutusList: COption {
    typealias Tag = COption_PlutusList_Tag
    typealias Value = CCardano.PlutusList
    
    func someTag() -> Tag {
        Some_PlutusList
    }
    
    func noneTag() -> Tag {
        None_PlutusList
    }
}

extension COption_Redeemers: COption {
    typealias Tag = COption_Redeemers_Tag
    typealias Value = CCardano.Redeemers
    
    func someTag() -> Tag {
        Some_Redeemers
    }
    
    func noneTag() -> Tag {
        None_Redeemers
    }
}

public struct TransactionWitnessSet {
    public var vkeys: Vkeywitnesses?
    public var nativeScripts: NativeScripts?
    public var bootstraps: BootstrapWitnesses?
    public var plutusScripts: PlutusScripts?
    public var plutusData: PlutusList?
    public var redeemers: Redeemers?
    
    init(transactionWitnessSet: CCardano.TransactionWitnessSet) {
        vkeys = transactionWitnessSet.vkeys.get()?.copied()
        nativeScripts = transactionWitnessSet.native_scripts.get()?.copied().map { $0.copied() }
        bootstraps = transactionWitnessSet.bootstraps.get()?.copied().map { $0.copied() }
        plutusScripts = transactionWitnessSet.plutus_scripts.get()?.copied().map { $0.copied() }
        plutusData = transactionWitnessSet.plutus_data.get()?.copied().map { $0.copied() }
        redeemers = transactionWitnessSet.redeemers.get()?.copied().map { $0.copied() }
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
            try nativeScripts.withCOption(
                with: { try $0.withCArray(fn: $1) }
            ) { nativeScripts in
                try bootstraps.withCOption(
                    with: { try $0.withCArray(fn: $1) }
                ) { bootstraps in
                    try plutusScripts.withCOption(
                        with: { try $0.withCArray(fn: $1) }
                    ) { plutusScripts in
                        try plutusData.withCOption(
                            with: { try $0.withCArray(fn: $1) }
                        ) { plutusData in
                            try redeemers.withCOption(
                                with: { try $0.withCArray(fn: $1) }
                            ) { redeemers in
                                try fn(CCardano.TransactionWitnessSet(
                                    vkeys: vkeys,
                                    native_scripts: nativeScripts,
                                    bootstraps: bootstraps,
                                    plutus_scripts: plutusScripts,
                                    plutus_data: plutusData,
                                    redeemers: redeemers
                                ))
                            }
                        }
                    }
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
