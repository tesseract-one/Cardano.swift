//
//  Array.swift
//  
//
//  Created by Yehor Popovych on 13.05.2021.
//

import Foundation
import OrderedCollections

protocol CArray: CPtr where Val == [CElement] {
    associatedtype CElement
    
    init(ptr: UnsafePointer<CElement>!, len: UInt)
    
    var ptr: UnsafePointer<CElement>! { get set }
    var len: UInt { get }
}

extension CArray {
    func copied() -> Val {
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
    
    func copiedOrderedDictionary() -> OrderedDictionary<CElement.Key, CElement.Value> {
        let tuples = copied().map { $0.tuple }
        return OrderedDictionary(uniqueKeysWithValues: tuples)
    }
    
    mutating func ownedDictionary() -> [CElement.Key: CElement.Value] {
        let tuples = owned().map { $0.tuple }
        return Dictionary(uniqueKeysWithValues: tuples)
    }
}

extension Array {
    private func withCElement<A: CArray, T>(
        index: Int,
        ar: [A.CElement],
        with: @escaping (Element, @escaping (A.CElement) throws -> T) throws -> T,
        fn: @escaping (A) throws -> T
    ) rethrows -> T {
        if index < count {
            var ar = ar
            return try with(self[index]) {
                ar.append($0)
                return try withCElement(index: index + 1, ar: ar, with: with, fn: fn)
            }
        } else {
            return try ar.withCArr(fn: fn)
        }
    }
    
    func withCArr<A: CArray, T>(fn: @escaping (A) throws -> T) rethrows -> T where A.CElement == Element {
        try withContiguousStorageIfAvailable {
            try fn(A(ptr: $0.baseAddress, len: UInt($0.count)))
        }!
    }
    
    func withCArray<A: CArray, T>(
        with: @escaping (Element, @escaping (A.CElement) throws -> T) throws -> T,
        fn: @escaping (A) throws -> T
    ) rethrows -> T {
        var ar = [A.CElement]()
        ar.reserveCapacity(count)
        return try withCElement(index: 0, ar: ar, with: with, fn: fn)
    }
}

protocol WithCKVArray: Sequence where Element == (key: Key, value: Value) {
    associatedtype Key: Hashable
    associatedtype Value
    
    func withCKVArr<A: CArray, T>(fn: @escaping (A) throws -> T) rethrows -> T
    where
        A.CElement: CKeyValue,
        Key == A.CElement.Key,
        Value == A.CElement.Value
    
    func withCKVArray<A: CArray, T>(
        withKey: @escaping (Key, @escaping (A.CElement.Key) throws -> T) throws -> T,
        fn: @escaping (A) throws -> T
    ) rethrows -> T where A.CElement: CKeyValue, Value == A.CElement.Value
    
    func withCKVArray<A: CArray, T>(
        withValue: @escaping (Value, @escaping (A.CElement.Value) throws -> T) throws -> T,
        fn: @escaping (A) throws -> T
    ) rethrows -> T where A.CElement: CKeyValue, Key == A.CElement.Key
    
    func withCKVArray<A: CArray, T>(
        withKey: @escaping (Key, @escaping (A.CElement.Key) throws -> T) throws -> T,
        withValue: @escaping (Value, @escaping (A.CElement.Value) throws -> T) throws -> T,
        fn: @escaping (A) throws -> T
    ) rethrows -> T where A.CElement: CKeyValue
}

extension WithCKVArray {
    func withCKVArr<A: CArray, T>(fn: @escaping (A) throws -> T) rethrows -> T
    where
        A.CElement: CKeyValue,
        Key == A.CElement.Key,
        Value == A.CElement.Value
    {
        try Array(self).withContiguousStorageIfAvailable { storage in
            let mapped = storage.map { A.CElement($0) }
            return try mapped.withUnsafeBufferPointer {
                try fn(A(ptr: $0.baseAddress, len: UInt($0.count)))
            }
        }!
    }
    
    func withCKVArray<A: CArray, T>(
        withKey: @escaping (Key, @escaping (A.CElement.Key) throws -> T) throws -> T,
        fn: @escaping (A) throws -> T
    ) rethrows -> T where A.CElement: CKeyValue, Value == A.CElement.Value {
        try Array(self).withCArray(
            with: { el, fn in
                try withKey(el.key) { try fn(A.CElement(($0, el.value))) }
            },
            fn: fn
        )
    }
    
    func withCKVArray<A: CArray, T>(
        withValue: @escaping (Value, @escaping (A.CElement.Value) throws -> T) throws -> T,
        fn: @escaping (A) throws -> T
    ) rethrows -> T where A.CElement: CKeyValue, Key == A.CElement.Key {
        try Array(self).withCArray(
            with: { el, fn in
                try withValue(el.value) { try fn(A.CElement((el.key, $0))) }
            },
            fn: fn
        )
    }
    
    func withCKVArray<A: CArray, T>(
        withKey: @escaping (Key, @escaping (A.CElement.Key) throws -> T) throws -> T,
        withValue: @escaping (Value, @escaping (A.CElement.Value) throws -> T) throws -> T,
        fn: @escaping (A) throws -> T
    ) rethrows -> T where A.CElement: CKeyValue {
        try Array(self).withCArray(
            with: { el, fn in
                try withKey(el.key) { key in
                    try withValue(el.value) { value in
                        try fn(A.CElement((key, value)))
                    }
                }
            },
            fn: fn
        )
    }
}

extension Dictionary: WithCKVArray {}
extension OrderedDictionary: WithCKVArray {}
