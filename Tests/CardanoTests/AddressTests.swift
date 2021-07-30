//
//  AddressTests.swift
//  
//
//  Created by Ostap Danylovych on 29.07.2021.
//

import Foundation
import XCTest
@testable import Cardano

final class AddressTests: XCTestCase {
    private func rootKey12() throws -> Bip32PrivateKey {
        let entropy: [UInt8] = [0xdf, 0x9e, 0xd2, 0x5e, 0xd1, 0x46, 0xbf, 0x43, 0x33, 0x6a, 0x5d, 0x7c, 0xf7, 0x39, 0x59, 0x94];
        return try Bip32PrivateKey(bip39: Data(entropy), password: Data())
    }
    
    private func harden(_ index: UInt32) -> UInt32 {
        index | 0x80_00_00_00
    }
    
    func testBip3212Base() throws {
        let spend = try rootKey12()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 0)
            .derive(index: 0)
            .publicKey()
        let stake = try rootKey12()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 2)
            .derive(index: 0)
            .publicKey()
        let spendCred = StakeCredential.keyHash(try spend.toRawKey().hash())
        let stakeCred = StakeCredential.keyHash(try stake.toRawKey().hash())
        let addrNet0 = try BaseAddress(
            network: NetworkInfo.testnet.network_id,
            payment: spendCred,
            stake: stakeCred
        ).toAddress()
        XCTAssertEqual(
            try addrNet0.bech32(),
            "addr_test1qz2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzer3jcu5d8ps7zex2k2xt3uqxgjqnnj83ws8lhrn648jjxtwq2ytjqp"
        )
        let addrNet3 = try BaseAddress(
            network: NetworkInfo.mainnet.network_id,
            payment: spendCred,
            stake: stakeCred
        ).toAddress()
        XCTAssertEqual(
            try addrNet3.bech32(),
            "addr1qx2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzer3jcu5d8ps7zex2k2xt3uqxgjqnnj83ws8lhrn648jjxtwqfjkjv7"
        )
    }
}
