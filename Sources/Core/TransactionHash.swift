//
//  TransactionHash.swift
//  
//
//  Created by Ostap Danylovych on 09.06.2021.
//

import Foundation
import CCardano

public typealias TransactionIndex = CCardano.TransactionIndex

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
        self = try txBody.withCTransactionBody { txBody in
            RustResult<Self>.wrap { res, err in
                cardano_transaction_hash_hash_transaction(txBody, res, err)
            }
        }.get()
    }
    
    public func bytes() throws -> Data {
        var bytes = try RustResult<CData>.wrap { result, error in
            cardano_transaction_hash_to_bytes(self, result, error)
        }.get()
        return bytes.owned()
    }
    
    public var bytesArray: [UInt8] {
        withUnsafeBytes(of: bytes) { ptr in
            Array(ptr.bindMemory(to: UInt8.self).prefix(32))
        }
    }
}

extension TransactionHash: Equatable {
    public static func == (lhs: TransactionHash, rhs: TransactionHash) -> Bool {
        lhs.bytesArray == rhs.bytesArray
    }
}

extension TransactionHash: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(bytesArray)
    }
}
