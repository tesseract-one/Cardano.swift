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

public struct NetworkApiInfo: Equatable, Hashable {
    public let networkID: NetworkID
    public let protocolMagic: UInt32
    public let linearFee: LinearFee
    public let poolDeposit: UInt64
    public let keyDeposit: UInt64
    public let maxValueSize: UInt32
    public let maxTxSize: UInt32
    public let coinsPerUtxoWord: UInt64
    
    public static let shelley = Self(
        networkID: 1,
        protocolMagic: 764824073,
        linearFee: LinearFee(constant: 155381, coefficient: 44),
        poolDeposit: 500000000,
        keyDeposit: 2000000,
        maxValueSize: 5000,
        maxTxSize: 16384,
        coinsPerUtxoWord: 34482
    )
    
    public static let alonzo = Self(
        networkID: 0,
        protocolMagic: 1097911063,
        linearFee: LinearFee(constant: 155381, coefficient: 44),
        poolDeposit: 500000000,
        keyDeposit: 2000000,
        maxValueSize: 5000,
        maxTxSize: 16384,
        coinsPerUtxoWord: 34482
    )
    
    public static let mainnet = shelley
    public static let testnet = alonzo
}
