//
//  BootstrapWitness.swift
//  
//
//  Created by Ostap Danylovych on 15.06.2021.
//

import Foundation
import CCardano

public struct BootstrapWitness {
    public private(set) var vkey: Vkey
    public private(set) var signature: Ed25519Signature
    public private(set) var chainCode: Data
    public private(set) var attributes: Data
    
    init(bootstrapWitness: CCardano.BootstrapWitness) {
        vkey = bootstrapWitness.vkey
        signature = bootstrapWitness.signature
        chainCode = bootstrapWitness.chain_code.copied()
        attributes = bootstrapWitness.attributes.copied()
    }
    
    public init(vkey: Vkey, signature: Ed25519Signature, chainCode: Data, attributes: Data) {
        self.vkey = vkey
        self.signature = signature
        self.chainCode = chainCode
        self.attributes = attributes
    }
    
    public init(txBodyHash: TransactionHash, addr: ByronAddress, key: Bip32PrivateKey) throws {
        var bootstrapWitness = try CCardano.BootstrapWitness(txBodyHash: txBodyHash, addr: addr, key: key)
        self = bootstrapWitness.owned()
    }
    
    func clonedCBootstrapWitness() throws -> CCardano.BootstrapWitness {
        try withCBootstrapWitness { try $0.clone() }
    }
    
    func withCBootstrapWitness<T>(
        fn: @escaping (CCardano.BootstrapWitness) throws -> T
    ) rethrows -> T {
        try chainCode.withCData { chainCode in
            try attributes.withCData { attributes in
                try fn(CCardano.BootstrapWitness(
                    vkey: vkey,
                    signature: signature,
                    chain_code: chainCode,
                    attributes: attributes
                ))
            }
        }
    }
}

extension CCardano.BootstrapWitness: CPtr {
    typealias Val = BootstrapWitness
    
    func copied() -> BootstrapWitness {
        BootstrapWitness(bootstrapWitness: self)
    }
    
    mutating func free() {
        cardano_bootstrap_witness_free(&self)
    }
}

extension CCardano.BootstrapWitness {
    public init(txBodyHash: TransactionHash, addr: ByronAddress, key: Bip32PrivateKey) throws {
        self = try addr.withCAddress { addr in
            RustResult<Self>.wrap { result, error in
                cardano_bootstrap_witness_make_icarus_bootstrap_witness(txBodyHash, addr, key, result, error)
            }
        }.get()
    }
    
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_bootstrap_witness_clone(self, result, error)
        }.get()
    }
}

public typealias BootstrapWitnesses = Array<BootstrapWitness>

extension CCardano.BootstrapWitnesses: CArray {
    typealias CElement = CCardano.BootstrapWitness
    typealias Val = [CCardano.BootstrapWitness]

    mutating func free() {
        cardano_bootstrap_witnesses_free(&self)
    }
}

extension BootstrapWitnesses {
    func withCArray<T>(fn: @escaping (CCardano.BootstrapWitnesses) throws -> T) rethrows -> T {
        try withCArray(with: { try $0.withCBootstrapWitness(fn: $1) }, fn: fn)
    }
}
