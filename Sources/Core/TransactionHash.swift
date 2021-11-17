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
    
    public init(hex: String) throws {
        guard let data = Data(hex: hex) else {
            throw CardanoRustError.deserialization(message: "bad hex string")
        }
        try self.init(bytes: data)
    }
    
    public func bytes() throws -> Data {
        var bytes = try RustResult<CData>.wrap { result, error in
            cardano_transaction_hash_to_bytes(self, result, error)
        }.get()
        return bytes.owned()
    }
    
    public var hash: [UInt8] {
        withUnsafeBytes(of: _0) { ptr in
            Array(ptr.bindMemory(to: UInt8.self).prefix(32))
        }
    }
    
    public var hex: String {
        Data(hash).hex(prefix: false)
    }
}

extension TransactionHash: Equatable {
    public static func == (lhs: TransactionHash, rhs: TransactionHash) -> Bool {
        lhs.hash == rhs.hash
    }
}

extension TransactionHash: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(hash)
    }
}
