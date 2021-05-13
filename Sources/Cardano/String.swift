//
//  String.swift
//  
//
//  Created by Yehor Popovych on 22.02.2021.
//

import Foundation
import CCardano

extension CharPtr {
    func string() -> String {
        defer {
            var out = Optional(self)
            cardano_charptr_free(&out)
        }
        return String(cString: self)
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
