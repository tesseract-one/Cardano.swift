//
//  StakeCredential.swift
//  
//
//  Created by Yehor Popovych on 23.02.2021.
//

import Foundation
import CCardano

public typealias StakeCredential = CCardano.StakeCredential
public typealias Ed25519KeyHash = CCardano.Ed25519KeyHash
public typealias ScriptHash = CCardano.ScriptHash

extension Ed25519KeyHash: CType {}

extension Ed25519KeyHash {
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { res, err in
                cardano_ed25519_key_hash_from_bytes(bytes, res, err)
            }
        }.get()
    }
    
    public func data() throws -> Data {
        var data = try RustResult<Self>.wrap { res, err in
            cardano_ed25519_key_hash_to_bytes(self, res, err)
        }.get()
        return data.owned()
    }
}

extension ScriptHash: CType {}

extension ScriptHash {
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { res, err in
                cardano_script_hash_from_bytes(bytes, res, err)
            }
        }.get()
    }
    
    public func data() throws -> Data {
        var data = try RustResult<Self>.wrap { res, err in
            cardano_script_hash_to_bytes(self, res, err)
        }.get()
        return data.owned()
    }
}

extension StakeCredential: CType {}

extension StakeCredential {
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { res, err in
                cardano_stake_credential_from_bytes(bytes, res, err)
            }
        }.get()
    }
    
    public init(keyHash: Ed25519KeyHash) {
        var cred = StakeCredential()
        cred.tag = Key
        cred.key = keyHash
        self = cred
    }
    
    public init(scriptHash: ScriptHash) {
        var cred = StakeCredential()
        cred.tag = Script
        cred.script = scriptHash
        self = cred
    }
    
    public func data() throws -> Data {
        var data = try RustResult<Self>.wrap { res, err in
            cardano_stake_credential_to_bytes(self, res, err)
        }.get()
        return data.owned()
    }
    
    public var kind: UInt8 {
        tag == Key ? 0 : 1
    }
    
    public var scriptHash: ScriptHash? {
        tag == Script ? script : nil
    }
    
    public var keyHash: Ed25519KeyHash? {
        tag == Key ? key : nil
    }
}
