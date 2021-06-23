//
//  GenesisKeyDelegation.swift
//  
//
//  Created by Ostap Danylovych on 24.06.2021.
//

import Foundation
import CCardano

public typealias GenesisHash = CCardano.GenesisHash

extension GenesisHash: CType {}

public typealias GenesisDelegateHash = CCardano.GenesisDelegateHash

extension GenesisDelegateHash: CType {}

public typealias VRFKeyHash = CCardano.VRFKeyHash

extension VRFKeyHash: CType {}

public typealias GenesisKeyDelegation = CCardano.GenesisKeyDelegation

extension GenesisKeyDelegation: CType {}
