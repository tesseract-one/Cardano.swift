//
//  GeneralTransactionMetadata.swift
//  
//
//  Created by Ostap Danylovych on 25.06.2021.
//

import Foundation
import CCardano

public enum JsonNumber: Equatable {
    case posInt(UInt64)
    case negInt(Int64)
    case float(Float64)

    init(jsonNumber: CCardano.JsonNumber) {
        switch jsonNumber.tag {
        case PosIntKind: self = .posInt(jsonNumber.pos_int_kind)
        case NegIntKind: self = .negInt(jsonNumber.neg_int_kind)
        case FloatKind: self = .float(jsonNumber.float_kind)
        default: fatalError("Unknown JsonNumber type")
        }
    }

    func withCJsonNumber<T>(
        fn: @escaping (CCardano.JsonNumber) throws -> T
    ) rethrows -> T {
        switch self {
        case .posInt(let int):
            var jsonNumber = CCardano.JsonNumber()
            jsonNumber.tag = PosIntKind
            jsonNumber.pos_int_kind = int
            return try fn(jsonNumber)
        case .negInt(let int):
            var jsonNumber = CCardano.JsonNumber()
            jsonNumber.tag = NegIntKind
            jsonNumber.neg_int_kind = int
            return try fn(jsonNumber)
        case .float(let float):
            var jsonNumber = CCardano.JsonNumber()
            jsonNumber.tag = FloatKind
            jsonNumber.float_kind = float
            return try fn(jsonNumber)
        }
    }
}

extension CCardano.JsonNumber: CPtr {
    typealias Val = JsonNumber
    
    func copied() -> JsonNumber {
        JsonNumber(jsonNumber: self)
    }
    
    mutating func free() {}
}

extension CArray_JsonValue: CArray {
    typealias CElement = CCardano.JsonValue

    mutating func free() {}
}

extension Array where Element == JsonValue {
    func withCArray<T>(fn: @escaping (CArray_JsonValue) throws -> T) rethrows -> T {
        try withCArray(with: { try $0.withCJsonValue(fn: $1) }, fn: fn)
    }
}

struct JsonValueMapKeyValue: CKeyValue {
    var key: String
    var val: CCardano.JsonValue

    init(key: String, val: CCardano.JsonValue) {
        self.key = key
        self.val = val
    }
}

extension CCardano.JsonValueMap: CArray {
    typealias CElement = JsonValueMapKeyValue
    
    init(ptr: UnsafePointer<JsonValueMapKeyValue>!, len: UInt) {
        self.init(cptr: UnsafeRawPointer(ptr), len: len)
    }
    
    var ptr: UnsafePointer<JsonValueMapKeyValue>! {
        get { cptr.assumingMemoryBound(to: JsonValueMapKeyValue.self) }
        set { cptr = UnsafeRawPointer(newValue) }
    }

    mutating func free() {
        cardano_json_value_map_free(&self)
    }
}

extension Dictionary where Key == String, Value == JsonValue {
    func withCKVArray<T>(fn: @escaping (CCardano.JsonValueMap) throws -> T) rethrows -> T {
        try withCKVArray(withValue: { try $0.withCJsonValue(fn: $1) }, fn: fn)
    }
}

public enum JsonValue: Equatable {
    case nullKind
    case boolKind(Bool)
    case numberKind(JsonNumber)
    case stringKind(String)
    case arrayKind([JsonValue])
    case objectKind([String: JsonValue])

    init(jsonValue: CCardano.JsonValue) {
        switch jsonValue.tag {
        case NullKind: self = .nullKind
        case BoolKind: self = .boolKind(jsonValue.bool_kind)
        case NumberKind: self = .numberKind(jsonValue.number_kind.copied())
        case StringKind: self = .stringKind(jsonValue.string_kind.copied())
        case ArrayKind: self = .arrayKind(jsonValue.array_kind.copied().map { $0.copied() })
        case ObjectKind:
            let jsonValueMap = jsonValue.object_kind.copiedDictionary().map { key, value in
                (key, value.copied())
            }
            self = .objectKind(Dictionary(uniqueKeysWithValues: jsonValueMap))
        default: fatalError("Unknown JsonValue type")
        }
    }
    
    public init(s: String) throws {
        var jsonValue = try CCardano.JsonValue(s: s)
        self = jsonValue.owned()
    }

    func withCJsonValue<T>(
        fn: @escaping (CCardano.JsonValue) throws -> T
    ) rethrows -> T {
        switch self {
        case .nullKind:
            var jsonValue = CCardano.JsonValue()
            jsonValue.tag = NullKind
            return try fn(jsonValue)
        case .boolKind(let bool):
            var jsonValue = CCardano.JsonValue()
            jsonValue.tag = BoolKind
            jsonValue.bool_kind = bool
            return try fn(jsonValue)
        case .numberKind(let number):
            return try number.withCJsonNumber { number in
                var jsonValue = CCardano.JsonValue()
                jsonValue.tag = NumberKind
                jsonValue.number_kind = number
                return try fn(jsonValue)
            }
        case .stringKind(let string):
            return try string.withCharPtr { string in
                var jsonValue = CCardano.JsonValue()
                jsonValue.tag = StringKind
                jsonValue.string_kind = string
                return try fn(jsonValue)
            }
        case .arrayKind(let array):
            return try array.withCArray { array in
                var jsonValue = CCardano.JsonValue()
                jsonValue.tag = ArrayKind
                jsonValue.array_kind = array
                return try fn(jsonValue)
            }
        case .objectKind(let object):
            return try object.withCKVArray { object in
                var jsonValue = CCardano.JsonValue()
                jsonValue.tag = ObjectKind
                jsonValue.object_kind = object
                return try fn(jsonValue)
            }
        }
    }
}

extension CCardano.JsonValue: CPtr {
    typealias Val = JsonValue
    
    func copied() -> JsonValue {
        JsonValue(jsonValue: self)
    }
    
    mutating func free() {}
}

extension CCardano.JsonValue {
    public init(s: String) throws {
        self = try s.withCharPtr { s in
            RustResult<Self>.wrap { result, error in
                cardano_serde_json_from_str(s, result, error)
            }
        }.get()
    }
    
    public func clone() throws -> Self {
        try RustResult<Self>.wrap { result, error in
            cardano_json_value_clone(self, result, error)
        }.get()
    }
}

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
    case int(UInt64)
    case bytes(Data)
    case text(String)
    
    init(transactionMetadatum: CCardano.TransactionMetadatum) {
        switch transactionMetadatum.tag {
        case MetadataMapKind:
            let metadataMap = transactionMetadatum.metadata_map_kind.copiedDictionary()
                .map { key, value in (key.copied(), value.copied()) }
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
    
    public init(arbitraryBytes: Data) throws {
        var transactionMetadatum = try CCardano.TransactionMetadatum(arbitraryBytes: arbitraryBytes)
        self = transactionMetadatum.owned()
    }
    
    public init(json: String, schema: MetadataJsonSchema) throws {
        var transactionMetadatum = try CCardano.TransactionMetadatum(json: json, schema: schema)
        self = transactionMetadatum.owned()
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
    
    var int: UInt64? {
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
            tm.int_kind = int
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

    mutating func free() {
        cardano_general_transaction_metadata_free(&self)
    }
}

extension GeneralTransactionMetadata {
    func withCKVArray<T>(fn: @escaping (CCardano.GeneralTransactionMetadata) throws -> T) rethrows -> T {
        try withCKVArray(withValue: { try $0.withCTransactionMetadatum(fn: $1) }, fn: fn)
    }
}
