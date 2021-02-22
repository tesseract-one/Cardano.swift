//
//  Address.swift
//  
//
//  Created by Yehor Popovych on 22.02.2021.
//

import Foundation
import CCardano

public class Address {
    private var address: CAddress
    
    private init(address: CAddress) {
        self.address = address
    }
    
    public convenience init(bytes: Data) throws {
        let address = try bytes.withCData { bytes in
            RustResult<CAddress>.wrap { address, error in
                cardano_address_from_bytes(bytes, address, error)
            }
        }.get()
        self.init(address: address)
    }
    
    public convenience init(bech32: String) throws {
        let address = try bech32.withCharPtr { bech32 in
            RustResult<CAddress>.wrap { address, error in
                cardano_address_from_bech32(bech32, address, error)
            }
        }.get()
        self.init(address: address)
    }
    
    public func bytes() throws -> Data {
        var data = try RustResult<CData>.wrap { data, error in
            cardano_address_to_bytes(self.address, data, error)
        }.get()
        return data.data()
    }
    
    public func bech32(prefix: Optional<String>) throws -> String {
        let chars = try prefix.withCharPtr { chPtr in
            RustResult<CharPtr>.wrap { out, error in
                cardano_address_to_bech32(self.address, chPtr, out, error)
            }
        }.get()
        return chars!.string()
    }
    
    public func networkId() throws -> NetworkId {
        try RustResult<NetworkId>.wrap { id, error in
            cardano_address_network_id(self.address, id, error)
        }.get()
    }
    
    deinit {
        cardano_address_free(&self.address)
    }
}
