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
    
    public func signAndSubmit(tx: TransactionBody,
                              with addresses: [Address],
                              metadata: TransactionMetadata?,
                              _ cb: @escaping ApiCallback<String>) throws {
        cardano.signer.sign(tx: ExtendedTransaction(
            tx: tx,
            addresses: try cardano.addresses.extended(addresses: addresses),
            metadata: metadata
        )) { res in
            switch res {
            case .success(let signed):
                submit(tx: signed, cb)
            case .failure(let error):
                cb(.failure(error))
            }
        }
    }
    
    public func submit(tx: Transaction,
                       _ cb: @escaping ApiCallback<String>) {
        cardano.network.submit(tx: tx, cb)
    }
}

extension CardanoProtocol {
    public var tx: CardanoTxApi { try! getApi() }
}
