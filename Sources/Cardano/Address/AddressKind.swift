//
//  AddressKind.swift
//  
//
//  Created by Yehor Popovych on 23.02.2021.
//

import Foundation
import CCardano

public typealias PointerAddress = CCardano.PointerAddress
public typealias EnterpriseAddress = CCardano.EnterpriseAddress
public typealias RewardAddress = CCardano.RewardAddress

public enum AddressKind {
    case base(BaseAddress)
    case pointer(PointerAddress)
    case enterprise(EnterpriseAddress)
    case reward(RewardAddress)
    case byron(ByronAddress)
    
    public init(address: CCardano.Address) throws {
        switch address.tag {
        case Base: self = .base(BaseAddress(address: address.base.clone()))
        case Byron: self = try .byron(ByronAddress(address: address.byron.clone()))
        case Ptr: self = .pointer(address.ptr)
        case Enterprise: self = .enterprise(address.enterprise)
        case Reward: self = .reward(address.reward)
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
    
    var pointer: PointerAddress? {
        guard case .pointer(let addr) = self else {
            return nil
        }
        return addr
    }
    
    var reward: RewardAddress? {
        guard case .reward(let addr) = self else {
            return nil
        }
        return addr
    }
    
    var enterprise: EnterpriseAddress? {
        guard case .enterprise(let addr) = self else {
            return nil
        }
        return addr
    }
    
    func cAddress() throws -> CCardano.Address {
        var address = CCardano.Address()
        switch self {
        case .base(let base):
            address.tag = Base
            address.base = try base.cAddress()
        case .byron(let byron):
            address.tag = Byron
            address.byron = try byron.cAddress()
        case .pointer(let ptr):
            address.tag = Ptr
            address.ptr = ptr
        case .enterprise(let ent):
            address.tag = Enterprise
            address.enterprise = ent
        case .reward(let rew):
            address.tag = Reward
            address.reward = rew
        }
        return address
    }
}
