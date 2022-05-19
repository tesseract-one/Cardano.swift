//
//  Keychain.swift
//  
//
//  Created by Ostap Danylovych on 04.11.2021.
//

import Foundation
import Bip39
#if !COCOAPODS
import CardanoCore
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
    
    func vkeyWitness(transactionHash: TransactionHash) throws -> Vkeywitness {
        try Vkeywitness(txBodyHash: transactionHash, sk: _sk.toRawKey())
    }
    
    func bootstrapWitness(transactionHash: TransactionHash,
                          address: ByronAddress) throws -> BootstrapWitness {
        try BootstrapWitness(txBodyHash: transactionHash, addr: address, key: _sk)
    }
}

public enum KeychainError: Error {
    case accountNotFound(index: UInt32)
    case accountNotFound(path: Bip32Path)
    case derivationFailed(address: Bip32Path)
}

public class Keychain {
    private let _root: KeyPair
    private var _cache: [UInt32: KeyPair]
    private var syncQueue: DispatchQueue
    
    public init(mnemonic: [String], password: Data? = nil) throws {
        syncQueue = DispatchQueue(label: "Keychain.Sync.Queue", target: .global())
        let entropy = try Mnemonic(mnemonic: mnemonic).entropy
        let b32Key = try Bip32PrivateKey(bip39: Data(entropy), password: password ?? Data())
        _root = try KeyPair(sk: b32Key)
        _cache = [:]
    }
    
    private func deriveKeyPair(for path: Bip32Path) -> Result<KeyPair, KeychainError> {
        guard let keyPair = _cache[path.accountIndex!] else {
            return .failure(.accountNotFound(path: path))
        }
        let derived = try? keyPair.derive(index: path.isChange! ? 1 : 0)
            .derive(index: path.addressIndex!)
        guard let derivedKeyPair = derived else {
            return .failure(.derivationFailed(address: path))
        }
        return .success(derivedKeyPair)
    }
    
    @discardableResult
    public func addAccount(index: UInt32) throws -> Account {
        var path = Bip32Path.prefix
        path = try path.appending(index, hard: true)
        let keyPair = try _root
            .derive(index: path.path[0])
            .derive(index: path.path[1])
            .derive(index: path.path[2])
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
                throw KeychainError.accountNotFound(index: index)
            }
            return Account(publicKey: keyPair.publicKey, index: index)
        }
    }
}

extension Keychain: SignatureProvider {
    public func accounts(_ cb: @escaping (Result<[Account], Error>) -> Void) {
        DispatchQueue.global().async {
            cb(.success(self.accounts()))
        }
    }
    
    public func sign(tx: ExtendedTransaction, _ cb: @escaping (Result<Transaction, Error>) -> Void) {
        DispatchQueue.global().async {
            var vkeyWitnesses: Vkeywitnesses = []
            var bootstrapWitnesses: BootstrapWitnesses = []
            do {
                for extended in tx.addresses {
                    switch self.deriveKeyPair(for: extended.path) {
                    case .success(let keyPair):
                        let transactionHash = try TransactionHash(txBody: tx.tx)
                        switch extended.address {
                        case .base:
                            vkeyWitnesses.append(try keyPair.vkeyWitness(
                                transactionHash: transactionHash
                            ))
                        case .pointer:
                            vkeyWitnesses.append(try keyPair.vkeyWitness(
                                transactionHash: transactionHash
                            ))
                        case .enterprise:
                            vkeyWitnesses.append(try keyPair.vkeyWitness(
                                transactionHash: transactionHash
                            ))
                        case .byron(let byron):
                            bootstrapWitnesses.append(try keyPair.bootstrapWitness(
                                transactionHash: transactionHash,
                                address: byron
                            ))
                        default:
                            break
                        }
                    case .failure(let error):
                        cb(.failure(error))
                        return
                    }
                }
            } catch {
                cb(.failure(error))
                return
            }
            var witnessSet = TransactionWitnessSet()
            if !vkeyWitnesses.isEmpty {
                witnessSet.vkeys = vkeyWitnesses
            }
            if !bootstrapWitnesses.isEmpty {
                witnessSet.bootstraps = bootstrapWitnesses
            }
            cb(.success(Transaction(
                body: tx.tx,
                witnessSet: witnessSet,
                auxiliaryData: tx.auxiliaryData
            )))
        }
    }
}
