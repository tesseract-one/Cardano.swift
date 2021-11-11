//
//  TestEnvironment.swift
//  
//
//  Created by Ostap Danylovych on 11.11.2021.
//

import Foundation
import Cardano

struct TestEnvironment {
    let mnemonic: [String]
    let blockfrostProjectId: String
    let addresses: [Address]
    let publicKey: Bip32PublicKey
    
    static var instance: Self {
        let env = ProcessInfo.processInfo.environment
        let mnemonic = env["CARDANO_TEST_MNEMONIC"]!
        let blockfrostProjectId = env["CARDANO_TEST_BLOCKFROST_PROJECT_ID"]!
        let addresses = env["CARDANO_TEST_ADDRESSES"]!
        let publicKey = env["CARDANO_TEST_PUBLIC_KEY"]!
        return Self(
            mnemonic: mnemonic.components(separatedBy: " "),
            blockfrostProjectId: blockfrostProjectId,
            addresses: try! addresses.components(separatedBy: "\n").map {
                try Address(bech32: $0)
            },
            publicKey: try! Bip32PublicKey(bech32: publicKey)
        )
    }
}
