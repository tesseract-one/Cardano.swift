//
//  Ed25519Signature.swift
//  
//
//  Created by Ostap Danylovych on 13.05.2021.
//

import Foundation
import CCardano

typealias Ed25519Signature = CCardano.Ed25519Signature

extension Ed25519Signature {
    public init(data: Data) throws {
        self = try data.withCData { bytes in
            RustResult<Self>.wrap { result, error in
                cardano_ed25519_signature_from_bytes(bytes, result, error)
            }
        }.get()
    }
    
    public func data() throws -> Data {
        var data = try RustResult<Self>.wrap { result, error in
            cardano_ed25519_signature_to_bytes(self, result, error)
        }.get()
        return data.data()
    }
    
    public func hex() throws -> String {
        let chars = try RustResult<Self>.wrap { result, error in
            cardano_ed25519_signature_to_hex(self, result, error)
        }.get()
        return chars!.string()
    }
}
