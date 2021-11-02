//
//  CardanoApi.swift
//  
//
//  Created by Yehor Popovych on 27.10.2021.
//

import Foundation

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
    var info: NetworkApiInfo { get }
    var addresses: AddressManager { get }
    var utxos: UtxoProvider { get }
    var signer: SignatureProvider { get }
    var network: NetworkProvider { get }
    
    func getApi<A: CardanoApi>() throws -> A
}
