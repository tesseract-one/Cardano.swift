//
//  Bip32PrivateKey.swift
//  
//
//  Created by Yehor Popovych on 23.03.2021.
//

import Foundation
import CCardano

public typealias Bip32PrivateKey = CCardano.Bip32PrivateKey

extension Bip32PrivateKey: CType {}

extension Bip32PrivateKey {
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { res, err in
                cardano_bip32_private_key_from_bytes(bytes, res, err)
            }
        }.get()
    }
    
    public init(bech32: String) throws {
        self = try bech32.withCharPtr { bech32 in
            RustResult<Self>.wrap { res, err in
                cardano_bip32_private_key_from_bech32(bech32, res, err)
            }
        }.get()
    }
    
    public init(bip39 entropy: Data, password: Data) throws {
        self = try entropy.withCData { entropy in
            password.withCData { password in
                RustResult<Self>.wrap { res, err in
                    cardano_bip32_private_key_from_bip39_entropy(
                        entropy, password, res, err
                    )
                }
            }
        }.get()
    }
    
    public init(xprv128: Data) throws {
        self = try xprv128.withCData { xprv128 in
            RustResult<Self>.wrap { res, err in
                cardano_bip32_private_key_from_128_xprv(xprv128, res, err)
            }
        }.get()
    }
    
    public static func generate() throws -> Self {
        try RustResult<Self>.wrap { res, err in
            cardano_bip32_private_key_generate_ed25519_bip32(res, err)
        }.get()
    }
    
    public func bytes() throws -> Data {
        var data = try RustResult<CData>.wrap { res, err in
            cardano_bip32_private_key_as_bytes(self, res, err)
        }.get()
        return data.owned()
    }
    
    public func bech32() throws -> String {
        var str = try RustResult<CharPtr>.wrap { res, err in
            cardano_bip32_private_key_to_bech32(self, res, err)
        }.get()
        return str.owned()
    }
    
    public func to128Xprv() throws -> Data {
        var xprv128 = try RustResult<CData>.wrap { res, err in
            cardano_bip32_private_key_to_128_xprv(self, res, err)
        }.get()
        return xprv128.owned()
    }
    
    public func publicKey() throws -> Bip32PublicKey {
        return try RustResult<Bip32PublicKey>.wrap { res, err in
            cardano_bip32_private_key_to_public(self, res, err)
        }.get()
    }
    
    public func derive(index: UInt32) throws -> Self {
        return try RustResult<Self>.wrap { res, err in
            cardano_bip32_private_key_derive(self, index, res, err)
        }.get()
    }
    
    public func chaincode() throws -> Data {
        var chaincode = try RustResult<CData>.wrap { res, err in
            cardano_bip32_private_key_chaincode(self, res, err)
        }.get()
        return chaincode.owned()
    }
    
    public func toRawKey() throws -> PrivateKey {
        return try RustResult<PrivateKey>.wrap { res, err in
            cardano_bip32_private_key_to_raw_key(self, res, err)
        }.get()
    }
}
