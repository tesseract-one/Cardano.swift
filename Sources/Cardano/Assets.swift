//
//  Assets.swift
//  
//
//  Created by Yehor Popovych on 13.05.2021.
//

import Foundation
import CCardano

// AssetNames Array
public typealias AssetNames = Array<AssetName>

extension CCardano.AssetNames: CArray {
    typealias CElement = CCardano.AssetName

    mutating func free() {
        cardano_asset_names_free(&self)
    }
}

extension AssetNames {
    func withCArray<T>(fn: @escaping (CCardano.AssetNames) throws -> T) rethrows -> T {
        try withContiguousStorageIfAvailable { storage in
            try fn(CCardano.AssetNames(ptr: storage.baseAddress, len: UInt(storage.count)))
        }!
    }
}

// Assets Dictionary
public typealias Assets = Dictionary<AssetName, UInt64>

extension CCardano.AssetsKeyValue: CType {}

extension CCardano.AssetsKeyValue: CKeyValue {
    typealias Key = AssetName
    typealias Value = UInt64
}

extension CCardano.Assets: CArray {
    typealias CElement = CCardano.AssetsKeyValue
    
    mutating func free() {
        cardano_assets_free(&self)
    }
}

extension Assets {
    func withCKVArray<T>(fn: @escaping (CCardano.Assets) throws -> T) rethrows -> T {
        try withContiguousStorageIfAvailable { storage in
            let mapped = storage.map { CCardano.Assets.CElement($0) }
            return try mapped.withUnsafeBufferPointer {
                try fn(CCardano.Assets(ptr: $0.baseAddress, len: UInt($0.count)))
            }
        }!
    }
}
