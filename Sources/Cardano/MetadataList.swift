//
//  MetadataList.swift
//  
//
//  Created by Ostap Danylovych on 28.06.2021.
//

import Foundation
import CCardano

public typealias MetadataList = Array<TransactionMetadatum>

extension CCardano.MetadataList: CArray {
    typealias CElement = CCardano.TransactionMetadatum

    mutating func free() {
        cardano_metadata_list_free(&self)
    }
}

extension MetadataList {
    func withCArray<T>(fn: @escaping (CCardano.MetadataList) throws -> T) rethrows -> T {
        try withContiguousStorageIfAvailable { storage in
            let mapped = storage.map { $0.withCTransactionMetadatum { $0 } }
            return try mapped.withUnsafeBufferPointer {
                try fn(CCardano.MetadataList(ptr: $0.baseAddress, len: UInt($0.count)))
            }
        }!
    }
}
