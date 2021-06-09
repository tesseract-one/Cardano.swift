//
//  TransactionInput.swift
//  
//
//  Created by Ostap Danylovych on 09.06.2021.
//

import Foundation
import CCardano

public typealias TransactionInput = CCardano.TransactionInput

extension TransactionInput: CType {}

extension TransactionInput {
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { result, error in
                cardano_transaction_input_from_bytes(bytes, result, error)
            }
        }.get()
    }
    
    public func bytes() throws -> Data {
        var bytes = try RustResult<Self>.wrap { result, error in
            cardano_transaction_input_to_bytes(self, result, error)
        }.get()
        return bytes.owned()
    }
}
