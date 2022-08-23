//
//  GeneralTransactionMetadata.swift
//  
//
//  Created by Ostap Danylovych on 25.06.2021.
//

import Foundation
import CCardano
import BigInt
import OrderedCollections

public enum MetadataJsonSchema {
    case noConversions
    case basicConversions
    case detailedSchema
    
    init(schema: CCardano.MetadataJsonSchema) {
        switch schema {
        case NoConversions: self = .noConversions
        case BasicConversions: self = .basicConversions
        case DetailedSchema: self = .detailedSchema
        default: fatalError("Unknown MetadataJsonSchema type")
        }
    }
    
    func withCMetadataJsonSchema<T>(
        fn: @escaping (CCardano.MetadataJsonSchema) throws -> T
    ) rethrows -> T {
        switch self {
        case .noConversions: return try fn(NoConversions)
        case .basicConversions: return try fn(BasicConversions)
        case .detailedSchema: return try fn(DetailedSchema)
        }
    }
}

public enum TransactionMetadatum: Equatable, Hashable {
    case metadataMap(MetadataMap)
    case metadataList(MetadataList)
    case int(BigInt)
    case bytes(Data)
    case text(String)
    
    init(transactionMetadatum: CCardano.TransactionMetadatum) {
        switch transactionMetadatum.tag {
        case MetadataMapKind:
            let metadataMap = transactionMetadatum.metadata_map_kind.copiedOrderedDictionary()
                .map { key, value in (key.copied(), value.copied()) }
            self = .metadataMap(OrderedDictionary(uniqueKeysWithValues: metadataMap))
        case MetadataListKind:
            self = .metadataList(transactionMetadatum.metadata_list_kind.copied().map {
                $0.copied()
            })
        case IntKind: self = .int(transactionMetadatum.int_kind.bigInt)
        case BytesKind: self = .bytes(transactionMetadatum.bytes_kind.copied())
        case TextKind: self = .text(transactionMetadatum.text_kind.copied())
        default: fatalError("Unknown TransactionMetadatum type")
        }
    }
    
    public init(arbitraryBytes: Data) throws {
        var transactionMetadatum = try CCardano.TransactionMetadatum(arbitraryBytes: arbitraryBytes)
        self = transactionMetadatum.owned()
    }
    
    public init(json: String, schema: MetadataJsonSchema) throws {
        var transactionMetadatum = try CCardano.TransactionMetadatum(json: json, schema: schema)
        self = transactionMetadatum.owned()
    }
    
    public static func newBytes(bytes: Data) throws -> Self {
        var transactionMetadatum = try CCardano.TransactionMetadatum.newBytes(bytes: bytes)
        return transactionMetadatum.owned()
    }
    
    public static func newText(text: String) throws -> Self {
        var transactionMetadatum = try CCardano.TransactionMetadatum.newText(text: text)
        return transactionMetadatum.owned()
    }
    
    var map: MetadataMap? {
        guard case .metadataMap(let map) = self else {
            return nil
        }
        return map
    }
    
    var list: MetadataList? {
        guard case .metadataList(let list) = self else {
            return nil
        }
        return list
    }
    
    var int: BigInt? {
        guard case .int(let int) = self else {
            return nil
        }
        return int
    }
    
    var bytes: Data? {
        guard case .bytes(let bytes) = self else {
            return nil
        }
        return bytes
    }
    
    var text: String? {
        guard case .text(let text) = self else {
            return nil
        }
        return text
    }
    
    public func arbitraryBytes() throws -> Data {
        try withCTransactionMetadatum { try $0.arbitraryBytes() }
    }
    
    public func json(schema: MetadataJsonSchema) throws -> String {
        try withCTransactionMetadatum { try $0.json(schema: schema) }
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
        case .int(let int):
            var tm = CCardano.TransactionMetadatum()
            tm.tag = IntKind
            tm.int_kind = int.cInt128
            return try fn(tm)
        case .bytes(let bytes):
            return try bytes.withCData { bytes in
                var tm = CCardano.TransactionMetadatum()
                tm.tag = BytesKind
                tm.bytes_kind = bytes
                return try fn(tm)
            }
        case .text(let text):
            return try text.withCharPtr { text in
                var tm = CCardano.TransactionMetadatum()
                tm.tag = TextKind
                tm.text_kind = text
                return try fn(tm)
            }
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
    public static func newBytes(bytes: Data) throws -> Self {
        try bytes.withCData { bytes in
            RustResult<Self>.wrap { result, error in
                cardano_transaction_metadatum_new_bytes(bytes, result, error)
            }
        }.get()
    }
    
    public static func newText(text: String) throws -> Self {
        try text.withCharPtr { text in
            RustResult<Self>.wrap { result, error in
                cardano_transaction_metadatum_new_text(text, result, error)
            }
        }.get()
    }
    
    public init(arbitraryBytes: Data) throws {
        self = try arbitraryBytes.withCData { arbitraryBytes in
            RustResult<Self>.wrap { result, error in
                cardano_transaction_metadatum_encode_arbitrary_bytes_as_metadatum(arbitraryBytes, result, error)
            }
        }.get()
    }
    
    public init(json: String, schema: MetadataJsonSchema) throws {
        self = try json.withCharPtr { json in
            schema.withCMetadataJsonSchema { schema in
                RustResult<Self>.wrap { result, error in
                    cardano_transaction_metadatum_encode_json_str_to_metadatum(json, schema, result, error)
                }
            }
        }.get()
    }
    
    public func arbitraryBytes() throws -> Data {
        var data = try RustResult<CData>.wrap { res, err in
            cardano_transaction_metadatum_decode_arbitrary_bytes_from_metadatum(self, res, err)
        }.get()
        return data.owned()
    }
    
    public func json(schema: MetadataJsonSchema) throws -> String {
        var jsonStr = try schema.withCMetadataJsonSchema { schema in
            RustResult<CharPtr>.wrap { res, err in
                cardano_transaction_metadatum_decode_metadatum_to_json_str(self, schema, res, err)
            }
        }.get()
        return jsonStr.owned()
    }
    
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
    typealias Val = [CCardano.GeneralTransactionMetadataKeyValue]

    mutating func free() {
        cardano_general_transaction_metadata_free(&self)
    }
}

extension GeneralTransactionMetadata {
    func withCKVArray<T>(fn: @escaping (CCardano.GeneralTransactionMetadata) throws -> T) rethrows -> T {
        try withCKVArray(withValue: { try $0.withCTransactionMetadatum(fn: $1) }, fn: fn)
    }
}
