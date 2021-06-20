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
    func cOption<Option: COption>() -> Option where Option.Value == Wrapped {
        cOption { $0 }
    }
    
    func cOption<Option: COption>(convert: (Wrapped) throws -> Option.Value) rethrows -> Option {
        var option = Option()
        if let value = self {
            option.tag = option.someTag()
            option.some = try convert(value)
        } else {
            option.tag = option.noneTag()
        }
        return option
    }
}
