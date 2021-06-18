//
//  PrivateKey.swift
//  
//
//  Created by Ostap Danylovych on 14.05.2021.
//

import Foundation
import CCardano

public typealias PrivateKey = CCardano.PrivateKey

extension PrivateKey: CType {}

extension PrivateKey {
    var isExtended: Bool { get { self.tag == Extended } }
    var isNormal: Bool { get { self.tag == Normal } }

    public init(extendedBytes bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { result, error in
                cardano_private_key_from_extended_bytes(bytes, result, error)
            }
        }.get()
    }
    
    public init(normalBytes bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { result, error in
                cardano_private_key_from_normal_bytes(bytes, result, error)
            }
        }.get()
    }
    
    public func toPublic() throws -> PublicKey {
        try RustResult<CCardano.PublicKey>.wrap { result, error in
            cardano_private_key_to_public(self, result, error)
        }.get()
    }
    
    public func bytes() throws -> Data {
        var data = try RustResult<CData>.wrap { result, error in
            cardano_private_key_as_bytes(self, result, error)
        }.get()
        return data.owned()
    }
    
    public func sign(message: Data) throws -> Ed25519Signature {
        try message.withCData { message in
            RustResult<CCardano.Ed25519Signature>.wrap { result, error in
                cardano_private_key_sign(self, message, result, error)
            }
        }.get()
    }
}
