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
    func testBaseAddress() throws {
        let mnemonic = try Mnemonic()
        let keychain = try Keychain(mnemonic: mnemonic.mnemonic(), password: Data())
        let account = try keychain.addAccount(index: 0)
        let root = try KeyPair(sk: try Bip32PrivateKey(bip39: Data(mnemonic.entropy), password: Data()))
        let path = try Bip32Path
            .prefix
            .appending(0, hard: true)
        let keyPair = try root
            .derive(index: path.purpose!)
            .derive(index: path.coin!)
            .derive(index: path.accountIndex!)
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
        let paymentPath = try! path
            .appending(0)
            .appending(0)
        let payment = StakeCredential.keyHash(
            try publicKey
                .derive(index: paymentPath.path[3])
                .derive(index: paymentPath.path[4])
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
