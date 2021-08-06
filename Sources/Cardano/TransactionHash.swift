//
//  TransactionHash.swift
//  
//
//  Created by Ostap Danylovych on 09.06.2021.
//

import Foundation
import CCardano

public typealias TransactionHash = CCardano.TransactionHash

extension TransactionHash: CType {}

extension TransactionHash {
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { result, error in
                cardano_transaction_hash_from_bytes(bytes, result, error)
            }
        }.get()
    }
    
    public init(txBody: TransactionBody) throws {
        fatalError()
    }
    
    public func bytes() throws -> Data {
        var bytes = try RustResult<CData>.wrap { result, error in
            cardano_transaction_hash_to_bytes(self, result, error)
        }.get()
        return bytes.owned()
    }
}
