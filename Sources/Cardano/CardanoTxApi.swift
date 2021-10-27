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
    
    public func get(id: TransactionHash,
                    _ cb: @escaping ApiCallback<Transaction>) {
        
    }
    
    public func submit(tx: TransactionBody,
                       metadata: TransactionMetadata?,
                       _ cb: @escaping ApiCallback<Transaction>) {
        
    }
    
    public func submit(tx: Transaction,
                       _ cb: @escaping ApiCallback<Transaction>) {
        
    }
}

extension CardanoProtocol {
    public var tx: CardanoTxApi { try! getApi() }
}
