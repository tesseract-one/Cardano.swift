//
//  Bip32PublicKey.swift
//  
//
//  Created by Yehor Popovych on 23.03.2021.
//

import Foundation
import CCardano

public typealias Bip32PublicKey = CCardano.Bip32PublicKey

extension Bip32PublicKey {
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { res, err in
                cardano_bip32_public_key_from_bytes(bytes, res, err)
            }
        }.get()
    }
    
    public init(bech32: String) throws {
        self = try bech32.withCharPtr { bech32 in
            RustResult<Self>.wrap { res, err in
                cardano_bip32_public_key_from_bech32(bech32, res, err)
            }
        }.get()
    }
    
    public func bytes() throws -> Data {
        var data = try RustResult<CData>.wrap { res, err in
            cardano_bip32_public_key_as_bytes(self, res, err)
        }.get()
        return data.data()
    }
    
    public func bech32() throws -> String {
        let str = try RustResult<CharPtr>.wrap { res, err in
            cardano_bip32_public_key_to_bech32(self, res, err)
        }.get()
        return str!.string()
    }
    
    public func chaincode() throws -> Data {
        var data = try RustResult<CData>.wrap { res, err in
            cardano_bip32_public_key_chaincode(self, res, err)
        }.get()
        return data.data()
    }
    
    public func derive(index: UInt32) throws -> Self {
        return try RustResult<Self>.wrap { res, err in
            cardano_bip32_public_key_derive(self, index, res, err)
        }.get()
    }
}
