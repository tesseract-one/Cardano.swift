//
//  UTXO.swift
//  
//
//  Created by Yehor Popovych on 27.10.2021.
//

import Foundation
#if !COCOAPODS
import CardanoCore
#endif

public struct UTXO {
    public let txHash: TransactionHash
    public let index: TransactionIndex
    public let value: Value
}
