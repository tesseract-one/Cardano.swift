//
//  NetworkApiInfo.swift
//  
//
//  Created by Yehor Popovych on 27.10.2021.
//

import Foundation
#if !COCOAPODS
import CardanoCore
#endif

public struct NetworkApiInfo {
    public let networkID: NetworkID
    public let protocolMagic: UInt32
    public let linearFee: LinearFee
    public let minimumUtxoVal: UInt64
    public let poolDeposit: UInt64
    public let keyDeposit: UInt64
    public let maxValueSize: UInt32
    public let maxTxSize: UInt32
    
    public static let shelley = Self(
        networkID: 1,
        protocolMagic: 764824073,
        linearFee: LinearFee(constant: 155381, coefficient: 44),
        minimumUtxoVal: 1000000,
        poolDeposit: 500000000,
        keyDeposit: 2000000,
        maxValueSize: 5000,
        maxTxSize: 16384
    )
    
    public static let alonzo = Self(
        networkID: 0,
        protocolMagic: 1097911063,
        linearFee: LinearFee(constant: 155381, coefficient: 44),
        minimumUtxoVal: 34482,
        poolDeposit: 500000000,
        keyDeposit: 2000000,
        maxValueSize: 5000,
        maxTxSize: 16384
    )
    
    public static let mainnet = shelley
    public static let testnet = alonzo
}
