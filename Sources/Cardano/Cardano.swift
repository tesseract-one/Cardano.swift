//
//  Cardano.swift
//  
//
//  Created by Yehor Popovych on 2/3/21.
//

import Foundation
import CCardano

public struct Cardano {
    public func callRust() -> Bool {
        return hello_from_rust()
    }
}

