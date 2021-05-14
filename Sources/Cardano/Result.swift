//
//  Result.swift
//  
//
//  Created by Yehor Popovych on 22.02.2021.
//

import Foundation
import CCardano

typealias RustResult<T> = Result<T, CardanoRustError>

extension RustResult {
    static func wrap<S: CType>(
        ccall: @escaping (UnsafeMutablePointer<S>, UnsafeMutablePointer<CError>) -> Bool
    ) -> RustResult<S> {
        var error = CError()
        var val = S()
        if !ccall(&val, &error) {
            return .failure(error.owned())
        }
        return .success(val)
    }
}

protocol CType {
    init()
}

protocol CPtr: CType {
    associatedtype Value
    func copied() -> Value
    mutating func owned() -> Value
    mutating func free()
}

extension CPtr {
    mutating func owned() -> Value {
        defer { self.free() }
        return self.copied()
    }
}

