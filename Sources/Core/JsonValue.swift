//
//  JsonValue.swift
//  
//
//  Created by Ostap Danylovych on 17.08.2021.
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
    typealias Val = [CCardano.JsonValue]

    mutating func free() {}
}

extension Array where Element == JsonValue {
    func withCArray<T>(fn: @escaping (CArray_JsonValue) throws -> T) rethrows -> T {
        try withCArray(with: { try $0.withCJsonValue(fn: $1) }, fn: fn)
    }
}

extension WrappedCharPtr: Equatable {
    public static func == (lhs: WrappedCharPtr, rhs: WrappedCharPtr) -> Bool {
        lhs._0.copied() == rhs._0.copied()
    }
}

extension WrappedCharPtr: Hashable {
    public func hash(into hasher: inout Hasher) {
        self._0.copied().hash(into: &hasher)
    }
}

extension JsonValueMapKeyValue: CKeyValue {
    typealias Key = WrappedCharPtr
    typealias Value = CCardano.JsonValue
}

extension CCardano.JsonValueMap: CArray {
    typealias CElement = JsonValueMapKeyValue
    typealias Val = [JsonValueMapKeyValue]
    
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
        try withCKVArray(
            withKey: { key, fn in
                try key.withCharPtr { try fn(WrappedCharPtr(_0: $0)) }
            },
            withValue: { try $0.withCJsonValue(fn: $1) },
            fn: fn
        )
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
                (key._0.copied(), value.copied())
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
