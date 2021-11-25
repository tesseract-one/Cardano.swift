//
//  AccountTests.swift
//  
//
//  Created by Ostap Danylovych on 06.11.2021.
//

import Foundation
import XCTest
@testable import Cardano
import Bip39

final class AccountTests: XCTestCase {
    func testAddressIsSame() throws {
        let entropy: [UInt8] = [0xdf, 0x9e, 0xd2, 0x5e, 0xd1, 0x46, 0xbf, 0x43, 0x33, 0x6a, 0x5d, 0x7c, 0xf7, 0x39, 0x59, 0x94]
        let mnemonic = try Mnemonic(entropy: entropy)
        let keychain = try Keychain(mnemonic: mnemonic.mnemonic(), password: Data())
        let account = try keychain.addAccount(index: 0)
        let address2 = try account.baseAddress(
            index: 0,
            change: false,
            networkID: NetworkInfo.testnet.network_id
        ).address
        XCTAssertEqual(try address2.bech32(), "addr_test1qz2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzer3jcu5d8ps7zex2k2xt3uqxgjqnnj83ws8lhrn648jjxtwq2ytjqp")
    }

    func testBaseAddress() throws {
        let mnemonic = try Mnemonic()
        let keychain = try Keychain(mnemonic: mnemonic.mnemonic(), password: Data())
        let account = try keychain.addAccount(index: 0)
        let root = try KeyPair(sk: try Bip32PrivateKey(bip39: Data(mnemonic.entropy), password: Data()))
        var path = try Bip32Path
            .prefix
            .appending(0, hard: true)
        let keyPair = try root
            .derive(index: path.path[0])
            .derive(index: path.path[1])
            .derive(index: path.path[2])
        let publicKey = keyPair.publicKey
        let stakePath = try! path
            .appending(2)
            .appending(0)
        let stake = StakeCredential.keyHash(
            try publicKey
                .derive(index: stakePath.path[3])
                .derive(index: stakePath.path[4])
                .toRawKey().hash()
        )
        path = try! path
            .appending(0)
            .appending(0)
        let payment = StakeCredential.keyHash(
            try publicKey
                .derive(index: path.path[3])
                .derive(index: path.path[4])
                .toRawKey()
                .hash()
        )
        let address1 = ExtendedAddress(
            address: BaseAddress(
                network: NetworkInfo.testnet.network_id,
                payment: payment,
                stake: stake
            ).toAddress(),
            path: path
        )
        let address2 = try account.baseAddress(
            index: 0,
            change: false,
            networkID: NetworkInfo.testnet.network_id
        )
        XCTAssertEqual(address1, address2)
    }
}
