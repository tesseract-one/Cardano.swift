//
//  Keychain.swift
//  
//
//  Created by Ostap Danylovych on 04.11.2021.
//

import Foundation
#if !COCOAPODS
import CardanoCore
import Bip39
#endif

struct KeyPair {
    let publicKey: Bip32PublicKey
    private let _sk: Bip32PrivateKey

    init(sk: Bip32PrivateKey) throws {
        _sk = sk
        try publicKey = sk.publicKey()
    }
    
    func derive(index: UInt32) throws -> Self {
        try Self(sk: _sk.derive(index: index))
    }
}

public class Keychain: SignatureProvider {
    private let _root: KeyPair
    private var _cache: [UInt32: KeyPair]
    
    public init(mnemonic: [String], password: Data) throws {
        let entropy = try Mnemonic(mnemonic: mnemonic).entropy
        _root = try KeyPair(sk: try Bip32PrivateKey(bip39: Data(entropy), password: password))
        _cache = [:]
    }
    
    public func addAccount(index: UInt32) throws {
        let path = Bip32Path.prefix
        let keyPair = try _root
            .derive(index: path.path[0])
            .derive(index: path.path[1])
            .derive(index: index)
        _cache[index] = keyPair
    }
    
    public func accounts(_ cb: @escaping (Result<[Account], Error>) -> Void) {
        DispatchQueue.global().async {
            let accounts = self._cache.map { (index, keyPair) in
                Account(publicKey: keyPair.publicKey, index: index)
            }
            cb(.success(accounts))
        }
    }
    
    public func sign(tx: ExtendedTransaction, _ cb: @escaping (Result<Transaction, Error>) -> Void) {
        fatalError("Not implemented")
    }
}
