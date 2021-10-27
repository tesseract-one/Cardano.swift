//
//  NetworkInfo.swift
//  
//
//  Created by Yehor Popovych on 27.10.2021.
//

import Foundation
#if !COCOAPODS
import CardanoCore
#endif

public struct NetworkId {
    public let id: UInt32
    
    public init(_ id: UInt32) {
        self.id = id
    }
    
    public static let mainnet = Self(0)
}

public struct NetworkInfo {
    public let networkId: NetworkId
    public let linearFee: LinearFee
    public let minimumUtxoVal: UInt64
    public let poolDeposit: UInt64
    public let keyDeposit: UInt64
    
    // TODO: Create mainnet parameters
    // public static let mainnet = Self(...)
}
