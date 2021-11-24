//
//  AddressTests.swift
//  
//
//  Created by Ostap Danylovych on 29.07.2021.
//

import Foundation
import XCTest
#if !COCOAPODS
@testable import CardanoCore
#else
@testable import Cardano
#endif

final class AddressTests: XCTestCase {
    let initialize: Void = _initialize
    
    private func rootKey12() throws -> Bip32PrivateKey {
        let entropy: [UInt8] = [0xdf, 0x9e, 0xd2, 0x5e, 0xd1, 0x46, 0xbf, 0x43, 0x33, 0x6a, 0x5d, 0x7c, 0xf7, 0x39, 0x59, 0x94]
        return try Bip32PrivateKey(bip39: Data(entropy), password: Data())
    }
    
    private func rootKey15() throws -> Bip32PrivateKey {
        let entropy: [UInt8] = [0x0c, 0xcb, 0x74, 0xf3, 0x6b, 0x7d, 0xa1, 0x64, 0x9a, 0x81, 0x44, 0x67, 0x55, 0x22, 0xd4, 0xd8, 0x09, 0x7c, 0x64, 0x12]
        return try Bip32PrivateKey(bip39: Data(entropy), password: Data())
    }
    
    private func rootKey24() throws -> Bip32PrivateKey {
        let entropy: [UInt8] = [0x4e, 0x82, 0x8f, 0x9a, 0x67, 0xdd, 0xcf, 0xf0, 0xe6, 0x39, 0x1a, 0xd4, 0xf2, 0x6d, 0xdb, 0x75, 0x79, 0xf5, 0x9b, 0xa1, 0x4b, 0x6d, 0xd4, 0xba, 0xf6, 0x3d, 0xcf, 0xdb, 0x9d, 0x24, 0x20, 0xda]
        return try Bip32PrivateKey(bip39: Data(entropy), password: Data())
    }
    
    private func harden(_ index: UInt32) -> UInt32 {
        index | 0x80_00_00_00
    }
    
    func testBaseSerializeConsistency() throws {
        let base = BaseAddress(
            network: 5,
            payment: StakeCredential.keyHash(try Ed25519KeyHash(bytes: Data(repeating: 23, count: 28))),
            stake: StakeCredential.scriptHash(try ScriptHash(bytes: Data(repeating: 42, count: 28)))
        )
        let addr = base.toAddress()
        let addr2 = try Address(bytes: addr.bytes())
        XCTAssertEqual(try addr.bytes(), try addr2.bytes())
    }

    func testPtrSerializeConsistency() throws {
        let ptr = PointerAddress(
            network: 25,
            payment: StakeCredential.keyHash(try Ed25519KeyHash(bytes: Data(repeating: 23, count: 28))),
            stake: Pointer(slot: 2354556573, tx_index: 127, cert_index: 0)
        )
        let addr = ptr.toAddress()
        let addr2 = try Address(bytes: addr.bytes())
        XCTAssertEqual(try addr.bytes(), try addr2.bytes())
    }
    
    func testEnterpriseSerializeConsistency() throws {
        let enterprise = EnterpriseAddress(
            network: 64,
            payment: StakeCredential.keyHash(try Ed25519KeyHash(bytes: Data(repeating: 23, count: 28)))
        )
        let addr = enterprise.toAddress()
        let addr2 = try Address(bytes: try addr.bytes())
        XCTAssertEqual(try addr.bytes(), try addr2.bytes())
    }
    
    func testRewardSerializeConsistency() throws {
        let reward = RewardAddress(
            network: 9,
            payment: StakeCredential.scriptHash(try ScriptHash(bytes: Data(repeating: 127, count: 28)))
        )
        let addr = reward.toAddress()
        let addr2 = try Address(bytes: try addr.bytes())
        XCTAssertEqual(try addr.bytes(), try addr2.bytes())
    }
    
    func testBech32Parsing() throws {
        let addr = try Address(bech32: "addr1u8pcjgmx7962w6hey5hhsd502araxp26kdtgagakhaqtq8sxy9w7g")
        XCTAssertEqual(try addr.bech32(prefix: "foobar"), "foobar1u8pcjgmx7962w6hey5hhsd502araxp26kdtgagakhaqtq8s92n4tm")
    }
    
