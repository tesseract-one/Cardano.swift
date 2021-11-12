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
                    change: Address? = nil,
                    _ cb: @escaping ApiCallback<String>) {
        let addresses: [Address]
        let changeAddress: Address
        do {
            addresses = try cardano.addresses.get(cached: from)
            changeAddress = try change ?? cardano.addresses.new(for: from, change: true)
        } catch {
            cb(.failure(error))
            return
        }
        ada(to: to, amount: amount, from: addresses, change: changeAddress, cb)
    }
    
    private func getUtxos(iterator: UtxoProviderAsyncIterator,
                          to: Address,
                          amount: UInt64,
                          change: Address,
                          slot: Int?,
                          maxSlots: UInt32,
                          all: [UTXO],
                          _ cb: @escaping (Result<TransactionBuilder, Error>) -> Void) {
        iterator.next { (res, iterator) in
            switch res {
            case .success(let utxosResult):
                var notEnoughUtxos: Error?
                var utxos = [UTXO]()
                do {
                    for utxo in utxosResult {
                        utxos.append(utxo)
                        var transactionBuilder = try TransactionBuilder(
                            linearFee: cardano.info.linearFee,
                            minimumUtxoVal: cardano.info.minimumUtxoVal,
                            poolDeposit: cardano.info.poolDeposit,
                            keyDeposit: cardano.info.keyDeposit
                        )
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
                        if let slot = slot {
                            transactionBuilder.ttl = UInt32(slot) + maxSlots
                        }
                        do {
                            let _ = try transactionBuilder.addChangeIfNeeded(address: change)
                            cb(.success(transactionBuilder))
                            return
                        } catch {
                            notEnoughUtxos = error
                        }
                    }
                } catch {
                    cb(.failure(error))
                }
                guard let iterator = iterator else {
                    cb(.failure(notEnoughUtxos!))
                    return
                }
                getUtxos(
                    iterator: iterator,
                    to: to,
                    amount: amount,
                    change: change,
                    slot: slot,
                    maxSlots: maxSlots,
                    all: all + utxos,
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
                    maxSlots: UInt32 = 200,
                    _ cb: @escaping ApiCallback<String>) {
        cardano.network.getSlotNumber { res in
            switch res {
            case .success(let slot):
                getUtxos(
                    iterator: cardano.utxos.get(for: from, asset: nil),
                    to: to,
                    amount: amount,
                    change: change,
                    slot: slot,
                    maxSlots: maxSlots,
                    all: []
                ) { res in
                    switch res {
                    case .success(let transactionBuilder):
                        do {
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
            case .failure(let error):
                cb(.failure(error))
            }
        }
    }
}

extension CardanoProtocol {
    public var send: CardanoSendApi { try! getApi() }
}
