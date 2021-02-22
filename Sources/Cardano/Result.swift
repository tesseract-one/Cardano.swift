//
//  Result.swift
//  
//
//  Created by Yehor Popovych on 22.02.2021.
//

import Foundation
import CCardano

public typealias RustResult<T> = Result<T, CardanoRustError>

extension RustResult {
    public static func wrap<S>(
        ccall: @escaping (UnsafeMutablePointer<S>, UnsafeMutablePointer<CError>) -> Bool
    ) -> RustResult<S> {
        var error = CError()
        let val = UnsafeMutablePointer<S>.allocate(capacity: 1)
        defer { val.deallocate() }
        if !ccall(val, &error) {
            defer { cardano_error_free(&error) }
            return .failure(CardanoRustError(error: error))
        }
        return .success(val.pointee)
    }
}
