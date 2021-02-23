//
//  Error.swift
//  
//
//  Created by Yehor Popovych on 22.02.2021.
//

import Foundation
import CCardano

public enum CardanoRustError: Error {
    case nullPtr
    case dataLengthMismatch
    case panic(reason: String)
    case utf8(message: String)
    case deserialization(message: String)
    case common(message: String)
    case unknown
    
    
    public init(error: CError) {
        switch error.tag {
        case NullPtr: self = .nullPtr
        case DataLengthMismatch: self = .dataLengthMismatch
        case Panic: self = .panic(reason: error.panic.string())
        case Utf8Error: self = .utf8(message: error.utf8_error.string())
        case DeserializeError:
            self = .deserialization(message: error.deserialize_error.string())
        case Error: self = .common(message: error.error.string())
        default: self = .unknown
        }
    }
}
