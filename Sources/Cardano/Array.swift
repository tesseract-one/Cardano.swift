//
//  Array.swift
//  
//
//  Created by Yehor Popovych on 13.05.2021.
//

import Foundation

protocol CArray {
    associatedtype Value;
    
    init(ptr: UnsafePointer<Value>!, len: UInt)
    
    var ptr: UnsafePointer<Value>! { get set }
    var len: UInt { get }
    
    mutating func free()
}

extension CArray {
    mutating func array() -> [Value] {
        defer { self.free() }
        return Array(UnsafeBufferPointer(start: ptr, count: Int(len)))
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

extension CArray where Value: CKeyValue {
    mutating func dictionary() -> [Value.Key: Value.Value] {
        defer { self.free() }
        let tuples = UnsafeBufferPointer(start: ptr, count: Int(len))
            .map { $0.tuple }
        return Dictionary(uniqueKeysWithValues: tuples)
    }
}

protocol CArrayConvertible: Sequence {
    associatedtype Arr: CArray where Self.Arr.Value == Self.Element
    
    func withCArray<T>(fn: @escaping (Arr) throws -> T) rethrows -> T
}

extension CArrayConvertible {
    func withCArray<T>(fn: @escaping (Arr) throws -> T) rethrows -> T {
        try withContiguousStorageIfAvailable { storage in
            try fn(Arr(ptr: storage.baseAddress, len: UInt(storage.count)))
        }!
    }
}

protocol CKeyValueArrayConvertible: Sequence {
    associatedtype Arr: CArray where
        Arr.Value: CKeyValue,
        Element == (key: Arr.Value.Key, value: Arr.Value.Value)
    
    func withCKVArray<T>(fn: @escaping (Arr) throws -> T) rethrows -> T
}

extension CKeyValueArrayConvertible {
    func withCKVArray<T>(fn: @escaping (Arr) throws -> T) rethrows -> T {
        try withContiguousStorageIfAvailable { storage in
            let mapped = storage.map { Arr.Value($0) }
            return try fn(Arr(ptr: mapped, len: UInt(mapped.count)))
        }!
    }
}
