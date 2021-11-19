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
                    lovelace amount: UInt64,
                    from: Account,
                    change: Address? = nil,
                    _ cb: @escaping ApiCallback<TransactionHash>) {
        let addresses: [Address]
        let changeAddress: Address
        do {
            addresses = try cardano.addresses.get(cached: from)
            changeAddress = try change ?? cardano.addresses.new(for: from, change: true)
        } catch {
            cb(.failure(error))
            return
        }
        ada(to: to, lovelace: amount, from: addresses, change: changeAddress, cb)
    }
    
    private func getAllUtxos(iterator: UtxoProviderAsyncIterator,
                             all: [TransactionUnspentOutput],
                             _ cb: @escaping (Result<[TransactionUnspentOutput], Error>) -> Void) {
        iterator.next { (res, iterator) in
            switch res {
            case .success(let utxos):
                guard let iterator = iterator else {
                    cb(.success(all + utxos))
                    return
                }
                getAllUtxos(iterator: iterator, all: all + utxos, cb)
            case .failure(let error):
                cb(.failure(error))
            }
        }
    }
    
    public func ada(to: Address,
                    lovelace amount: UInt64,
                    from: [Address],
                    change: Address,
                    maxSlots: UInt32 = 300,
                    _ cb: @escaping ApiCallback<TransactionHash>) {
        cardano.network.getSlotNumber { res in
            switch res {
            case .success(let slot):
                getAllUtxos(
                    iterator: cardano.utxos.get(for: from, asset: nil),
                    all: []
                ) { res in
                    switch res {
                    case .success(let utxos):
                        do {
                            var transactionBuilder = try TransactionBuilder(
                                linearFee: cardano.info.linearFee,
                                poolDeposit: cardano.info.poolDeposit,
                                keyDeposit: cardano.info.keyDeposit,
                                maxValueSize: cardano.info.maxValueSize,
                                maxTxSize: cardano.info.maxTxSize,
                                coinsPerUtxoWord: cardano.info.coinsPerUtxoWord
                            )
                            try transactionBuilder.addOutput(
                                output: TransactionOutput(address: to, amount: Value(coin: amount))
                            )
                            if let slot = slot {
                                transactionBuilder.ttl = UInt32(slot) + maxSlots
                            }
                            try transactionBuilder.addInputsFrom(inputs: utxos,
                                                                 strategy: .largestFirst)
                            let addresses = transactionBuilder.inputs.map { input in
                                utxos.first { utxo in
                                    utxo.input == input.input
                                    && utxo.output.amount == input.amount
                                }!.output.address
                            }
                            let _ = try transactionBuilder.addChangeIfNeeded(address: change)
                            let transactionBody = try transactionBuilder.build()
                            let extendedTransaction = ExtendedTransaction(
                                tx: transactionBody,
                                addresses: try cardano.addresses.extended(addresses: addresses),
                                auxiliaryData: nil
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