    func testByronMagicParsing() throws {
        let addr = try ByronAddress(base58: "Ae2tdPwUPEZ4YjgvykNpoFeYUxoyhNj2kg8KfKWN2FizsSpLUPv68MpTVDo")
        XCTAssertEqual(try addr.byronProtocolMagic(), NetworkInfo.mainnet.protocol_magic)
        XCTAssertEqual(try addr.networkId(), NetworkInfo.mainnet.network_id)
        let addr2 = try ByronAddress(base58: "2cWKMJemoBaipzQe9BArYdo2iPUfJQdZAjm4iCzDA1AfNxJSTgm9FZQTmFCYhKkeYrede")
        XCTAssertEqual(try addr2.byronProtocolMagic(), NetworkInfo.testnet.protocol_magic)
        XCTAssertEqual(try addr2.networkId(), NetworkInfo.testnet.network_id)
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
        let addrNet0 = BaseAddress(
            network: NetworkInfo.testnet.network_id,
            payment: spendCred,
            stake: stakeCred
        ).toAddress()
        XCTAssertEqual(
            try addrNet0.bech32(),
            "addr_test1qz2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzer3jcu5d8ps7zex2k2xt3uqxgjqnnj83ws8lhrn648jjxtwq2ytjqp"
        )
        let addrNet3 = BaseAddress(
            network: NetworkInfo.mainnet.network_id,
            payment: spendCred,
            stake: stakeCred
        ).toAddress()
        XCTAssertEqual(
            try addrNet3.bech32(),
            "addr1qx2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzer3jcu5d8ps7zex2k2xt3uqxgjqnnj83ws8lhrn648jjxtwqfjkjv7"
        )
    }
    
