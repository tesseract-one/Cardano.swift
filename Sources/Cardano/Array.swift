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
