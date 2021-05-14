//
//  NetworkInfo.swift
//  
//
//  Created by Yehor Popovych on 23.02.2021.
//

import Foundation
import CCardano

public typealias NetworkInfo = CCardano.NetworkInfo

extension NetworkInfo: CType {}

extension NetworkInfo {
    public static let mainnet: NetworkInfo = {
       cardano_network_info_mainnet()
    }()
    
    public static let testnet: NetworkInfo = {
       cardano_network_info_testnet()
    }()
}
