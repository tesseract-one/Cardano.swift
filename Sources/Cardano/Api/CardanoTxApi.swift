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
                    _ cb: @escaping ApiCallback<ChainTransaction?>) {
        cardano.network.getTransaction(hash: hash, cb)
    }
    
    public func signAndSubmit(tx: TransactionBody,
                              with addresses: [Address],
                              auxiliaryData: AuxiliaryData?,
                              _ cb: @escaping ApiCallback<String>) {
        let extended: [ExtendedAddress]
        do {
            extended = try cardano.addresses.extended(addresses: addresses)
        } catch {
            cb(.failure(error))
            return
        }
        cardano.signer.sign(tx: ExtendedTransaction(
            tx: tx,
            addresses: extended,
            auxiliaryData: auxiliaryData
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
