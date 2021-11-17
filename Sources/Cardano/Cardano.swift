//
//  Cardano.swift
//  
//
//  Created by Yehor Popovych on 2/3/21.
//

import Foundation
#if !COCOAPODS
@_exported import CardanoCore
#endif

public protocol CardanoBootstrapAware {
    func bootstrap(cardano: CardanoProtocol) throws
}

public class Cardano: CardanoProtocol {
    public let info: NetworkApiInfo
    public let addresses: AddressManager
    public let utxos: UtxoProvider
    public let signer: SignatureProvider
    public let network: NetworkProvider
    
    private var apis: Dictionary<String, CardanoApi>
    private let syncQueue: DispatchQueue
    
    public init(info: NetworkApiInfo,
                signer: SignatureProvider,
                network: NetworkProvider,
                addresses: AddressManager = SimpleAddressManager(),
                utxos: UtxoProvider = NonCachingUtxoProvider()) throws {
        let _ = Cardano._initialize
        self.syncQueue = DispatchQueue(label: "Cardano Sync Queue", target: .global())
        self.addresses = addresses
        self.utxos = utxos
        self.signer = signer
        self.network = network
        self.info = info
        self.apis = [:]
        try self.bootstrap(obj: addresses)
        try self.bootstrap(obj: utxos)
    }
    
    public func getApi<A>() throws -> A where A : CardanoApi {
        return try syncQueue.sync {
            if let api = self.apis[A.id] as? A {
                return api
            } else {
                let api = try A(cardano: self)
                self.apis[A.id] = api
                return api
            }
        }
    }
    
    private func bootstrap(obj: Any) throws {
        if let aware = obj as? CardanoBootstrapAware {
            try aware.bootstrap(cardano: self)
        }
    }
    
    private static let _initialize: Void = {
        InitCardanoCore()
    }()
}

