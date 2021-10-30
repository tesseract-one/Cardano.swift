//
//  AddressManager.swift
//  
//
//  Created by Ostap Danylovych on 27.10.2021.
//

import Foundation
#if !COCOAPODS
import CardanoCore
#endif

public enum AddressManagerError: Error {
    case notInCache(account: Account)
    case notInCache(address: String)
}

public protocol AddressManager {
    // Returns list of accounts
    func accounts(_ cb: @escaping (Result<[Account], Error>) -> Void)
    
    // Creates and caches new address for the Account
    func new(for account: Account, change: Bool) throws -> Address
    
    // Get cached addresses for the Account. Throws if unknown account (not fetched)
    func get(cached account: Account, change: Bool) throws -> [Address]
    
    // Fetches list of addresses for account from the network.
    func get(for account: Account,
             change: Bool,
             _ cb: @escaping (Result<[Address], Error>) -> Void)
    
    // Updates cached addresses for Accounts from the network
    func fetch(for accounts: [Account],
               _ cb: @escaping (Result<Void, Error>) -> Void)
    
    // Returns list of accounts
    func fetchedAccounts() -> [Account]
    
    // Returns extended addresses for provided addresses
    func extended(addresses: [Address]) throws -> [ExtendedAddress]
}
