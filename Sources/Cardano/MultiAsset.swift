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

extension CCardano.MultiAsset: CArray {
    typealias CElement = CCardano.MultiAssetKeyValue
    
    mutating func free() {
        cardano_multi_asset_free(&self)
    }
}
