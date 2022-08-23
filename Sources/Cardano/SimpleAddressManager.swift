//
//  SimpleAddressManager.swift
//  
//
//  Created by Ostap Danylovych on 29.10.2021.
//

import Foundation
import OrderedCollections
#if !COCOAPODS
import CardanoCore
#endif

public class SimpleAddressManager: AddressManager, CardanoBootstrapAware {
    private let fetchChunkSize = 20
    
    private weak var cardano: CardanoProtocol!
    
    private var syncQueue: DispatchQueue
    private var addresses: [Address: Bip32Path]
    private var accountAddresses: [Account: OrderedSet<Address>]
    private var accountChangeAddresses: [Account: OrderedSet<Address>]
    
    public init() {
        syncQueue = DispatchQueue(label: "AddressManager.Sync.Queue", target: .global())
        addresses = [:]
        accountAddresses = [:]
        accountChangeAddresses = [:]
    }
    
    public func bootstrap(cardano: CardanoProtocol) throws {
        self.cardano = cardano
    }
    
    private func fromIndex(for account: Account, change: Bool) -> Int {
        return syncQueue.sync {
            let addresses = (change ? accountChangeAddresses : accountAddresses)[account] ?? []
            return addresses.count
        }
    }
    
    public func accounts(_ cb: @escaping (Result<[Account], Error>) -> Void) {
        cardano.signer.accounts(cb)
    }
    
    public func new(for account: Account, change: Bool) throws -> Address {
        let from = fromIndex(for: account, change: change)
        let extended = try account.baseAddress(
            index: UInt32(from),
            change: change,
            networkID: cardano.info.networkID
        )
        try syncQueue.sync {
            guard var addresses = (change ? accountChangeAddresses : accountAddresses)[account] else {
                throw AddressManagerError.notInCache(account: account)
            }
            addresses.append(extended.address)
            if change {
                accountChangeAddresses[account] = addresses
            } else {
                accountAddresses[account] = addresses
            }
            self.addresses[extended.address] = extended.path
        }
        return extended.address
    }
    
    public func get(cached account: Account) throws -> [Address] {
        try syncQueue.sync {
            let addresses = accountAddresses[account]
            let changeAddresses = accountChangeAddresses[account]
            guard addresses != nil || changeAddresses != nil else {
                throw AddressManagerError.notInCache(account: account)
            }
            return Array(addresses ?? []) + Array(changeAddresses ?? [])
        }
    }
    
    public func get(for account: Account,
                    _ cb: @escaping (Result<[Address], Error>) -> Void) {
        fetch(for: [account]) { res in
            cb(res.flatMap {
                Result { try self.get(cached: account) }
            })
        }
    }
    
    private func fetchNext(for account: Account,
                           index: Int,
                           all: [(ExtendedAddress, Bool)],
                           change: Bool,
                           _ cb: @escaping (Result<[ExtendedAddress], Error>) -> Void) {
        let addresses: [ExtendedAddress]
        do {
            addresses = try (0..<fetchChunkSize).map { offset in
                try account.baseAddress(
                    index: UInt32(index + offset),
                    change: change,
                    networkID: cardano.info.networkID
                )
            }
        } catch {
            cb(.failure(error))
            return
        }
        addresses.asyncMap { address, mapped in
            self.cardano.network.getTransactionCount(for: address.address) { res in
                mapped(res.map { (address, $0 > 0) })
            }
        }.exec { res in
            switch res {
            case .success(let addresses):
                let all = all + addresses
                guard let lastNotEmpty = all.lastIndex(where: { $0.1 }) else {
                    cb(.success([]))
                    return
                }
                if all.count - lastNotEmpty > self.fetchChunkSize {
                    cb(.success(all.dropLast(all.count - lastNotEmpty - 1).map { $0.0 }))
                } else {
                    self.fetchNext(
                        for: account,
                        index: index + self.fetchChunkSize,
                        all: all,
                        change: change,
                        cb
                    )
                }
            case .failure(let error):
                cb(.failure(error))
            }
        }
    }
    
    public func fetch(for accounts: [Account],
                      _ cb: @escaping (Result<Void, Error>) -> Void) {
        [true, false].asyncMap { change, mapped in
            accounts.asyncMap { account, mapped in
                self.fetchNext(
                    for: account,
                    index: self.fromIndex(for: account, change: false),
                    all: [],
                    change: change
                ) { res in
                    mapped(res.map { addresses in
                        self.syncQueue.sync {
                            addresses.forEach { address in
                                self.addresses[address.address] = address.path
                            }
                            if change {
                                var accountChangeAddresses = self.accountChangeAddresses[account] ?? []
                                accountChangeAddresses.append(contentsOf: addresses.map { $0.address })
                                self.accountChangeAddresses[account] = accountChangeAddresses
                            } else {
                                var accountAddresses = self.accountAddresses[account] ?? []
                                accountAddresses.append(contentsOf: addresses.map { $0.address })
                                self.accountAddresses[account] = accountAddresses
                            }
                        }
                    })
                }
            }.exec(mapped)
        }.exec { cb($0.map { _ in }) }
    }
    
    public func fetch(_ cb: @escaping (Result<Void, Error>) -> Void) {
        cardano.signer.accounts { res in
            switch res {
            case .failure(let err): cb(.failure(err))
            case .success(let accounts): self.fetch(for: accounts, cb)
            }
        }
    }
    
    public func fetchedAccounts() -> [Account] {
        syncQueue.sync {
            Array(accountAddresses.keys) + accountChangeAddresses.keys.filter {
                !accountAddresses.keys.contains($0)
            }
        }
    }
    
    public func extended(addresses: [Address]) throws -> [ExtendedAddress] {
        try syncQueue.sync {
            try addresses.map { address in
                guard let path = self.addresses[address] else {
                    throw try AddressManagerError.notInCache(address: address.bech32())
                }
                return ExtendedAddress(address: address, path: path)
            }
        }
    }
}
