//
//  Map.swift
//  
//
//  Created by Yehor Popovych on 14.05.2021.
//

import Foundation

protocol CMap {
    associatedtype Key: Hashable;
    associatedtype Value;
    
    init(keys_ptr: UnsafePointer<Key>!, values_ptr: UnsafePointer<Value>!, len: UInt)
    
    var keys_ptr: UnsafePointer<Key>! { get set }
    var values_ptr: UnsafePointer<Value>! { get set }
    var len: UInt { get }
    
    mutating func free()
}

extension CMap {
    mutating func dictionary() -> [Key: Value] {
        defer { self.free() }
        let tuples = zip(
            UnsafeBufferPointer(start: keys_ptr, count: Int(len)),
            UnsafeBufferPointer(start: values_ptr, count: Int(len))
        )
        return Dictionary(uniqueKeysWithValues: tuples)
    }
}

protocol CMapConvertible: Sequence {
    associatedtype Map: CMap where Element == (key: Map.Key, value: Map.Value)
    
    func withCMap<T>(fn: @escaping (Map) throws -> T) rethrows -> T
}

extension CMapConvertible {
    func withCMap<T>(fn: @escaping (Map) throws -> T) rethrows -> T {
        try withContiguousStorageIfAvailable { storage in
            let keys = storage.map { $0.0 }
            let values = storage.map { $0.1 }
            return try keys.withUnsafeBufferPointer { keys in
                try values.withUnsafeBufferPointer { values in
                    let map = Map(
                        keys_ptr: keys.baseAddress,
                        values_ptr: values.baseAddress,
                        len: UInt(storage.count)
                    )
                    return try fn(map)
                }
            }
        }!
    }
}
