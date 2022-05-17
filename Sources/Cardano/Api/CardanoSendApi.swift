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
        let cardano = self.cardano!
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
                            let config = TransactionBuilderConfig(
                                fee_algo: cardano.info.linearFee,
                                pool_deposit: cardano.info.poolDeposit,
                                key_deposit: cardano.info.keyDeposit,
                                max_value_size: cardano.info.maxValueSize,
                                max_tx_size: cardano.info.maxTxSize,
                                coins_per_utxo_word: cardano.info.coinsPerUtxoWord,
                                prefer_pure_change: false
                            )
                            var transactionBuilder = try TransactionBuilder(config: config)
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
                            cardano.tx.signAndSubmit(tx: transactionBody,
                                                     with: addresses,
                                                     auxiliaryData: nil,
                                                     cb)
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
