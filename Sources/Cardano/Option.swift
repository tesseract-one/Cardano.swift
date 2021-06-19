//
//  Option.swift
//  
//
//  Created by Ostap Danylovych on 16.06.2021.
//

import Foundation

protocol COption {
    associatedtype Tag: Equatable
    associatedtype Value: CType
    
    var tag: Tag { get set }
    var some: Value { get set }
    
    init()
    
    func someTag() -> Tag
    func noneTag() -> Tag
}

extension COption {
    func get() -> Value? {
        tag == someTag() ? some : nil
    }
}

extension Optional {
    func cOption<O: COption>() -> O where O.Value == Wrapped {
        var option = O()
        if let value = self {
            option.tag = option.someTag()
            option.some = value
            return option
        } else {
            option.tag = option.noneTag()
            return option
        }
    }
    
    func withCOption<O: COption, T>(with: (Wrapped, @escaping (O.Value) throws -> T) throws -> T, fn: @escaping (O) throws -> T) rethrows -> T {
        var option = O()
        if let value = self {
            return try with(value) { value in
                option.tag = option.someTag()
                option.some = value
                return try fn(option)
            }
        } else {
            option.tag = option.noneTag()
            return try fn(option)
        }
    }
}
