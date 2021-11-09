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
                    _ cb: @escaping ApiCallback<String>) {
        let addresses: [Address]
        let change: Address
        do {
            addresses = try cardano.addresses.get(cached: from)
            change = try cardano.addresses.new(for: from, change: true)
        } catch {
            cb(.failure(error))
            return
        }
        ada(to: to, amount: amount, from: addresses, change: change, cb)
    }
    
    private func getUtxos(iterator: UtxoProviderAsyncIterator,
                          all: [UTXO],
                          currentAmount: UInt64,
                          finalAmount: UInt64,
                          _ cb: @escaping (Result<[UTXO], Error>) -> Void) {
        iterator.next { (res, iterator) in
            switch res {
            case .success(let utxosResult):
                var utxos = [UTXO]()
                var currentAmount = currentAmount
                for utxo in utxosResult {
                    utxos.append(utxo)
                    currentAmount += utxo.value.coin
                    guard currentAmount < finalAmount else {
                        cb(.success(all + utxos))
                        return
                    }
                }
                guard let iterator = iterator else {
                    cb(.success(all + utxos))
                    return
                }
                getUtxos(
                    iterator: iterator,
                    all: all + utxos,
                    currentAmount: currentAmount,
                    finalAmount: finalAmount,
                    cb
                )
            case .failure(let error):
                cb(.failure(error))
            }
        }
    }
    
    public func ada(to: Address,
                    amount: UInt64,
                    from: [Address],
                    change: Address,
                    _ cb: @escaping ApiCallback<String>) {
        do {
            var transactionBuilder = try TransactionBuilder(
                linearFee: cardano.info.linearFee,
                minimumUtxoVal: cardano.info.minimumUtxoVal,
                poolDeposit: cardano.info.poolDeposit,
                keyDeposit: cardano.info.keyDeposit
            )
            getUtxos(
                iterator: cardano.utxos.get(for: from, asset: nil),
                all: [],
                currentAmount: 0,
                finalAmount: amount
            ) { res in
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
                        let _ = try transactionBuilder.addChangeIfNeeded(address: change)
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
