//
//  CardanoProtocol.swift
//  
//
//  Created by Yehor Popovych on 27.10.2021.
//

import Foundation
#if !COCOAPODS
import CardanoCore
#endif

public protocol AddressManager {
    func accounts(_ cb: @escaping (Result<[Account], Error>) -> Void)
    
    func new(for account: Account, change: Bool) -> Address
    
    func get(for account: Account,
             forceUpdate: Bool,
             _ cb: @escaping (Result<[Address], Error>) -> Void)
    
    func fetch(for accounts: [Account],
               _ cb: @escaping (Result<Void, Error>) -> Void)
    
    func extended(addresses: [Address]) throws -> [ExtendedAddress]
}

public extension AddressManager {
    func get(for account: Account,
             _ cb: @escaping (Result<[Address], Error>) -> Void) {
        self.get(for: account, forceUpdate: false, cb)
    }
}

public protocol UtxoProviderAsyncIterator {
    func next(_ cb: @escaping (Result<[UTXO], Error>, Self?) -> Void)
    func next(limit: Int, _ cb: @escaping (Result<[UTXO], Error>, Self?) -> Void)
}

public protocol UtxoProvider {
    func get(for addresses: [Address],
             asset: (PolicyID, AssetName)?) -> UtxoProviderAsyncIterator
    
    func get(id: (tx: TransactionHash, index: TransactionIndex),
             _ cb: @escaping (Result<[UTXO], Error>) -> Void)
}

public protocol CardanoBootstrapAware {
    func bootstrap(cardano: CardanoProtocol) throws
}

public typealias ApiResult<T> = Result<T, Error>
public typealias ApiCallback<T> = (ApiResult<T>) -> Void

public protocol CardanoApi {
    init(cardano: CardanoProtocol) throws
    static var id: String { get }
}

public extension CardanoApi {
    static var id: String { String(describing: self) }
}

public protocol CardanoProtocol: AnyObject {
    var addresses: AddressManager { get }
    var utxos: UtxoProvider { get }
    var signer: SignatureProvider { get }
    var network: NetworkProvider { get }
    
    func getApi<A: CardanoApi>() throws -> A
}
