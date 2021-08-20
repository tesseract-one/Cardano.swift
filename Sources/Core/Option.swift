//
//  Option.swift
//  
//
//  Created by Ostap Danylovych on 16.06.2021.
//

import Foundation

protocol COption {
    associatedtype Tag: Equatable
    associatedtype Value
    
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
    func cOption<Option: COption>() -> Option where Option.Value == Wrapped {
        var option = Option()
        if let value = self {
            option.tag = option.someTag()
            option.some = value
        } else {
            option.tag = option.noneTag()
        }
        return option
    }
    
    func withCOption<Option: COption, T>(
        with: (Wrapped, @escaping (Option.Value) throws -> T) throws -> T,
        fn: @escaping (Option) throws -> T
    ) rethrows -> T {
        var option = Option()
        if let value = self {
            return try with(value) {
                option.tag = option.someTag()
                option.some = $0
                return try fn(option)
            }
        } else {
            option.tag = option.noneTag()
            return try fn(option)
        }
    }
}
