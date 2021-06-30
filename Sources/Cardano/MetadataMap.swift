//
//  MetadataMap.swift
//  
//
//  Created by Ostap Danylovych on 28.06.2021.
//

import Foundation
import CCardano

public typealias MetadataMap = Dictionary<TransactionMetadatum, TransactionMetadatum>

public typealias PTransactionMetadatum = CCardano.CPointer_TransactionMetadatum

extension PTransactionMetadatum: CPointer {
    typealias Val = CCardano.TransactionMetadatum
    
    mutating func free() {}
}

extension PTransactionMetadatum: Equatable {
    public static func == (lhs: PTransactionMetadatum, rhs: PTransactionMetadatum) -> Bool {
        lhs.copied().copied() == lhs.copied().copied()
    }
}

extension PTransactionMetadatum: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(copied().copied())
    }
}

extension CCardano.MetadataMapKeyValue: CType {}

extension CCardano.MetadataMapKeyValue: CKeyValue {
    typealias Key = PTransactionMetadatum
    typealias Value = PTransactionMetadatum
}

extension CCardano.MetadataMap: CArray {
    typealias CElement = CCardano.MetadataMapKeyValue

    mutating func free() {
        cardano_metadata_map_free(&self)
    }
}

extension MetadataMap {
    func withCKVArray<T>(fn: @escaping (CCardano.MetadataMap) throws -> T) rethrows -> T {
        try withContiguousStorageIfAvailable { storage in
            let mapped = storage.map {
                CCardano.MetadataMap.CElement((
                    PTransactionMetadatum(from: $0.key.withCTransactionMetadatum { $0 }),
                    PTransactionMetadatum(from: $0.value.withCTransactionMetadatum { $0 })
                ))
            }
            return try mapped.withUnsafeBufferPointer {
                try fn(CCardano.MetadataMap(ptr: $0.baseAddress, len: UInt($0.count)))
            }
        }!
    }
}
