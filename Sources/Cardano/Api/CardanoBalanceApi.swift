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
                    update: Bool = false,
                    _ cb: @escaping (Result<UInt64, Error>) -> Void) {
        let getBalance = { (addresses: [Address]) -> Void in
            addresses.asyncMap { address, mapped in
                cardano.network.getBalance(for: address, mapped)
            }.exec { res in
                cb(res.map { $0.reduce(0, +) })
            }
        }
        if update {
            cardano.addresses.get(for: account) { res in
                switch res {
                case .success(let addresses):
                    getBalance(addresses)
                case .failure(let error):
                    cb(.failure(error))
                }
            }
        } else {
            do {
                getBalance(try cardano.addresses.get(cached: account))
            } catch {
                cb(.failure(error))
            }
        }
    }
    
    public func ada(in address: Address,
                    _ cb: @escaping (Result<UInt64, Error>) -> Void) {
        cardano.network.getBalance(for: address, cb)
    }
}
