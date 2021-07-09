//
//  GeneralTransactionMetadata.swift
//  
//
//  Created by Ostap Danylovych on 25.06.2021.
//

import Foundation
import CCardano

public enum TransactionMetadatum: Equatable, Hashable {
    case metadataMap(MetadataMap)
    case metadataList(MetadataList)
    case int(UInt64)
    case bytes(Data)
    case text(String)
    
    init(transactionMetadatum: CCardano.TransactionMetadatum) {
        switch transactionMetadatum.tag {
        case MetadataMapKind:
            let metadataMap = transactionMetadatum.metadata_map_kind
                .copiedDictionary().map { key, value in (key.copied(), value.copied()) }
            self = .metadataMap(Dictionary(uniqueKeysWithValues: metadataMap))
        case MetadataListKind:
            self = .metadataList(transactionMetadatum.metadata_list_kind.copied().map {
                $0.copied()
            })
        case IntKind: self = .int(transactionMetadatum.int_kind)
        case BytesKind: self = .bytes(transactionMetadatum.bytes_kind.copied())
        case TextKind: self = .text(transactionMetadatum.text_kind.copied())
        default: fatalError("Unknown certificate type")
        }
    }
    
    func clonedCTransactionMetadatum() throws -> CCardano.TransactionMetadatum {
        try withCTransactionMetadatum { try $0.clone() }
    }
    
    func withCTransactionMetadatum<T>(
        fn: @escaping (CCardano.TransactionMetadatum) throws -> T
    ) rethrows -> T {
        switch self {
        case .metadataList(let metadataList):
            return try metadataList.withCArray { metadataList in
                var tm = CCardano.TransactionMetadatum()
                tm.tag = MetadataListKind
                tm.metadata_list_kind = metadataList
                return try fn(tm)
            }
        case .metadataMap(let metadataMap):
            return try metadataMap.withCKVArray { metadataMap in
                var tm = CCardano.TransactionMetadatum()
                tm.tag = MetadataMapKind
                tm.metadata_map_kind = metadataMap
                return try fn(tm)
            }
        default: return try fn(CCardano.TransactionMetadatum())
        }
    }
}

extension CCardano.TransactionMetadatum: CPtr {
    typealias Val = TransactionMetadatum
    
    func copied() -> TransactionMetadatum {
        TransactionMetadatum(transactionMetadatum: self)
    }
    
    mutating func free() {
        cardano_transaction_metadatum_free(&self)
    }
}

extension CCardano.TransactionMetadatum {
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_transaction_metadatum_clone(self, result, error)
        }.get()
    }
}

extension CCardano.TransactionMetadatum: Equatable {
    public static func == (
        lhs: CCardano.TransactionMetadatum,
        rhs: CCardano.TransactionMetadatum
    ) -> Bool {
        lhs.copied() == rhs.copied()
    }
}

extension CCardano.TransactionMetadatum: Hashable {
    public func hash(into hasher: inout Hasher) {
        self.copied().hash(into: &hasher)
    }
}

public typealias GeneralTransactionMetadata = Dictionary<TransactionMetadatumLabel, TransactionMetadatum>

extension CCardano.GeneralTransactionMetadataKeyValue: CType {}

extension CCardano.GeneralTransactionMetadataKeyValue: CKeyValue {
    typealias Key = TransactionMetadatumLabel
    typealias Value = CCardano.TransactionMetadatum
}

extension CCardano.GeneralTransactionMetadata: CArray {
    typealias CElement = CCardano.GeneralTransactionMetadataKeyValue

    mutating func free() {
        cardano_general_transaction_metadata_free(&self)
    }
}

extension GeneralTransactionMetadata {
    func withCKVArray<T>(fn: @escaping (CCardano.GeneralTransactionMetadata) throws -> T) rethrows -> T {
        try withContiguousStorageIfAvailable { storage in
            let mapped = storage.map { el in
                el.value.withCTransactionMetadatum { value in
                    CCardano.GeneralTransactionMetadata.CElement((el.key, value))
                }
            }
            return try mapped.withUnsafeBufferPointer {
                try fn(CCardano.GeneralTransactionMetadata(ptr: $0.baseAddress, len: UInt($0.count)))
            }
        }!
    }
}
