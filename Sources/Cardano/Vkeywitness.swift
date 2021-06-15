//
//  Vkeywitness.swift
//  
//
//  Created by Ostap Danylovych on 15.06.2021.
//

import Foundation
import CCardano

public struct Vkeywitness {
    public private(set) var vkey: Vkey
    public private(set) var signature: Ed25519Signature
    
    init(vkeywitness: CCardano.Vkeywitness) {
        vkey = vkeywitness.vkey.copied()
        signature = vkeywitness.signature.copied()
    }
    
    public init(vkey: Vkey, signature: Ed25519Signature) {
        self.vkey = vkey
        self.signature = signature
    }
    
    func clonedCVkeywitness() throws -> CCardano.Vkeywitness {
        try withCVkeywitness { try $0.clone() }
    }
    
    func withCVkeywitness<T>(
        fn: @escaping (CCardano.Vkeywitness) throws -> T
    ) rethrows -> T {
        try vkey.withCVkey { vkey in
            try signature.withCSignature { signature in
                try fn(CCardano.Vkeywitness(vkey: vkey, signature: signature))
            }
        }
    }
}

extension CCardano.Vkeywitness: CPtr {
    typealias Value = Vkeywitness
    
    func copied() -> Vkeywitness {
        Vkeywitness(vkeywitness: self)
    }
    
    mutating func free() {
        cardano_vkeywitness_free(&self)
    }
}

extension CCardano.Vkeywitness {
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_vkeywitness_clone(self, result, error)
        }.get()
    }
}
