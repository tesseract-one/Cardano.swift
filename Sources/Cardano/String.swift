//
//  String.swift
//  
//
//  Created by Yehor Popovych on 22.02.2021.
//

import Foundation
import CCardano

extension Optional: CType where Wrapped == CharPtr {
    init() {
        self = nil
    }
}

extension Optional: CPtr where Wrapped == CharPtr {
    typealias Value = String
    
    func copied() -> Value { String(cString: self!) }
    
    mutating func free() {
        cardano_charptr_free(&self)
    }
}

extension String {
    func withCharPtr<T>(fn: @escaping (CharPtr) throws -> T) rethrows -> T {
        try withCString(fn)
    }
}

extension Optional where Wrapped == String {
    func withCharPtr<T>(fn: @escaping (Optional<CharPtr>) throws -> T) rethrows -> T {
        if let str = self {
            return try str.withCharPtr(fn: fn)
        } else {
            return try fn(nil)
        }
    }
}