    func testBip3212Enterprise() throws {
        let spend = try rootKey12()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 0)
            .derive(index: 0)
            .publicKey()
        let spendCred = StakeCredential.keyHash(try spend.toRawKey().hash())
        let addrNet0 = EnterpriseAddress(
            network: NetworkInfo.testnet.network_id,
            payment: spendCred
        ).toAddress()
        XCTAssertEqual(
            try addrNet0.bech32(),
            "addr_test1vz2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzerspjrlsz"
        )
        let addrNet3 = EnterpriseAddress(
            network: NetworkInfo.mainnet.network_id,
            payment: spendCred
        ).toAddress()
        XCTAssertEqual(
            try addrNet3.bech32(),
            "addr1vx2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzers66hrl8"
        )
    }
    
    func testBip3212Pointer() throws {
        let spend = try rootKey12()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 0)
            .derive(index: 0)
            .publicKey()
        let spendCred = StakeCredential.keyHash(try spend.toRawKey().hash())
        let addrNet0 = PointerAddress(
            network: NetworkInfo.testnet.network_id,
            payment: spendCred,
            stake: Pointer(slot: 1, tx_index: 2, cert_index: 3)
        ).toAddress()
        XCTAssertEqual(
            try addrNet0.bech32(),
            "addr_test1gz2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzerspqgpsqe70et"
        )
        let addrNet3 = PointerAddress(
            network: NetworkInfo.mainnet.network_id,
            payment: spendCred,
            stake: Pointer(slot: 24157, tx_index: 177, cert_index: 42)
        ).toAddress()
        XCTAssertEqual(
            try addrNet3.bech32(),
            "addr1gx2fxv2umyhttkxyxp8x0dlpdt3k6cwng5pxj3jhsydzer5ph3wczvf2w8lunk"
        )
    }
    
    func testBip3215Base() throws {
        let spend = try rootKey15()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 0)
            .derive(index: 0)
            .publicKey()
        let stake = try rootKey15()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 2)
            .derive(index: 0)
            .publicKey()
        let spendCred = StakeCredential.keyHash(try spend.toRawKey().hash())
        let stakeCred = StakeCredential.keyHash(try stake.toRawKey().hash())
        let addrNet0 = BaseAddress(
            network: NetworkInfo.testnet.network_id,
            payment: spendCred,
            stake: stakeCred
        ).toAddress()
        XCTAssertEqual(
            try addrNet0.bech32(),
            "addr_test1qpu5vlrf4xkxv2qpwngf6cjhtw542ayty80v8dyr49rf5ewvxwdrt70qlcpeeagscasafhffqsxy36t90ldv06wqrk2qum8x5w"
        )
        let addrNet3 = BaseAddress(
            network: NetworkInfo.mainnet.network_id,
            payment: spendCred,
            stake: stakeCred
        ).toAddress()
        XCTAssertEqual(
            try addrNet3.bech32(),
            "addr1q9u5vlrf4xkxv2qpwngf6cjhtw542ayty80v8dyr49rf5ewvxwdrt70qlcpeeagscasafhffqsxy36t90ldv06wqrk2qld6xc3"
        )
    }
    
    func testBip3215Enterprise() throws {
        let spend = try rootKey15()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 0)
            .derive(index: 0)
            .publicKey()
        let spendCred = StakeCredential.keyHash(try spend.toRawKey().hash())
        let addrNet0 = EnterpriseAddress(
            network: NetworkInfo.testnet.network_id,
            payment: spendCred
        ).toAddress()
        XCTAssertEqual(
            try addrNet0.bech32(),
            "addr_test1vpu5vlrf4xkxv2qpwngf6cjhtw542ayty80v8dyr49rf5eg57c2qv"
        )
        let addrNet3 = EnterpriseAddress(
            network: NetworkInfo.mainnet.network_id,
            payment: spendCred
        ).toAddress()
        XCTAssertEqual(
            try addrNet3.bech32(),
            "addr1v9u5vlrf4xkxv2qpwngf6cjhtw542ayty80v8dyr49rf5eg0kvk0f"
        )
    }
    
    func testBip3215Pointer() throws {
        let spend = try rootKey15()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 0)
            .derive(index: 0)
            .publicKey()
        let spendCred = StakeCredential.keyHash(try spend.toRawKey().hash())
        let addrNet0 = PointerAddress(
            network: NetworkInfo.testnet.network_id,
            payment: spendCred,
            stake: Pointer(slot: 1, tx_index: 2, cert_index: 3)
        ).toAddress()
        XCTAssertEqual(
            try addrNet0.bech32(),
            "addr_test1gpu5vlrf4xkxv2qpwngf6cjhtw542ayty80v8dyr49rf5egpqgpsdhdyc0"
        )
        let addrNet3 = PointerAddress(
            network: NetworkInfo.mainnet.network_id,
            payment: spendCred,
            stake: Pointer(slot: 24157, tx_index: 177, cert_index: 42)
        ).toAddress()
        XCTAssertEqual(
            try addrNet3.bech32(),
            "addr1g9u5vlrf4xkxv2qpwngf6cjhtw542ayty80v8dyr49rf5evph3wczvf2kd5vam"
        )
    }
    
    func testParseRedeemAddress() throws {
        let address = "Ae2tdPwUPEZ3MHKkpT5Bpj549vrRH7nBqYjNXnCV8G2Bc2YxNcGHEa8ykDp"
        XCTAssertTrue(try ByronAddress.isValid(s: address))
        let byronAddr = try ByronAddress(base58: address)
        XCTAssertEqual(try byronAddr.base58(), address)
        let byronAddr2 = try ByronAddress(base58: address)
        XCTAssertEqual(try byronAddr2.base58(), address)
    }
    
    func testBip3215Byron() throws {
        let address = "Ae2tdPwUPEZHtBmjZBF4YpMkK9tMSPTE2ADEZTPN97saNkhG78TvXdp3GDk"
        let byronKey = try rootKey15()
            .derive(index: harden(44))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 0)
            .derive(index: 0)
            .publicKey()
        let byronAddr = try ByronAddress(key: byronKey, protocolMagic: NetworkInfo.mainnet.protocol_magic)
        XCTAssertEqual(try byronAddr.base58(), address)
        XCTAssertTrue(try ByronAddress.isValid(s: address))
        XCTAssertEqual(try byronAddr.networkId(), 0b0001)
        let byronAddr2 = try Address(bytes: try byronAddr.bytes()).byron!
        XCTAssertEqual(try byronAddr.base58(), try byronAddr2.base58())
    }
    
    func testBip3224Base() throws {
        let spend = try rootKey24()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 0)
            .derive(index: 0)
            .publicKey()
        let stake = try rootKey24()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 2)
            .derive(index: 0)
            .publicKey()
        let spendCred = StakeCredential.keyHash(try spend.toRawKey().hash())
        let stakeCred = StakeCredential.keyHash(try stake.toRawKey().hash())
        let addrNet0 = BaseAddress(
            network: NetworkInfo.testnet.network_id,
            payment: spendCred,
            stake: stakeCred
        ).toAddress()
        XCTAssertEqual(
            try addrNet0.bech32(),
            "addr_test1qqy6nhfyks7wdu3dudslys37v252w2nwhv0fw2nfawemmn8k8ttq8f3gag0h89aepvx3xf69g0l9pf80tqv7cve0l33sw96paj"
        )
        let addrNet3 = BaseAddress(
            network: NetworkInfo.mainnet.network_id,
            payment: spendCred,
            stake: stakeCred
        ).toAddress()
        XCTAssertEqual(
            try addrNet3.bech32(),
            "addr1qyy6nhfyks7wdu3dudslys37v252w2nwhv0fw2nfawemmn8k8ttq8f3gag0h89aepvx3xf69g0l9pf80tqv7cve0l33sdn8p3d"
        )
    }
    
    func testBip3224Enterprise() throws {
        let spend = try rootKey24()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 0)
            .derive(index: 0)
            .publicKey()
        let spendCred = StakeCredential.keyHash(try spend.toRawKey().hash())
        let addrNet0 = EnterpriseAddress(
            network: NetworkInfo.testnet.network_id,
            payment: spendCred
        ).toAddress()
        XCTAssertEqual(
            try addrNet0.bech32(),
            "addr_test1vqy6nhfyks7wdu3dudslys37v252w2nwhv0fw2nfawemmnqtjtf68"
        )
        let addrNet3 = EnterpriseAddress(
            network: NetworkInfo.mainnet.network_id,
            payment: spendCred
        ).toAddress()
        XCTAssertEqual(
            try addrNet3.bech32(),
            "addr1vyy6nhfyks7wdu3dudslys37v252w2nwhv0fw2nfawemmnqs6l44z"
        )
    }
    
    func testBip3224Pointer() throws {
        let spend = try rootKey24()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 0)
            .derive(index: 0)
            .publicKey()
        let spendCred = StakeCredential.keyHash(try spend.toRawKey().hash())
        let addrNet0 = PointerAddress(
            network: NetworkInfo.testnet.network_id,
            payment: spendCred,
            stake: Pointer(slot: 1, tx_index: 2, cert_index: 3)
        ).toAddress()
        XCTAssertEqual(
            try addrNet0.bech32(),
            "addr_test1gqy6nhfyks7wdu3dudslys37v252w2nwhv0fw2nfawemmnqpqgps5mee0p"
        )
        let addrNet3 = PointerAddress(
            network: NetworkInfo.mainnet.network_id,
            payment: spendCred,
            stake: Pointer(slot: 24157, tx_index: 177, cert_index: 42)
        ).toAddress()
        XCTAssertEqual(
            try addrNet3.bech32(),
            "addr1gyy6nhfyks7wdu3dudslys37v252w2nwhv0fw2nfawemmnyph3wczvf2dqflgt"
        )
    }
    
    func testBip3212Reward() throws {
        let stakingKey = try rootKey12()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 2)
            .derive(index: 0)
            .publicKey()
        let stakingCred = StakeCredential.keyHash(try stakingKey.toRawKey().hash())
        let addrNet0 = RewardAddress(
            network: NetworkInfo.testnet.network_id,
            payment: stakingCred
        ).toAddress()
        XCTAssertEqual(
            try addrNet0.bech32(),
            "stake_test1uqevw2xnsc0pvn9t9r9c7qryfqfeerchgrlm3ea2nefr9hqp8n5xl"
        )
        let addrNet3 = RewardAddress(
            network: NetworkInfo.mainnet.network_id,
            payment: stakingCred
        ).toAddress()
        XCTAssertEqual(
            try addrNet3.bech32(),
            "stake1uyevw2xnsc0pvn9t9r9c7qryfqfeerchgrlm3ea2nefr9hqxdekzz"
        )
    }
}
