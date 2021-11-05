//
//  CardanoTxApi.swift
//  
//
//  Created by Yehor Popovych on 27.10.2021.
//

import Foundation
#if !COCOAPODS
import CardanoCore
#endif

public struct CardanoTxApi: CardanoApi {
    public weak var cardano: CardanoProtocol!
    
    public init(cardano: CardanoProtocol) throws {
        self.cardano = cardano
    }
    
    public func get(hash: String,
                    _ cb: @escaping ApiCallback<ChainTransaction>) {
        cardano.network.getTransaction(hash: hash, cb)
    }
    
    public func submit(tx: TransactionBody,
                       metadata: TransactionMetadata?,
                       _ cb: @escaping ApiCallback<Transaction>) {
        
    }
    
    public func submit(tx: Transaction,
                       _ cb: @escaping ApiCallback<String>) {
        cardano.network.submit(tx: tx, cb)
    }
}

extension CardanoProtocol {
    public var tx: CardanoTxApi { try! getApi() }
}
