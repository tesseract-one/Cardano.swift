//
//  Vkey.swift
//  
//
//  Created by Ostap Danylovych on 07.06.2021.
//

import Foundation
import CCardano

public typealias Vkey = CCardano.Vkey

extension Vkey: CType {}

extension Vkey {
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { result, error in
                cardano_vkey_from_bytes(bytes, result, error)
            }
        }.get()
    }
    
    public func bytes() throws -> Data {
        var data = try RustResult<CData>.wrap { data, error in
            cardano_vkey_to_bytes(self, data, error)
        }.get()
        return data.owned()
    }
}
