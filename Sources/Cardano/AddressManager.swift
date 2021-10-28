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

public protocol AddressManager {
    func accounts(_ cb: @escaping (Result<[Account], Error>) -> Void)
    
    func new(for account: Account, change: Bool) -> Address
    
    func get(for account: Account,
             forceUpdate: Bool,
             _ cb: @escaping (Result<[Address], Error>) -> Void)
    
    func fetch(for accounts: [Account],
               _ cb: @escaping (Result<Void, Error>) -> Void)
    
    func extended(addresses: [Address]) throws -> [ExtendedAddress]
}

public extension AddressManager {
    func get(for account: Account,
             _ cb: @escaping (Result<[Address], Error>) -> Void) {
        self.get(for: account, forceUpdate: false, cb)
    }
}
