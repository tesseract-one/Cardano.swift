//
//  AddressKind.swift
//  
//
//  Created by Yehor Popovych on 23.02.2021.
//

import Foundation
import CCardano

public enum AddressKind {
    case base(CCardano.BaseAddress)
    case byron(ByronAddress)
    
    public init(address: CCardano.Address) throws {
        switch address.tag {
        case Base: self = .base(address.base)
        case Byron: self = try .byron(ByronAddress(address: address.byron.clone()))
        default: throw CardanoRustError.unknown
        }
    }
    
    var byron: ByronAddress? {
        guard case .byron(let addr) = self else {
            return nil
        }
        return addr
    }
    
    var base: BaseAddress? {
        guard case .base(let addr) = self else {
            return nil
        }
        return addr
    }
    
    var cAddress: CCardano.Address {
        var address = CCardano.Address()
        switch self {
        case .base(let base):
            address.tag = Base
            address.base = base
        case .byron(let byron):
            address.tag = Byron
            address.byron = try! byron.cAddress()
        }
        return address
    }
}
