//
//  Pointer.swift
//  
//
//  Created by Ostap Danylovych on 29.06.2021.
//

import Foundation
import CCardano

protocol CPointer: CPtr where Val: CPtr {
    init(_0: UnsafePointer<Val>!)
    
    var _0: UnsafePointer<Val>! { get set }
}

extension CPointer {
    func copied() -> Val {
        _0.pointee
    }
}

extension CPointer {
    init(from: Val) {
        self = Self(_0: withUnsafePointer(to: from) { $0 })
    }
}
