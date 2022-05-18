//
//  MultiAsset.swift
//  
//
//  Created by Ostap Danylovych on 15.05.2021.
//

import Foundation
import CCardano

public typealias PolicyID = ScriptHash
public typealias MultiAsset = Dictionary<PolicyID, Assets>

extension CCardano.MultiAssetKeyValue: CType {}

extension CCardano.MultiAssetKeyValue: CKeyValue {
    typealias Key = PolicyID
    typealias Value = CCardano.Assets
}

extension CCardano.MultiAsset: CArray {
    typealias CElement = CCardano.MultiAssetKeyValue
    typealias Val = [CCardano.MultiAssetKeyValue]

    mutating func free() {
        cardano_multi_asset_free(&self)
    }
}

extension MultiAsset {
    public func sub(rhsMA: MultiAsset) throws -> MultiAsset {
        try self.withCKVArray { multiAsset in
            try multiAsset.sub(rhsMA: rhsMA)
        }
    }
    
    func withCKVArray<T>(fn: @escaping (CCardano.MultiAsset) throws -> T) rethrows -> T {
        try withCKVArray(withValue: { try $0.withCKVArray(fn: $1) }, fn: fn)
    }
}

extension CCardano.MultiAsset {
    public func sub(rhsMA: MultiAsset) throws -> MultiAsset {
        var multiAsset = try rhsMA.withCKVArray { rhsMA in
            RustResult<CCardano.MultiAsset>.wrap { result, error in
                cardano_multi_asset_sub(self, rhsMA, result, error)
            }
        }.get()
        return multiAsset.ownedDictionary().mapValues {
            var val = $0
            return val.ownedDictionary()
        }
    }
}
