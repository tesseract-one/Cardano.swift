//
//  PublicKey.swift
//  
//
//  Created by Ostap Danylovych on 13.05.2021.
//

import Foundation
import CCardano

public typealias PublicKey = CCardano.PublicKey

extension PublicKey: CType {}

extension PublicKey {
    public init(bech32: String) throws {
        self = try bech32.withCharPtr { bech32 in
            RustResult<Self>.wrap { result, error in
                cardano_public_key_from_bech32(bech32, result, error)
            }
        }.get()
    }
    
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { address, error in
                cardano_public_key_from_bytes(bytes, address, error)
            }
        }.get()
    }
    
    public func bech32() throws -> String {
        var str = try RustResult<CharPtr>.wrap { result, error in
            cardano_public_key_to_bech32(self, result, error)
        }.get()
        return str.owned()
    }
    
    public func bytes() throws -> Data {
        var data = try RustResult<CData>.wrap { data, error in
            cardano_public_key_as_bytes(self, data, error)
        }.get()
        return data.owned()
    }
    
    public func hash() throws -> Ed25519KeyHash {
        try RustResult<Ed25519KeyHash>.wrap { result, error in
            cardano_public_key_hash(self, result, error)
        }.get()
    }
}
