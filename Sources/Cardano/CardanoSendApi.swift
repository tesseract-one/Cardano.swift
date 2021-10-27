//
//  CardanoSendApi.swift
//  
//
//  Created by Yehor Popovych on 27.10.2021.
//

import Foundation
#if !COCOAPODS
import CardanoCore
#endif


public struct CardanoSendApi: CardanoApi {
    public weak var cardano: CardanoProtocol!
    
    public init(cardano: CardanoProtocol) throws {
        self.cardano = cardano
    }
    
    public func ada(to: Address,
                    amount: UInt64,
                    from: Account,
                    _ cb: ApiCallback<Transaction>) {
        
    }
    
    public func ada(to: Address,
                    amount: UInt64,
                    from: [Address],
                    _ cb: ApiCallback<Transaction>) {
        
    }
}

extension CardanoProtocol {
    public var send: CardanoSendApi { try! getApi() }
}
