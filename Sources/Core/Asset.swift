//
//  Asset.swift
//  
//
//  Created by Yehor Popovych on 23.02.2021.
//

import Foundation
import CCardano

public typealias AssetName = CCardano.AssetName

extension AssetName: CType {}

extension AssetName {
    public init(name: Data) throws {
        guard name.count <= 32 else {
            throw CardanoError.outOfRange(min: 0, max: 32, found: name.count)
        }
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
        var data = try RustResult<CData>.wrap { res, err in
            cardano_asset_name_get_name(self, res, err)
        }.get()
        return data.owned()
    }
    
    public func data() throws -> Data {
        var data = try RustResult<CData>.wrap { res, err in
            cardano_asset_name_to_bytes(self, res, err)
        }.get()
        return data.owned()
    }
    
    public var bytesArray: [UInt8] {
        withUnsafeBytes(of: bytes) { ptr in
            Array(ptr.bindMemory(to: UInt8.self).prefix(Int(self.len)))
        }
    }
}

extension AssetName: Equatable {
    public static func == (lhs: AssetName, rhs: AssetName) -> Bool {
        lhs.len == rhs.len && lhs.bytesArray == rhs.bytesArray
    }
}

extension AssetName: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(len)
        hasher.combine(bytesArray)
    }
}
