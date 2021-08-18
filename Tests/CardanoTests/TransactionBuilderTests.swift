//
//  TransactionBuilderTests.swift
//  
//
//  Created by Ostap Danylovych on 27.07.2021.
//

import Foundation
import XCTest
@testable import Cardano

final class TransactionBuilderTests: XCTestCase {
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
    
    func testTransactionBuilder() throws {
        let _ = Cardano()
        let data28 = Data(repeating: 1, count: 28)
        let data32 = Data(repeating: 1, count: 32)
        let linearFee = try LinearFee(coefficient: 1, constant: 2)
        var transactionBuilder = try TransactionBuilder(
            linearFee: linearFee,
            minimumUtxoVal: 1,
            poolDeposit: 2,
            keyDeposit: 3
        )
        transactionBuilder.fee = 1
        transactionBuilder.ttl = 2
        try transactionBuilder.setCerts(
            certs: [
                Certificate.genesisKeyDelegation(
                    GenesisKeyDelegation(
                        genesishash: GenesisHash(bytes: data28),
                        genesis_delegate_hash: GenesisDelegateHash(bytes: data28),
                        vrf_keyhash: VRFKeyHash(bytes: data32)
                    )
                )
            ]
        )
        try transactionBuilder.setWithdrawals(
            withdrawals: [
                RewardAddress(
                    network: 1,
                    payment: StakeCredential.keyHash(Ed25519KeyHash(bytes: data28))
                ): 1
            ]
        )
        XCTAssertNoThrow(try transactionBuilder.build())
    }

    func testBuildTxWithChange() throws {
        let linearFee = try LinearFee(coefficient: 500, constant: 2)
        var txBuilder = try TransactionBuilder(linearFee: linearFee, minimumUtxoVal: 1, poolDeposit: 1, keyDeposit: 1)
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
        try txBuilder.addOutput(output: TransactionOutput(address: addrNet0, amount: Value(coin: 10)))
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
        let linearFee = try LinearFee(coefficient: 500, constant: 2)
        var txBuilder = try TransactionBuilder(linearFee: linearFee, minimumUtxoVal: 1, poolDeposit: 1, keyDeposit: 1)
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
        let linearFee = try LinearFee(coefficient: 500, constant: 2)
        var txBuilder = try TransactionBuilder(linearFee: linearFee, minimumUtxoVal: 1, poolDeposit: 1, keyDeposit: 1_000_000)
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
        XCTAssertEqual(try txBuilder.minFee(), 213502)
        XCTAssertEqual(txBuilder.fee!, 213502)
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
        let linearFee = try LinearFee(coefficient: 0, constant: 0)
        var txBuilder = try TransactionBuilder(linearFee: linearFee, minimumUtxoVal: 1, poolDeposit: 0, keyDeposit: 0)
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
        try txBuilder.addOutput(output: TransactionOutput(address: addrNet0, amount: Value(coin: 5)))
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
        let linearFee = try LinearFee(coefficient: 0, constant: 0)
        var txBuilder = try TransactionBuilder(linearFee: linearFee, minimumUtxoVal: 1, poolDeposit: 0, keyDeposit: 0)
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
            amount: Value(coin: 6)
        )
        let spendCred = try StakeCredential.keyHash(spend.toRawKey().hash())
        let stakeCred = try StakeCredential.keyHash(stake.toRawKey().hash())
        let addrNet0 = BaseAddress(
            network: NetworkInfo.testnet.network_id,
            payment: spendCred,
            stake: stakeCred
        ).toAddress()
        try txBuilder.addOutput(output: TransactionOutput(address: addrNet0, amount: Value(coin: 5)))
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
        XCTAssertEqual(finalTx.outputs[1].amount.coin, 1)
    }
    
    func testBuildTxInsufficientDeposit() throws {
        let linearFee = try LinearFee(coefficient: 0, constant: 0)
        var txBuilder = try TransactionBuilder(linearFee: linearFee, minimumUtxoVal: 1, poolDeposit: 0, keyDeposit: 5)
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
        try txBuilder.addOutput(output: TransactionOutput(address: addrNet0, amount: Value(coin: 5)))
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
        XCTAssertThrowsError(try txBuilder.addChangeIfNeeded(address: changeAddr))
    }
    
    func testBuildTxWithInputs() throws {
        let linearFee = try LinearFee(coefficient: 500, constant: 2)
        var txBuilder = try TransactionBuilder(linearFee: linearFee, minimumUtxoVal: 1, poolDeposit: 1, keyDeposit: 1)
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
        let linearFee = try LinearFee(coefficient: 0, constant: 1)
        let minimumUtxoValue: UInt64 = 1
        var txBuilder = try TransactionBuilder(
            linearFee: linearFee,
            minimumUtxoVal: minimumUtxoValue,
            poolDeposit: 0,
            keyDeposit: 0
        )
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
        for (multiasset, ada) in zip(multiassets, [UInt64(10), 10]) {
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
        var outputAmount = Value(coin: 1)
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
        XCTAssertEqual(finalTx.outputs[0].amount.coin, minimumUtxoValue)
        XCTAssertEqual(finalTx.outputs[1].amount.multiasset?[policyId]?[name], UInt64(maInput1 + maInput2 - maOutput1))
    }
    
    func testBuildTxLeftoverAssets() throws {
        let linearFee = try LinearFee(coefficient: 500, constant: 2)
        var txBuilder = try TransactionBuilder(linearFee: linearFee, minimumUtxoVal: 1, poolDeposit: 1, keyDeposit: 1)
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
        let linearFee = try LinearFee(coefficient: 44, constant: 155381)
        var txBuilder = try TransactionBuilder(
            linearFee: linearFee,
            minimumUtxoVal: 1000000,
            poolDeposit: 500000000,
            keyDeposit: 2000000
        )
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
        let linearFee = try LinearFee(coefficient: 44, constant: 155381)
        var txBuilder = try TransactionBuilder(
            linearFee: linearFee,
            minimumUtxoVal: 1000000,
            poolDeposit: 500000000,
            keyDeposit: 2000000
        )
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
