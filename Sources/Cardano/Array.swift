//
//  Array.swift
//  
//
//  Created by Yehor Popovych on 13.05.2021.
//

import Foundation

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
    
    mutating func ownedDictionary() -> [CElement.Key: CElement.Value] {
        let tuples = owned().map { $0.tuple }
        return Dictionary(uniqueKeysWithValues: tuples)
    }
}
