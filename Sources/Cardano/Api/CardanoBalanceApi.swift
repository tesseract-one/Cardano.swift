//
//  CardanoBalanceApi.swift
//  
//
//  Created by Ostap Danylovych on 05.11.2021.
//

import Foundation
#if !COCOAPODS
import CardanoCore
#endif

public struct CardanoBalanceApi: CardanoApi {
    public weak var cardano: CardanoProtocol!
    
    public init(cardano: CardanoProtocol) throws {
        self.cardano = cardano
    }
    
    public func ada(in account: Account,
                    _ cb: @escaping (Result<UInt64, Error>) -> Void) {
        cardano.addresses.get(for: account, change: false) { res in
            switch res {
            case .success(let addresses):
                addresses.asyncMap { address, mapped in
                    cardano.network.getBalance(for: address, mapped)
                }.exec { res in
                    cb(res.map { $0.reduce(0, +) })
                }
            case .failure(let error):
                cb(.failure(error))
            }
        }
    }
    
    public func ada(in address: Address,
                    _ cb: @escaping (Result<UInt64, Error>) -> Void) {
        cardano.network.getBalance(for: address, cb)
    }
}
