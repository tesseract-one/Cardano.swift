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
    typealias Value = CCardano.AssetName
    
    mutating func free() {
        cardano_asset_names_free(&self)
    }
}

extension AssetNames: CArrayConvertible {
    typealias Arr = CCardano.AssetNames;
}

// Assets Dictionary
public typealias Assets = Dictionary<AssetName, UInt64>

extension CCardano.AssetsKeyValue: CKeyValue {
    typealias Key = AssetName
    typealias Value = UInt64
}

extension CCardano.Assets: CArray {
    typealias Value = CCardano.AssetsKeyValue
    
    mutating func free() {
        cardano_assets_free(&self)
    }
}

extension Assets: CKeyValueArrayConvertible {
    typealias Arr = CCardano.Assets
}
