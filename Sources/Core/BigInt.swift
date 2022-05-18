//
//  BigInt.swift
//  
//
//  Created by Yehor Popovych on 13.08.2021.
//

import Foundation
import CCardano
import BigInt

extension BigInt {
    public var cInt128: CInt128 {
        CInt128(w1: Int64(self >> 64), w2: UInt64(self & BigInt(UInt64.max)))
    }
}

extension BigUInt {
    public var cUInt128: CUInt128 {
        CUInt128(w1: UInt64(self >> 64), w2: UInt64(self & BigUInt(UInt64.max)))
    }
}

extension CInt128 {
    public var bigInt: BigInt {
        (BigInt(self.w1) << 64) | BigInt(self.w2)
    }
}

extension CUInt128 {
    public var bigUInt: BigUInt {
        (BigUInt(self.w1) << 64) | BigUInt(self.w2)
    }
}

extension CArray_u32: CArray {
    typealias CElement = UInt32
    typealias Val = [UInt32]

    mutating func free() {}
}

extension BigInt {
    public func cBigInt<T>(fn: @escaping (CBigInt) throws -> T) rethrows -> T {
        var sign: CCardano.Sign
        switch self.sign {
        case .plus: sign = Plus
        case .minus: sign = Minus
        }
        if isZero {
            sign = NoSign
        }
        return try magnitude.words.map { UInt32($0) }.withCArr { data in
            try fn(CBigInt(sign: sign, data: data))
        }
    }
}

extension CBigInt {
    public var bigInt: BigInt {
        let sign: BigInt.Sign
        switch self.sign {
        case Minus: sign = .minus
        case NoSign: sign = .plus
        case Plus: sign = .plus
        default: fatalError("Unknown Sign type")
        }
        return BigInt(
            sign: sign,
            magnitude: BigUInt(words: data.copied().map { UInt($0) })
        )
    }
}
