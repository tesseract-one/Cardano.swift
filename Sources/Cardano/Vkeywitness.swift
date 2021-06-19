//
//  Vkeywitness.swift
//  
//
//  Created by Ostap Danylovych on 15.06.2021.
//

import Foundation
import CCardano

public typealias Vkeywitness = CCardano.Vkeywitness

extension Vkeywitness: CType {}

public typealias Vkeywitnesses = Array<Vkeywitness>

extension CCardano.Vkeywitnesses: CArray {
    typealias CElement = CCardano.Vkeywitness

    mutating func free() {
        cardano_vkeywitnesses_free(&self)
    }
}

extension Vkeywitnesses {
    func withCArray<T>(fn: @escaping (CCardano.Vkeywitnesses) throws -> T) rethrows -> T {
        try withContiguousStorageIfAvailable { storage in
            try fn(CCardano.Vkeywitnesses(ptr: storage.baseAddress, len: UInt(storage.count)))
        }!
    }
}
