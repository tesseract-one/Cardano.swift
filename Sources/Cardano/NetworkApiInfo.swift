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
    public let linearFee: LinearFee
    public let minimumUtxoVal: UInt64
    public let poolDeposit: UInt64
    public let keyDeposit: UInt64
    
    // TODO: Create mainnet parameters
    // public static let mainnet = Self(...)
}
