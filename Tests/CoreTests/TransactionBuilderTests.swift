//
//  TransactionBuilderTests.swift
//  
//
//  Created by Ostap Danylovych on 27.07.2021.
//

import Foundation
import XCTest
#if !COCOAPODS
@testable import CardanoCore
#else
@testable import Cardano
#endif

final class TransactionBuilderTests: XCTestCase {
    let initialize: Void = _initialize
    private let maxValueSize: UInt32 = 4000
    private let maxTxSize: UInt32 = 8000
    
    private func genesisId() throws -> TransactionHash {
        try TransactionHash(bytes: Data(repeating: 0, count: 32))
    }
    
    private func rootKey15() throws -> Bip32PrivateKey {
        let entropy: [UInt8] = [0x0c, 0xcb, 0x74, 0xf3, 0x6b, 0x7d, 0xa1, 0x64, 0x9a, 0x81, 0x44, 0x67, 0x55, 0x22, 0xd4, 0xd8, 0x09, 0x7c, 0x64, 0x12]
        return try Bip32PrivateKey(bip39: Data(entropy), password: Data())
    }
    
    private func harden(_ index: UInt32) -> UInt32 {
        index | 0x80_00_00_00
    }
    
    func testBuildTxWithChange() throws {
        let linearFee = LinearFee(constant: 2, coefficient: 500)
        let config = TransactionBuilderConfig(
            fee_algo: linearFee,
            pool_deposit: 1,
            key_deposit: 1,
            max_value_size: maxValueSize,
            max_tx_size: maxTxSize,
            coins_per_utxo_word: 1,
            prefer_pure_change: false
        )
        var txBuilder = try TransactionBuilder(config: config)
        let spend = try rootKey15()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 0)
            .derive(index: 0)
            .publicKey()
        let changeKey = try rootKey15()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 1)
            .derive(index: 0)
            .publicKey()
        let stake = try rootKey15()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 2)
            .derive(index: 0)
            .publicKey()
        let spendCred = try StakeCredential.keyHash(spend.toRawKey().hash())
        let stakeCred = try StakeCredential.keyHash(stake.toRawKey().hash())
        let addrNet0 = BaseAddress(
            network: NetworkInfo.testnet.network_id,
            payment: spendCred,
            stake: stakeCred
        ).toAddress()
        try txBuilder.addKeyInput(
            hash: spend.toRawKey().hash(),
            input: TransactionInput(transaction_id: genesisId(), index: 0),
            amount: Value(coin: 1_000_000)
        )
        try txBuilder.addOutput(output: TransactionOutput(address: addrNet0, amount: Value(coin: 29)))
        txBuilder.ttl = 1000
        let changeCred = StakeCredential.keyHash(try changeKey.toRawKey().hash())
        let changeAddr = BaseAddress(
            network: NetworkInfo.testnet.network_id,
            payment: changeCred,
            stake: stakeCred
        ).toAddress()
        let addedChange = try txBuilder.addChangeIfNeeded(address: changeAddr)
        assert(addedChange)
        XCTAssertEqual(txBuilder.outputs.count, 2)
        XCTAssertEqual(
            try txBuilder.getExplicitInput().checkedAdd(rhs: txBuilder.getImplicitInput()).coin,
            try txBuilder.getExplicitOutput().checkedAdd(rhs: Value(coin: txBuilder.fee!)).coin
        )
        XCTAssertNoThrow(try txBuilder.build())
    }
    
    func testBuildTxWithoutChange() throws {
        let linearFee = LinearFee(constant: 2, coefficient: 500)
        let config = TransactionBuilderConfig(
            fee_algo: linearFee,
            pool_deposit: 1,
            key_deposit: 1,
            max_value_size: maxValueSize,
            max_tx_size: maxTxSize,
            coins_per_utxo_word: 1,
            prefer_pure_change: false
        )
        var txBuilder = try TransactionBuilder(config: config)
        let spend = try rootKey15()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 0)
            .derive(index: 0)
            .publicKey()
        let changeKey = try rootKey15()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 1)
            .derive(index: 0)
            .publicKey()
        let stake = try rootKey15()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 2)
            .derive(index: 0)
            .publicKey()
        let spendCred = try StakeCredential.keyHash(spend.toRawKey().hash())
        let stakeCred = try StakeCredential.keyHash(stake.toRawKey().hash())
        let addrNet0 = BaseAddress(
            network: NetworkInfo.testnet.network_id,
            payment: spendCred,
            stake: stakeCred
        ).toAddress()
        try txBuilder.addKeyInput(
            hash: spend.toRawKey().hash(),
            input: TransactionInput(transaction_id: genesisId(), index: 0),
            amount: Value(coin: 1_000_000)
        )
        try txBuilder.addOutput(output: TransactionOutput(address: addrNet0, amount: Value(coin: 880_000)))
        txBuilder.ttl = 1000
        let changeCred = StakeCredential.keyHash(try changeKey.toRawKey().hash())
        let changeAddr = BaseAddress(
            network: NetworkInfo.testnet.network_id,
            payment: changeCred,
            stake: stakeCred
        ).toAddress()
        let addedChange = try txBuilder.addChangeIfNeeded(address: changeAddr)
        assert(!addedChange)
        XCTAssertEqual(txBuilder.outputs.count, 1)
        XCTAssertEqual(
            try txBuilder.getExplicitInput().checkedAdd(rhs: txBuilder.getImplicitInput()).coin,
            try txBuilder.getExplicitOutput().checkedAdd(rhs: Value(coin: txBuilder.fee!)).coin
        )
        XCTAssertNoThrow(try txBuilder.build())
    }
    
    func testBuildTxWithCerts() throws {
        let linearFee = LinearFee(constant: 2, coefficient: 500)
        let config = TransactionBuilderConfig(
            fee_algo: linearFee,
            pool_deposit: 1,
            key_deposit: 1_000_000,
            max_value_size: maxValueSize,
            max_tx_size: maxTxSize,
            coins_per_utxo_word: 1,
            prefer_pure_change: false
        )
        var txBuilder = try TransactionBuilder(config: config)
        let spend = try rootKey15()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 0)
            .derive(index: 0)
            .publicKey()
        let changeKey = try rootKey15()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 1)
            .derive(index: 0)
            .publicKey()
        let stake = try rootKey15()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 2)
            .derive(index: 0)
            .publicKey()
        let stakeCred = try StakeCredential.keyHash(stake.toRawKey().hash())
        try txBuilder.addKeyInput(
            hash: spend.toRawKey().hash(),
            input: TransactionInput(transaction_id: genesisId(), index: 0),
            amount: Value(coin: 5_000_000)
        )
        txBuilder.ttl = 1000
        let certs = [
            Certificate.stakeRegistration(StakeRegistration(stakeCredential: stakeCred)),
            Certificate.stakeDelegation(
                StakeDelegation(stakeCredential: stakeCred, poolKeyhash: try stake.toRawKey().hash())
            )
        ]
        try txBuilder.setCerts(certs: certs)
        let changeCred = StakeCredential.keyHash(try changeKey.toRawKey().hash())
        let changeAddr = BaseAddress(
            network: NetworkInfo.testnet.network_id,
            payment: changeCred,
            stake: stakeCred
        ).toAddress()
        let _ = try txBuilder.addChangeIfNeeded(address: changeAddr)
        XCTAssertEqual(try txBuilder.minFee(), 214002)
        XCTAssertEqual(txBuilder.fee!, 214002)
        XCTAssertEqual(try txBuilder.getDeposit(), 1000000)
        XCTAssertEqual(txBuilder.outputs.count, 1)
        XCTAssertEqual(
            try txBuilder.getExplicitInput().checkedAdd(rhs: txBuilder.getImplicitInput()).coin,
            try txBuilder.getExplicitOutput().checkedAdd(rhs: Value(coin: txBuilder.fee!))
                .checkedAdd(rhs: Value(coin: txBuilder.getDeposit())).coin
        )
        XCTAssertNoThrow(try txBuilder.build())
    }
    
    func testBuildTxExactAmount() throws {
        let linearFee = LinearFee(constant: 0, coefficient: 0)
        let config = TransactionBuilderConfig(
            fee_algo: linearFee,
            pool_deposit: 0,
            key_deposit: 0,
            max_value_size: maxValueSize,
            max_tx_size: maxTxSize,
            coins_per_utxo_word: 1,
            prefer_pure_change: false
        )
        var txBuilder = try TransactionBuilder(config: config)
        let spend = try rootKey15()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 0)
            .derive(index: 0)
            .publicKey()
        let changeKey = try rootKey15()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 1)
            .derive(index: 0)
            .publicKey()
        let stake = try rootKey15()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 2)
            .derive(index: 0)
            .publicKey()
        try txBuilder.addKeyInput(
            hash: spend.toRawKey().hash(),
            input: TransactionInput(transaction_id: genesisId(), index: 0),
            amount: Value(coin: 100)
        )
        let spendCred = try StakeCredential.keyHash(spend.toRawKey().hash())
        let stakeCred = try StakeCredential.keyHash(stake.toRawKey().hash())
        let addrNet0 = BaseAddress(
            network: NetworkInfo.testnet.network_id,
            payment: spendCred,
            stake: stakeCred
        ).toAddress()
        try txBuilder.addOutput(output: TransactionOutput(address: addrNet0, amount: Value(coin: 100)))
        txBuilder.ttl = 0
        let changeCred = StakeCredential.keyHash(try changeKey.toRawKey().hash())
        let changeAddr = BaseAddress(
            network: NetworkInfo.testnet.network_id,
            payment: changeCred,
            stake: stakeCred
        ).toAddress()
        let addedChange = try txBuilder.addChangeIfNeeded(address: changeAddr)
        assert(!addedChange)
        let finalTx = try txBuilder.build()
        XCTAssertEqual(finalTx.outputs.count, 1)
    }
    
    func testBuildTxExactChange() throws {
        let linearFee = LinearFee(constant: 0, coefficient: 0)
        let config = TransactionBuilderConfig(
            fee_algo: linearFee,
            pool_deposit: 0,
            key_deposit: 0,
            max_value_size: maxValueSize,
            max_tx_size: maxTxSize,
            coins_per_utxo_word: 1,
            prefer_pure_change: false
        )
        var txBuilder = try TransactionBuilder(config: config)
        let spend = try rootKey15()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 0)
            .derive(index: 0)
            .publicKey()
        let changeKey = try rootKey15()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 1)
            .derive(index: 0)
            .publicKey()
        let stake = try rootKey15()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 2)
            .derive(index: 0)
            .publicKey()
        try txBuilder.addKeyInput(
            hash: spend.toRawKey().hash(),
            input: TransactionInput(transaction_id: genesisId(), index: 0),
            amount: Value(coin: 58)
        )
        let spendCred = try StakeCredential.keyHash(spend.toRawKey().hash())
        let stakeCred = try StakeCredential.keyHash(stake.toRawKey().hash())
        let addrNet0 = BaseAddress(
            network: NetworkInfo.testnet.network_id,
            payment: spendCred,
            stake: stakeCred
        ).toAddress()
        try txBuilder.addOutput(output: TransactionOutput(address: addrNet0, amount: Value(coin: 29)))
        txBuilder.ttl = 0
        let changeCred = StakeCredential.keyHash(try changeKey.toRawKey().hash())
        let changeAddr = BaseAddress(
            network: NetworkInfo.testnet.network_id,
            payment: changeCred,
            stake: stakeCred
        ).toAddress()
        let addedChange = try txBuilder.addChangeIfNeeded(address: changeAddr)
        assert(addedChange)
        let finalTx = try txBuilder.build()
        XCTAssertEqual(finalTx.outputs.count, 2)
        XCTAssertEqual(finalTx.outputs[1].amount.coin, 29)
    }
    
    func testBuildTxInsufficientDeposit() throws {
        let linearFee = LinearFee(constant: 0, coefficient: 0)
        let config = TransactionBuilderConfig(
            fee_algo: linearFee,
            pool_deposit: 0,
            key_deposit: 5,
            max_value_size: maxValueSize,
            max_tx_size: maxTxSize,
            coins_per_utxo_word: 1,
            prefer_pure_change: false
        )
        var txBuilder = try TransactionBuilder(config: config)
        let spend = try rootKey15()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 0)
            .derive(index: 0)
            .publicKey()
        let changeKey = try rootKey15()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 1)
            .derive(index: 0)
            .publicKey()
        let stake = try rootKey15()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 2)
            .derive(index: 0)
            .publicKey()
        try txBuilder.addKeyInput(
            hash: spend.toRawKey().hash(),
            input: TransactionInput(transaction_id: genesisId(), index: 0),
            amount: Value(coin: 5)
        )
        let spendCred = try StakeCredential.keyHash(spend.toRawKey().hash())
        let stakeCred = try StakeCredential.keyHash(stake.toRawKey().hash())
        let addrNet0 = BaseAddress(
            network: NetworkInfo.testnet.network_id,
            payment: spendCred,
            stake: stakeCred
        ).toAddress()
        XCTAssertThrowsError(try txBuilder.addOutput(output: TransactionOutput(address: addrNet0, amount: Value(coin: 5))))
        txBuilder.ttl = 0
        let certs = [
            Certificate.stakeRegistration(StakeRegistration(stakeCredential: stakeCred))
        ]
        try txBuilder.setCerts(certs: certs)
        let changeCred = StakeCredential.keyHash(try changeKey.toRawKey().hash())
        let changeAddr = BaseAddress(
            network: NetworkInfo.testnet.network_id,
            payment: changeCred,
            stake: stakeCred
        ).toAddress()
        let _ = try txBuilder.addChangeIfNeeded(address: changeAddr)
    }
    
    func testBuildTxWithInputs() throws {
        let linearFee = LinearFee(constant: 2, coefficient: 500)
        let config = TransactionBuilderConfig(
            fee_algo: linearFee,
            pool_deposit: 1,
            key_deposit: 1,
            max_value_size: maxValueSize,
            max_tx_size: maxTxSize,
            coins_per_utxo_word: 1,
            prefer_pure_change: false
        )
        var txBuilder = try TransactionBuilder(config: config)
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
        let spendCred = try StakeCredential.keyHash(spend.toRawKey().hash())
        let stakeCred = try StakeCredential.keyHash(stake.toRawKey().hash())
        XCTAssertEqual(
            try txBuilder.feeForInput(
                address: EnterpriseAddress(network: NetworkInfo.testnet.network_id, payment: spendCred).toAddress(),
                input: TransactionInput(transaction_id: genesisId(), index: 0),
                amount: Value(coin: 1_000_000)
            ),
            69500
        )
        try txBuilder.addInput(
            address: EnterpriseAddress(network: NetworkInfo.testnet.network_id, payment: spendCred).toAddress(),
            input: TransactionInput(transaction_id: genesisId(), index: 0),
            amount: Value(coin: 1_000_000)
        )
        try txBuilder.addInput(
            address: BaseAddress(network: NetworkInfo.testnet.network_id, payment: spendCred, stake: stakeCred).toAddress(),
            input: TransactionInput(transaction_id: genesisId(), index: 0),
            amount: Value(coin: 1_000_000)
        )
        try txBuilder.addInput(
            address: PointerAddress(
                network: NetworkInfo.testnet.network_id,
                payment: spendCred,
                stake: Pointer(slot: 0, tx_index: 0, cert_index: 0)
            ).toAddress(),
            input: TransactionInput(transaction_id: genesisId(), index: 0),
            amount: Value(coin: 1_000_000)
        )
        try txBuilder.addInput(
            address: ByronAddress(key: spend, protocolMagic: NetworkInfo.testnet.protocol_magic).toAddress(),
            input: TransactionInput(transaction_id: genesisId(), index: 0),
            amount: Value(coin: 1_000_000)
        )
        XCTAssertEqual(txBuilder.inputs.count, 4)
    }
    
    func testBuildTxWithNativeAssetsChange() throws {
        let linearFee = LinearFee(constant: 1, coefficient: 0)
        let config = TransactionBuilderConfig(
            fee_algo: linearFee,
            pool_deposit: 0,
            key_deposit: 0,
            max_value_size: maxValueSize,
            max_tx_size: maxTxSize,
            coins_per_utxo_word: 1,
            prefer_pure_change: false
        )
        var txBuilder = try TransactionBuilder(config: config)
        let spend = try rootKey15()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 0)
            .derive(index: 0)
            .publicKey()
        let changeKey = try rootKey15()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 1)
            .derive(index: 0)
            .publicKey()
        let stake = try rootKey15()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 2)
            .derive(index: 0)
            .publicKey()
        let policyId = try PolicyID(bytes: Data(repeating: 0, count: 28))
        let name = try AssetName(name: Data([0, 1, 2, 3]))
        let maInput1 = 100
        let maInput2 = 200
        let maOutput1 = 60
        let multiassets = [maInput1, maInput2, maOutput1].map { [policyId: [name: UInt64($0)]] }
        for (multiasset, ada) in zip(multiassets, [UInt64(100), 100]) {
            var inputAmount = Value(coin: ada)
            inputAmount.multiasset = multiasset
            try txBuilder.addKeyInput(
                hash: spend.toRawKey().hash(),
                input: TransactionInput(transaction_id: genesisId(), index: 0),
                amount: inputAmount
            )
        }
        let spendCred = try StakeCredential.keyHash(spend.toRawKey().hash())
        let stakeCred = try StakeCredential.keyHash(stake.toRawKey().hash())
        let addrNet0 = BaseAddress(
            network: NetworkInfo.testnet.network_id,
            payment: spendCred,
            stake: stakeCred
        ).toAddress()
        var outputAmount = Value(coin: 100)
        outputAmount.multiasset = multiassets[2]
        try txBuilder.addOutput(output: TransactionOutput(address: addrNet0, amount: outputAmount))
        let changeCred = StakeCredential.keyHash(try changeKey.toRawKey().hash())
        let changeAddr = BaseAddress(
            network: NetworkInfo.testnet.network_id,
            payment: changeCred,
            stake: stakeCred
        ).toAddress()
        let addedChange = try txBuilder.addChangeIfNeeded(address: changeAddr)
        assert(addedChange)
        let finalTx = try txBuilder.build()
        XCTAssertEqual(finalTx.outputs.count, 2)
        XCTAssertEqual(finalTx.outputs[1].amount.coin, 99)
        XCTAssertEqual(finalTx.outputs[1].amount.multiasset?[policyId]?[name], UInt64(maInput1 + maInput2 - maOutput1))
    }
    
    func testBuildTxLeftoverAssets() throws {
        let linearFee = LinearFee(constant: 2, coefficient: 500)
        let config = TransactionBuilderConfig(
            fee_algo: linearFee,
            pool_deposit: 1,
            key_deposit: 1,
            max_value_size: maxValueSize,
            max_tx_size: maxTxSize,
            coins_per_utxo_word: 1,
            prefer_pure_change: false
        )
        var txBuilder = try TransactionBuilder(config: config)
        let spend = try rootKey15()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 0)
            .derive(index: 0)
            .publicKey()
        let changeKey = try rootKey15()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 1)
            .derive(index: 0)
            .publicKey()
        let stake = try rootKey15()
            .derive(index: harden(1852))
            .derive(index: harden(1815))
            .derive(index: harden(0))
            .derive(index: 2)
            .derive(index: 0)
            .publicKey()
        let spendCred = try StakeCredential.keyHash(spend.toRawKey().hash())
        let stakeCred = try StakeCredential.keyHash(stake.toRawKey().hash())
        let addrNet0 = BaseAddress(
            network: NetworkInfo.testnet.network_id,
            payment: spendCred,
            stake: stakeCred
        ).toAddress()
        let policyId = try PolicyID(bytes: Data(repeating: 0, count: 28))
        let name = try AssetName(name: Data([0, 1, 2, 3]))
        var inputAmount = Value(coin: 1_000_000)
        let inputMultiasset = [
            policyId: [name: UInt64(100)]
        ]
        inputAmount.multiasset = inputMultiasset
        try txBuilder.addKeyInput(
            hash: spend.toRawKey().hash(),
            input: TransactionInput(transaction_id: genesisId(), index: 0),
            amount: inputAmount
        )
        try txBuilder.addOutput(output: TransactionOutput(address: addrNet0, amount: Value(coin: 880_000)))
        txBuilder.ttl = 1000
        let changeCred = StakeCredential.keyHash(try changeKey.toRawKey().hash())
        let changeAddr = BaseAddress(
            network: NetworkInfo.testnet.network_id,
            payment: changeCred,
            stake: stakeCred
        ).toAddress()
        XCTAssertThrowsError(try txBuilder.addChangeIfNeeded(address: changeAddr))
    }
    
    func testBuildTxBurnLessThanMinAda() throws {
        let linearFee = LinearFee(constant: 155381, coefficient: 44)
        let config = TransactionBuilderConfig(
            fee_algo: linearFee,
            pool_deposit: 500000000,
            key_deposit: 2000000,
            max_value_size: maxValueSize,
            max_tx_size: maxTxSize,
            coins_per_utxo_word: 34_482,
            prefer_pure_change: false
        )
        var txBuilder = try TransactionBuilder(config: config)
        let outputAddr = try ByronAddress(base58: "Ae2tdPwUPEZD9QQf2ZrcYV34pYJwxK4vqXaF8EXkup1eYH73zUScHReM42b")
        try txBuilder.addOutput(
            output: TransactionOutput(address: outputAddr.toAddress(), amount: Value(coin: 2_000_000))
        )
        try txBuilder.addInput(
            address: ByronAddress(base58: "Ae2tdPwUPEZ5uzkzh1o2DHECiUi3iugvnnKHRisPgRRP3CTF4KCMvy54Xd3").toAddress(),
            input: TransactionInput(transaction_id: genesisId(), index: 0),
            amount: Value(coin: 2_400_000)
        )
        txBuilder.ttl = 1
        let changeAddr = try ByronAddress(base58: "Ae2tdPwUPEZGUEsuMAhvDcy94LKsZxDjCbgaiBBMgYpR8sKf96xJmit7Eho")
        let addedChange = try txBuilder.addChangeIfNeeded(address: changeAddr.toAddress())
        assert(!addedChange)
        XCTAssertEqual(txBuilder.outputs.count, 1)
        XCTAssertEqual(
            try txBuilder.getExplicitInput().checkedAdd(rhs: txBuilder.getImplicitInput()).coin,
            try txBuilder.getExplicitOutput().checkedAdd(rhs: Value(coin: txBuilder.fee!)).coin
        )
        XCTAssertNoThrow(try txBuilder.build())
    }
    
    func testBuildTxBurnEmptyAssets() throws {
        let linearFee = LinearFee(constant: 155381, coefficient: 44)
        let config = TransactionBuilderConfig(
            fee_algo: linearFee,
            pool_deposit: 500000000,
            key_deposit: 2000000,
            max_value_size: maxValueSize,
            max_tx_size: maxTxSize,
            coins_per_utxo_word: 34_482,
            prefer_pure_change: false
        )
        var txBuilder = try TransactionBuilder(config: config)
        let outputAddr = try ByronAddress(base58: "Ae2tdPwUPEZD9QQf2ZrcYV34pYJwxK4vqXaF8EXkup1eYH73zUScHReM42b")
        try txBuilder.addOutput(
            output: TransactionOutput(address: outputAddr.toAddress(), amount: Value(coin: 2_000_000))
        )
        var inputValue = Value(coin: 2_400_000)
        inputValue.multiasset = [:]
        try txBuilder.addInput(
            address: ByronAddress(base58: "Ae2tdPwUPEZ5uzkzh1o2DHECiUi3iugvnnKHRisPgRRP3CTF4KCMvy54Xd3").toAddress(),
            input: TransactionInput(transaction_id: genesisId(), index: 0),
            amount: inputValue
        )
        txBuilder.ttl = 1
        let changeAddr = try ByronAddress(base58: "Ae2tdPwUPEZGUEsuMAhvDcy94LKsZxDjCbgaiBBMgYpR8sKf96xJmit7Eho")
        let addedChange = try txBuilder.addChangeIfNeeded(address: changeAddr.toAddress())
        assert(!addedChange)
        XCTAssertEqual(txBuilder.outputs.count, 1)
        XCTAssertEqual(
            try txBuilder.getExplicitInput().checkedAdd(rhs: txBuilder.getImplicitInput()).coin,
            try txBuilder.getExplicitOutput().checkedAdd(rhs: Value(coin: txBuilder.fee!)).coin
        )
        XCTAssertNoThrow(try txBuilder.build())
    }
}
