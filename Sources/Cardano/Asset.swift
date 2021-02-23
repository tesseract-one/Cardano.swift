//
//  Asset.swift
//  
//
//  Created by Yehor Popovych on 23.02.2021.
//

import Foundation
import CCardano

public typealias AssetName = CCardano.AssetName

extension AssetName {
    public init(name: Data) throws {
        self = try name.withCData { bytes in
            RustResult<Self>.wrap { res, err in
                cardano_asset_name_new(bytes, res, err)
            }
        }.get()
    }
    
    public init(data: Data) throws {
        self = try data.withCData { bytes in
            RustResult<Self>.wrap { res, err in
                cardano_asset_name_from_bytes(bytes, res, err)
            }
        }.get()
    }
    
    public func name() throws -> Data {
        var data = try RustResult<Self>.wrap { res, err in
            cardano_asset_name_get_name(self, res, err)
        }.get()
        return data.data()
    }
    
    public func data() throws -> Data {
        var data = try RustResult<Self>.wrap { res, err in
            cardano_asset_name_to_bytes(self, res, err)
        }.get()
        return data.data()
    }
}
