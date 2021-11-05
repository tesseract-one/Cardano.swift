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
                    _ cb: @escaping ApiCallback<Transaction>) {
        
    }
    
    private func getUtxos(iterator: UtxoProviderAsyncIterator,
                          all: [UTXO],
                          _ cb: @escaping (Result<[UTXO], Error>) -> Void) {
        iterator.next { (res, iterator) in
            switch res {
            case .success(let utxos):
                let all = all + utxos
                guard let iterator = iterator else {
                    cb(.success(all))
                    return
                }
                getUtxos(iterator: iterator, all: all, cb)
            case .failure(let error):
                cb(.failure(error))
            }
        }
    }
    
    public func ada(to: Address,
                    amount: UInt64,
                    from: [Address],
                    _ cb: @escaping ApiCallback<String>) {
        do {
            var transactionBuilder = try TransactionBuilder(
                linearFee: cardano.info.linearFee,
                minimumUtxoVal: cardano.info.minimumUtxoVal,
                poolDeposit: cardano.info.poolDeposit,
                keyDeposit: cardano.info.keyDeposit
            )
            getUtxos(iterator: cardano.utxos.get(for: from, asset: nil), all: []) { res in
                switch res {
                case .success(let utxos):
                    do {
                        try utxos.forEach { utxo in
                            try transactionBuilder.addInput(
                                address: utxo.address,
                                input: TransactionInput(
                                    transaction_id: utxo.txHash,
                                    index: utxo.index
                                ),
                                amount: utxo.value
                            )
                        }
                        try transactionBuilder.addOutput(
                            output: TransactionOutput(address: to, amount: Value(coin: amount))
                        )
                        let transactionBody = try transactionBuilder.build()
                        let extendedTransaction = ExtendedTransaction(
                            tx: transactionBody,
                            addresses: try cardano.addresses.extended(addresses: from),
                            metadata: nil
                        )
                        cardano.signer.sign(tx: extendedTransaction) { res in
                            switch res {
                            case .success(let transaction):
                                cardano.tx.submit(tx: transaction, cb)
                            case .failure(let error):
                                cb(.failure(error))
                            }
                        }
                    } catch {
                        cb(.failure(error))
                    }
                case .failure(let error):
                    cb(.failure(error))
                }
            }
        } catch {
            cb(.failure(error))
        }
    }
}

extension CardanoProtocol {
    public var send: CardanoSendApi { try! getApi() }
}
