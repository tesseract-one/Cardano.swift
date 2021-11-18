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

extension RustResult {
    static func wrap<S: CType>(
        ccall: @escaping (UnsafeMutablePointer<UnsafeMutablePointer<S>?>, UnsafeMutablePointer<CError>) -> Bool
    ) -> RustResult<Optional<S>> {
        var error = CError()
        var val = S()
        return withUnsafeMutablePointer(to: &val) { valPtr in
            var option = Optional(valPtr)
            if !ccall(&option, &error) {
                return .failure(error.owned())
            }
            return .success(option?.pointee)
        }
    }
}

extension RustResult {
    static func wrap(
        ccall: @escaping (UnsafeMutablePointer<CharPtr?>, UnsafeMutablePointer<CError>) -> Bool
    ) -> RustResult<CharPtr?> {
        var error = CError()
        var val: CharPtr? = nil
        if !ccall(&val, &error) {
            return .failure(error.owned())
        }
        return .success(val)
    }
}

extension RustResult {
    static func wrap(
        ccall: @escaping (UnsafeMutablePointer<CError>) -> Bool
    ) -> RustResult<Void> {
        var error = CError()
        if !ccall(&error) {
            return .failure(error.owned())
        }
        return .success(())
    }
}

protocol CType {
    init()
}

protocol CPtr: CType {
    associatedtype Val
    func copied() -> Val
    mutating func owned() -> Val
    mutating func free()
}

extension CPtr {
    mutating func owned() -> Val {
        defer { self.free() }
        return self.copied()
    }
}

extension Int8: CType {}
extension UInt8: CType {}
extension UInt32: CType {}
extension UInt64: CType {}
extension Bool: CType {}
