//
//  ProtocolParamUpdate.swift
//  
//
//  Created by Ostap Danylovych on 30.06.2021.
//

import Foundation
import CCardano

public struct ProtocolParamUpdate {
    private var _data: Data
    
    init(protocolParamUpdate: CCardano.ProtocolParamUpdate) {
        _data = protocolParamUpdate._0.copied()
    }
    
    public init(bytes: Data) throws {
        var protocolParamUpdate = try CCardano.ProtocolParamUpdate(bytes: bytes)
        self = protocolParamUpdate.owned()
    }
    
    public func bytes() throws -> Data {
        try withCProtocolParamUpdate { try $0.bytes() }
    }
    
    func clonedCProtocolParamUpdate() throws -> CCardano.ProtocolParamUpdate {
        try withCProtocolParamUpdate { try $0.clone() }
    }
    
    func withCProtocolParamUpdate<T>(
        fn: @escaping (CCardano.ProtocolParamUpdate) throws -> T
    ) rethrows -> T {
        try _data.withCData { data in
            try fn(CCardano.ProtocolParamUpdate(_0: data))
        }
    }
}

extension CCardano.ProtocolParamUpdate: CPtr {
    typealias Val = ProtocolParamUpdate
    
    func copied() -> ProtocolParamUpdate {
        ProtocolParamUpdate(protocolParamUpdate: self)
    }
    
    mutating func free() {
        cardano_protocol_param_update_free(&self)
    }
}

extension CCardano.ProtocolParamUpdate {
    public init(bytes: Data) throws {
        self = try bytes.withCData { bytes in
            RustResult<Self>.wrap { result, error in
                cardano_protocol_param_update_from_bytes(bytes, result, error)
            }
        }.get()
    }
    
    public func bytes() throws -> Data {
        var bytes = try RustResult<CData>.wrap { bytes, error in
            cardano_protocol_param_update_to_bytes(self, bytes, error)
        }.get()
        return bytes.owned()
    }
    
    public func clone() throws -> Self {
        try RustResult<CCardano.ProtocolParamUpdate>.wrap { result, error in
            cardano_protocol_param_update_clone(self, result, error)
        }.get()
    }
}
