//
//  Cardano+Blockfrost.swift
//  
//
//  Created by Yehor Popovych on 17.11.2021.
//

import Foundation
import BlockfrostSwiftSDK
#if !COCOAPODS
import Cardano
#endif

public extension Cardano {
    convenience init(blockfrost id: String,
                     info: NetworkApiInfo,
                     signer: SignatureProvider,
                     addresses: AddressManager = SimpleAddressManager(),
                     utxos: UtxoProvider = NonCachingUtxoProvider(),
                     responseQueue: DispatchQueue = .main) throws
    {
        let config = try info.blockfrostConfig()
        config.apiResponseQueue = responseQueue
        config.projectId = id
        try self.init(blockfrost: config,
                      info: info,
                      signer: signer,
                      addresses: addresses,
                      utxos: utxos)
    }
    
    convenience init(blockfrost config: BlockfrostConfig,
                     info: NetworkApiInfo,
                     signer: SignatureProvider,
                     addresses: AddressManager = SimpleAddressManager(),
                     utxos: UtxoProvider = NonCachingUtxoProvider()) throws
    {
        let network = BlockfrostNetworkProvider(config: config)
        // TODO: Remove this when BlockFrost will fix their bug
        BlockfrostConfig.shared().projectId = config.projectId
        try self.init(info: info,
                      signer: signer,
                      network: network,
                      addresses: addresses,
                      utxos: utxos)
    }
}
