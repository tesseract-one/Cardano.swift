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

public enum KeychainError: Error {
    case noSuchAccount(index: UInt32)
}

public class Keychain: SignatureProvider {
    private let _root: KeyPair
    private var _cache: [UInt32: KeyPair]
    private var syncQueue: DispatchQueue
    
    public init(mnemonic: [String], password: Data) throws {
        syncQueue = DispatchQueue(label: "Keychain.Sync.Queue", target: .global())
        let entropy = try Mnemonic(mnemonic: mnemonic).entropy
        _root = try KeyPair(sk: try Bip32PrivateKey(bip39: Data(entropy), password: password))
        _cache = [:]
    }
    
    public func accounts(_ cb: @escaping (Result<[Account], Error>) -> Void) {
        DispatchQueue.global().async {
            cb(.success(self.accounts()))
        }
    }
    
    public func sign(tx: ExtendedTransaction, _ cb: @escaping (Result<Transaction, Error>) -> Void) {
        fatalError("Not implemented")
    }
}

extension Keychain {
    public func addAccount(index: UInt32) throws -> Account {
        let path = Bip32Path.prefix
        let keyPair = try _root
            .derive(index: path.path[0])
            .derive(index: path.path[1])
            .derive(index: index)
        syncQueue.sync {
            _cache[index] = keyPair
        }
        return Account(publicKey: keyPair.publicKey, index: index)
    }
    
    public func accounts() -> [Account] {
        syncQueue.sync {
            _cache.map { (index, keyPair) in
                Account(publicKey: keyPair.publicKey, index: index)
            }
        }
    }
    
    public func account(index: UInt32) throws -> Account {
        return try syncQueue.sync {
            guard let keyPair = _cache[index] else {
                throw KeychainError.noSuchAccount(index: index)
            }
            return Account(publicKey: keyPair.publicKey, index: index)
        }
    }
}
