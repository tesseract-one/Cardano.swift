//
//  Value.swift
//  
//
//  Created by Ostap Danylovych on 28.06.2021.
//

import Foundation
import CCardano

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

public struct Value {
    public private(set) var coin: Coin
    public private(set) var multiasset: MultiAsset?
    
    init(value: CCardano.Value) {
        coin = value.coin
        multiasset = value.multiasset.get()?.copiedDictionary().mapValues { $0.copiedDictionary() }
    }
    
    func clonedCValue() throws -> CCardano.Value {
        try withCValue { try $0.clone() }
    }

    func withCValue<T>(
        fn: @escaping (CCardano.Value) throws -> T
    ) rethrows -> T {
        try fn(CCardano.Value(
            coin: coin,
            multiasset: multiasset.cOption { $0.withCKVArray { $0 } }
        ))
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
            try RustResult<CCardano.Value>.wrap { result, error in
                cardano_value_checked_add(self, rhs, result, error)
            }.get()
        }
        return value.owned()
    }
    
    public func checkedSub(rhs: Value) throws -> Value {
        var value = try rhs.withCValue { rhs in
            try RustResult<CCardano.Value>.wrap { result, error in
                cardano_value_checked_sub(self, rhs, result, error)
            }.get()
        }
        return value.owned()
    }
    
    public func clampedSub(rhs: Value) throws -> Value {
        var value = try rhs.withCValue { rhs in
            try RustResult<CCardano.Value>.wrap { result, error in
                cardano_value_clamped_sub(self, rhs, result, error)
            }.get()
        }
        return value.owned()
    }
    
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_value_clone(self, result, error)
        }.get()
    }
}
