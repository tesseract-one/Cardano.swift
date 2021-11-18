//
//  NetworkApiInfo+Blockfrost.swift
//  
//
//  Created by Yehor Popovych on 17.11.2021.
//

import Foundation
import BlockfrostSwiftSDK
#if !COCOAPODS
import Cardano
#endif

public enum BlockfrostNetworkInfoError: Error {
    case unknownNetworkID(UInt8)
}

public extension NetworkApiInfo {
    func blockfrostConfig() throws -> BlockfrostConfig {
        switch self {
        case .mainnet:
            return BlockfrostConfig.mainnetDefault().clone()
        case .testnet:
            return BlockfrostConfig.testnetDefault().clone()
        default:
            throw BlockfrostNetworkInfoError.unknownNetworkID(self.networkID)
        }
    }
}
