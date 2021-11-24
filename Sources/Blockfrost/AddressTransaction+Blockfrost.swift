//
//  AddressTransaction+Blockfrost.swift
//  
//
//  Created by Ostap Danylovych on 30.10.2021.
//

import Foundation
import BlockfrostSwiftSDK
#if !COCOAPODS
import Cardano
#endif

extension AddressTransaction {
    public init(blockfrost addressTransaction: AddressTransactionsContent) {
        self.init(
            txHash: addressTransaction.txHash,
            txIndex: addressTransaction.txIndex,
            blockHeight: addressTransaction.blockHeight
        )
    }
}
