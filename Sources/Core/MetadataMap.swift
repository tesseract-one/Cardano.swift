//
//  MetadataMap.swift
//  
//
//  Created by Ostap Danylovych on 28.06.2021.
//

import Foundation
import CCardano
import BigInt
import OrderedCollections

public typealias MetadataMap = OrderedDictionary<TransactionMetadatum, TransactionMetadatum>

extension MetadataMapKeyValue: CType {}

extension MetadataMapKeyValue: CKeyValue {
    typealias Key = CCardano.TransactionMetadatum
    typealias Value = CCardano.TransactionMetadatum
}

extension CCardano.MetadataMap: CArray {
    typealias CElement = MetadataMapKeyValue
    typealias Val = [MetadataMapKeyValue]
    
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
        try withCKVArray(
            withKey: { try $0.withCTransactionMetadatum(fn: $1) },
            withValue: { try $0.withCTransactionMetadatum(fn: $1) },
            fn: fn
        )
    }
    
    public func getStr(key: String) throws -> TransactionMetadatum? {
        self[try TransactionMetadatum.newText(text: key)]
    }
    
    public func getI32(key: Int32) -> TransactionMetadatum? {
        self[TransactionMetadatum.int(BigInt(key))]
    }
}
