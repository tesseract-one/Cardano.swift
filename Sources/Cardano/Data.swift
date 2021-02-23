//
//  Data.swift
//  
//
//  Created by Yehor Popovych on 22.02.2021.
//

import Foundation
import CCardano

extension Data {
    public func withCData<T>(fn: @escaping (CData) throws -> T) rethrows -> T {
        try self.withUnsafeBytes { ptr in
            let cdata = CData(
                ptr: ptr.baseAddress?.bindMemory(
                    to: UInt8.self, capacity: ptr.count
                ),
                len: UInt(ptr.count)
            )
            return try fn(cdata)
        }
    }
}

extension CData {
    public mutating func data() -> Data {
        defer { cardano_data_free(&self) }
        return Data(bytes: self.ptr, count: Int(self.len))
    }
}
