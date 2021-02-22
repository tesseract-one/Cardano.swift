//
//  Cardano.swift
//  
//
//  Created by Yehor Popovych on 2/3/21.
//

import Foundation
import CCardano

public class Cardano {
    private static let _initialize: Void = {
        cardano_initialize()
    }()
    
    public init() {
        let _ = Cardano._initialize
    }
}

