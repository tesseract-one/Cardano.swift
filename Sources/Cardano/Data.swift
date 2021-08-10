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

extension CData: CPtr {
    typealias Val = Data
    
    func copied() -> Data {
        Data(bytes: self.ptr, count: Int(self.len))
    }
    
    mutating func free() {
        cardano_data_free(&self)
    }
}

extension Data {
    private static let _srv_characters: [UInt8] = [
        UInt8(ascii: "0"), UInt8(ascii: "1"), UInt8(ascii: "2"), UInt8(ascii: "3"),
        UInt8(ascii: "4"), UInt8(ascii: "5"), UInt8(ascii: "6"), UInt8(ascii: "7"),
        UInt8(ascii: "8"), UInt8(ascii: "9"), UInt8(ascii: "a"), UInt8(ascii: "b"),
        UInt8(ascii: "c"), UInt8(ascii: "d"), UInt8(ascii: "e"), UInt8(ascii: "f")
    ]
    
    public init?(hex: String) {
        guard let data = hex.data(using: .ascii), data.count % 2 == 0 else {
            return nil
        }
        let prefix = hex.hasPrefix("0x") ? 2 : 0
        let parsed: Data? = data.withUnsafeBytes() { hex in
            var result = Data()
            result.reserveCapacity((hex.count - prefix) / 2)
            var current: UInt8? = nil
            for indx in prefix ..< hex.count {
                let v: UInt8
                switch hex[indx] {
                case let c where c <= 57: v = c - 48
                case let c where c >= 65 && c <= 70: v = c - 55
                case let c where c >= 97: v = c - 87
                default: return nil
                }
                if let val = current {
                    result.append(val << 4 | v)
                    current = nil
                } else {
                    current = v
                }
            }
            return result
        }
        if let parsed = parsed {
            self = parsed
        } else {
            return nil
        }
    }
    
    public func hex(prefix: Bool = true) -> String {
        var result = Array<UInt8>()
        result.reserveCapacity(self.count * 2 + (prefix ? 2 : 0))
        if prefix {
            result.append(UInt8(ascii: "0"))
            result.append(UInt8(ascii: "x"))
        }
        for byte in self {
            result.append(Self._srv_characters[Int(byte >> 4)])
            result.append(Self._srv_characters[Int(byte & 0x0F)])
        }
        return String(bytes: result, encoding: .ascii)!
    }
}
