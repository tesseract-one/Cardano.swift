//
//  MetadataMap.swift
//  
//
//  Created by Ostap Danylovych on 28.06.2021.
//

import Foundation
import CCardano

public typealias MetadataMap = Dictionary<TransactionMetadatum, TransactionMetadatum>

extension MetadataMapKeyValue: CType {}

extension MetadataMapKeyValue: CKeyValue {
    typealias Key = CCardano.TransactionMetadatum
    typealias Value = CCardano.TransactionMetadatum
}

extension CCardano.MetadataMap: CArray {
    typealias CElement = MetadataMapKeyValue
    
    init(ptr: UnsafePointer<MetadataMapKeyValue>!, len: UInt) {
        self.init(cptr: UnsafeRawPointer(ptr), len: len)
    }
    
    var ptr: UnsafePointer<MetadataMapKeyValue>! {
        get { cptr.assumingMemoryBound(to: MetadataMapKeyValue.self) }
        set { cptr = UnsafeRawPointer(newValue) }
    }

    mutating func free() {
        cardano_metadata_map_free(&self)
    }
}

extension MetadataMap {
    func withCKVArray<T>(fn: @escaping (CCardano.MetadataMap) throws -> T) rethrows -> T {
        try withContiguousStorageIfAvailable { storage in
            let mapped = storage.map {
                CCardano.MetadataMap.CElement(
                    key: $0.key.withCTransactionMetadatum { $0 },
                    val: $0.value.withCTransactionMetadatum { $0 }
                )
            }
            return try mapped.withUnsafeBufferPointer {
                try fn(CCardano.MetadataMap(ptr: $0.baseAddress, len: UInt($0.count)))
            }
        }!
    }
}
