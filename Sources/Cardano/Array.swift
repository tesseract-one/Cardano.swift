//
//  Array.swift
//  
//
//  Created by Yehor Popovych on 13.05.2021.
//

import Foundation

protocol CArray: CPtr where Value == [CElement] {
    associatedtype CElement: CType
    
    init(ptr: UnsafePointer<CElement>!, len: UInt)
    
    var ptr: UnsafePointer<CElement>! { get set }
    var len: UInt { get }
}

extension CArray {
    func copied() -> Value {
        Array(UnsafeBufferPointer(start: ptr, count: Int(len)))
    }
}

protocol CKeyValue {
    associatedtype Key: Hashable
    associatedtype Value
    
    var key: Key { get set }
    var val: Value { get set }
    
    init(key: Key, val: Value)
}

extension CKeyValue {
    init(_ tuple: (Key, Value)) {
        self.init(key: tuple.0, val: tuple.1)
    }
    var tuple: (Key, Value) { (key, val) }
}

extension CArray where CElement: CKeyValue {
    func copiedDictionary() -> [CElement.Key: CElement.Value] {
        let tuples = copied().map { $0.tuple }
        return Dictionary(uniqueKeysWithValues: tuples)
    }
    
    mutating func ownedDictionary() -> [CElement.Key: CElement.Value] {
        let tuples = owned().map { $0.tuple }
        return Dictionary(uniqueKeysWithValues: tuples)
    }
}

protocol CArrayConvertible: Sequence {
    associatedtype Array: CArray where Array.CElement == Element
    
    func withCArray<T>(fn: @escaping (Array) throws -> T) rethrows -> T
}

extension CArrayConvertible {
    func withCArray<T>(fn: @escaping (Array) throws -> T) rethrows -> T {
        try withContiguousStorageIfAvailable { storage in
            try fn(Array(ptr: storage.baseAddress, len: UInt(storage.count)))
        }!
    }
}

protocol CKeyValueArrayConvertible: Sequence {
    associatedtype Array: CArray where
        Array.CElement: CKeyValue,
        Element == (key: Array.CElement.Key, value: Array.CElement.Value)
    
    func withCKVArray<T>(fn: @escaping (Array) throws -> T) rethrows -> T
}

extension CKeyValueArrayConvertible {
    func withCKVArray<T>(fn: @escaping (Array) throws -> T) rethrows -> T {
        try withContiguousStorageIfAvailable { storage in
            let mapped = storage.map { Array.CElement($0) }
            return try fn(Array(ptr: mapped, len: UInt(mapped.count)))
        }!
    }
}
