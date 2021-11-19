//
//  Value.swift
//  
//
//  Created by Ostap Danylovych on 28.06.2021.
//

import Foundation
import CCardano

public enum Ordering {
    case less
    case equal
    case greater
    
    init(ordering: CCardano.COrdering) {
        switch ordering._0 {
        case Less: self = .less
        case Equal: self = .equal
        case Greater: self = .greater
        default: fatalError("Unknown COrdering type")
        }
    }
    
    func withCOrdering<T>(
        fn: @escaping (CCardano.COrdering) throws -> T
    ) rethrows -> T {
        switch self {
        case .less: return try fn(CCardano.COrdering(_0: Less))
        case .equal: return try fn(CCardano.COrdering(_0: Equal))
        case .greater: return try fn(CCardano.COrdering(_0: Greater))
        }
    }
}

extension CCardano.COrdering: CPtr {
    typealias Val = Ordering
    
    func copied() -> Ordering {
        Ordering(ordering: self)
    }
    
    mutating func free() {}
}

extension COption_MultiAsset: COption {
    typealias Tag = COption_MultiAsset_Tag
    typealias Value = CCardano.MultiAsset

    func someTag() -> Tag {
        Some_MultiAsset
    }

    func noneTag() -> Tag {
        None_MultiAsset
    }
}

public struct Value: Equatable {
    public var coin: Coin
    public var multiasset: MultiAsset?
    
    init(value: CCardano.Value) {
        coin = value.coin
        multiasset = value.multiasset.get()?.copiedDictionary().mapValues {
            $0.copiedDictionary()
        }
    }
    
    public init(coin: Coin) {
        self.coin = coin
    }
    
    public func checkedAdd(rhs: Value) throws -> Value {
        try withCValue { try $0.checkedAdd(rhs: rhs) }
    }
    
    public func checkedSub(rhs: Value) throws -> Value {
        try withCValue { try $0.checkedSub(rhs: rhs) }
    }
    
    public func clampedSub(rhs: Value) throws -> Value {
        try withCValue { try $0.clampedSub(rhs: rhs) }
    }
    
    public func compare(rhs: Value) throws -> Int8? {
        try withCValue { try $0.compare(rhs: rhs) }
    }
    
    public func partialCmp(other: Value) throws -> Ordering? {
        try withCValue { try $0.partialCmp(other: other) }
    }
    
    public func minAdaRequired(hasDataHash: Bool, coinsPerUtxoWord: UInt64) throws -> UInt64 {
        try withCValue { try $0.minAdaRequired(hasDataHash: hasDataHash,
                                               coinsPerUtxoWord: coinsPerUtxoWord) }
    }

    func clonedCValue() throws -> CCardano.Value {
        try withCValue { try $0.clone() }
    }

    func withCValue<T>(
        fn: @escaping (CCardano.Value) throws -> T
    ) rethrows -> T {
        try multiasset.withCOption(
            with: { try $0.withCKVArray(fn: $1) }
        ) { multiasset in
            try fn(CCardano.Value(
                coin: coin,
                multiasset: multiasset
            ))
        }
    }
}

extension CCardano.Value: CPtr {
    typealias Val = Value

    func copied() -> Value {
        Value(value: self)
    }

    mutating func free() {
        cardano_value_free(&self)
    }
}

extension CCardano.Value {
    public func checkedAdd(rhs: Value) throws -> Value {
        var value = try rhs.withCValue { rhs in
            RustResult<CCardano.Value>.wrap { result, error in
                cardano_value_checked_add(self, rhs, result, error)
            }
        }.get()
        return value.owned()
    }
    
    public func checkedSub(rhs: Value) throws -> Value {
        var value = try rhs.withCValue { rhs in
            RustResult<CCardano.Value>.wrap { result, error in
                cardano_value_checked_sub(self, rhs, result, error)
            }
        }.get()
        return value.owned()
    }
    
    public func clampedSub(rhs: Value) throws -> Value {
        var value = try rhs.withCValue { rhs in
            RustResult<CCardano.Value>.wrap { result, error in
                cardano_value_clamped_sub(self, rhs, result, error)
            }
        }.get()
        return value.owned()
    }
    
    public func compare(rhs: Value) throws -> Int8? {
        try rhs.withCValue { rhs in
            RustResult<Int8>.wrap { result, error in
                cardano_value_compare(self, rhs, result, error)
            }
        }.get()
    }
    
    public func partialCmp(other: Value) throws -> Ordering? {
        let ordering = try other.withCValue { other in
            RustResult<COrdering>.wrap { result, error in
                cardano_value_partial_cmp(self, other, result, error)
            }
        }.get()
        if var ordering = ordering {
            return ordering.owned()
        } else {
            return nil
        }
    }
    
    public func minAdaRequired(hasDataHash: Bool, coinsPerUtxoWord: UInt64) throws -> UInt64 {
        try RustResult<UInt64>.wrap { result, error in
            cardano_value_min_ada_required(self, hasDataHash, coinsPerUtxoWord, result, error)
        }.get()
    }
    
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_value_clone(self, result, error)
        }.get()
    }
}
