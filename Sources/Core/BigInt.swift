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
