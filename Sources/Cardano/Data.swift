//
//  Data.swift
//  
//
//  Created by Yehor Popovych on 22.02.2021.
//

import Foundation
import CCardano

extension Data {
    func withCData<T>(fn: @escaping (CData) throws -> T) rethrows -> T {
        try self.withUnsafeBytes { ptr in
            let bytesPtr = ptr.bindMemory(to: UInt8.self)
            let cdata = CData(
                ptr: bytesPtr.baseAddress,
                len: UInt(bytesPtr.count)
            )
            return try fn(cdata)
        }
    }
}

extension CData {
    mutating func data() -> Data {
        defer { cardano_data_free(&self) }
        return Data(bytes: self.ptr, count: Int(self.len))
    }
    
    func copied() -> Data {
        return Data(bytes: self.ptr, count: Int(self.len))
    }
}
