//
//  Cardano.swift
//  
//
//  Created by Yehor Popovych on 2/3/21.
//

import Foundation
import CCardano
#if !COCOAPODS
@_exported import CardanoCore
#endif

public class Cardano {
    private static let _initialize: Void = {
        cardano_initialize()
    }()
    
    public init() {
        let _ = Cardano._initialize
    }
}

