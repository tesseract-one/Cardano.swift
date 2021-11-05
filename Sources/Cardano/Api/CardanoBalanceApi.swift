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
                    _ cb: @escaping (Result<UInt64, Error>) -> Void) -> UInt64 {
        fatalError("Not implemented")
    }
    
    public func ada(in address: Address,
                    _ cb: @escaping (Result<UInt64, Error>) -> Void) {
        cardano.network.getBalance(for: address, cb)
    }
}
