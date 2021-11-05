//
//  ChainTransaction+Blockfrost.swift
//  
//
//  Created by Ostap Danylovych on 05.11.2021.
//

import Foundation
import BlockfrostSwiftSDK
#if !COCOAPODS
import Cardano
#endif

extension ChainTransaction {
    public init(blockfrost transaction: TxContent) {
        self.init(
            hash: transaction.hash,
            block: transaction.block,
            blockHeight: transaction.blockHeight,
            slot: transaction.slot,
            index: transaction.index,
            outputAmount: transaction.outputAmount.map {
                ChainTransactionAmount(unit: $0.unit, quantity: $0.quantity)
            },
            fees: transaction.fees,
            deposit: transaction.deposit,
            size: transaction.size,
            invalidBefore: transaction.invalidBefore,
            invalidHereafter: transaction.invalidHereafter,
            utxoCount: transaction.utxoCount,
            withdrawalCount: transaction.withdrawalCount,
            mirCertCount: transaction.mirCertCount,
            delegationCount: transaction.delegationCount,
            stakeCertCount: transaction.stakeCertCount,
            poolUpdateCount: transaction.poolUpdateCount,
            poolRetireCount: transaction.poolRetireCount,
            assetMintOrBurnCount: transaction.assetMintOrBurnCount,
            redeemerCount: transaction.redeemerCount
        )
    }
}
