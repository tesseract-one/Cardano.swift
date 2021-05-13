//
//  Assets.swift
//  
//
//  Created by Yehor Popovych on 13.05.2021.
//

import Foundation
import CCardano

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


public typealias Assets = Dictionary<AssetName, UInt64>

extension CCardano.Assets: CMap {
    typealias Key = CCardano.AssetName
    typealias Value = UInt64
    
    mutating func free() {
        cardano_assets_free(&self)
    }
}

extension Assets: CMapConvertible {
    typealias Map = CCardano.Assets
}
