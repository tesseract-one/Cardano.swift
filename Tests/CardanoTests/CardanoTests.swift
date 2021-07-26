import XCTest
@testable import Cardano

final class CardanoTests: XCTestCase {
    let publicKeyExample = "ed25519_pk1dgaagyh470y66p899txcl3r0jaeaxu6yd7z2dxyk55qcycdml8gszkxze2"
    let addressExample = "addr1u8pcjgmx7962w6hey5hhsd502araxp26kdtgagakhaqtq8sxy9w7g"
    
    func testInit() {
        let _ = Cardano()
    }
    
    func testLinearFee() throws {
        let _ = Cardano()
        let linearFee = try LinearFee(coefficient: 1, constant: 2)
        XCTAssertEqual(1, linearFee.coefficient)
        XCTAssertEqual(2, linearFee.constant)
    }
    
    func testValue() throws {
        let _ = Cardano()
        let v1 = Value(coin: 1)
        let v2 = Value(coin: 2)
        let added = try v1.checkedAdd(rhs: v2)
        XCTAssertEqual(added.coin, 3)
    }
    
    func testTransactionBody() throws {
        let _ = Cardano()
        let data28 = Data(repeating: 1, count: 28)
        let data32 = Data(repeating: 1, count: 32)
        let inputs = [
            TransactionInput(transaction_id: try TransactionHash(bytes: data32), index: 1)
        ]
        let outputs = [
            TransactionOutput(
                address: try Address(bech32: addressExample),
                amount: Value(coin: 1)
            )
        ]
        var transactionBody = TransactionBody(
            inputs: inputs,
            outputs: outputs,
            fee: 1,
            ttl: 1
        )
        let poolRegistration = PoolRegistration(
            poolParams: try PoolParams(
                operator: Ed25519KeyHash(bytes: data28),
                vrfKeyhash: VRFKeyHash(bytes: data32),
                pledge: 1,
                cost: 1,
                margin: UnitInterval(numerator: 1, denominator: 2),
                rewardAccount: RewardAddress(
                    network: 1,
                    payment: StakeCredential.keyHash(Ed25519KeyHash(bytes: data28))
                ),
                poolOwners: [
                    Ed25519KeyHash(bytes: data28)
                ],
                relays: [
                    Relay.singleHostName(
                        SingleHostName(
                            port: 1,
                            dnsName: DNSRecordAorAAAA(dnsName: "dnsname")
                        )
                    )
                ],
                poolMetadata: PoolMetadata(
                    url: URL(url: "url"),
                    metadataHash: MetadataHash(bytes: data32)
                )
            )
        )
        let certs = [Certificate.poolRegistration(poolRegistration)]
        transactionBody.certs = certs
        let withdrawals = [
            RewardAddress(
                network: 1,
                payment: StakeCredential.keyHash(try Ed25519KeyHash(bytes: data28))
            ): UInt64(1)
        ]
        transactionBody.withdrawals = withdrawals
        let update = Update(
            proposedProtocolParameterUpdates: [
                try GenesisHash(bytes: data28): ProtocolParamUpdate()
            ], epoch: 1
        )
        transactionBody.update = update
        transactionBody.metadataHash = try MetadataHash(bytes: data32)
        transactionBody.validityStartInterval = 1
        transactionBody.mint = [
            try ScriptHash(bytes: data28): [
                try AssetName(name: data32): 1
            ]
        ]
        XCTAssertNoThrow(transactionBody.withCTransactionBody { $0 })
    }
    
    func testTransactionWitnessSet() throws {
        let _ = Cardano()
        let data = Data(repeating: 1, count: 64)
        let vkeys = [
            Vkeywitness(
                vkey: try Vkey(_0: PublicKey(bech32: publicKeyExample)),
                signature: try Ed25519Signature(data: data)
            )
        ]
        let bootstraps = [
            BootstrapWitness(
                vkey: try Vkey(_0: PublicKey(bech32: publicKeyExample)),
                signature: try Ed25519Signature(data: data),
                chainCode: data,
                attributes: data
            )
        ]
        var transactionWitnessSet = TransactionWitnessSet()
        transactionWitnessSet.vkeys = vkeys
        transactionWitnessSet.bootstraps = bootstraps
        XCTAssertNoThrow(transactionWitnessSet.vkeys?.withCArray { $0 })
        XCTAssertNoThrow(transactionWitnessSet.bootstraps?.withCArray { $0 })
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

    func testMoveInstantaneousReward() throws {
        let _ = Cardano()
        let data = Data(repeating: 1, count: 28)
        var mir = MoveInstantaneousReward(pot: MIRPot.reserves)
        mir.rewards.updateValue(1, forKey: StakeCredential.keyHash(try Ed25519KeyHash(bytes: data)))
        XCTAssertNoThrow(try mir.bytes())
    }
}
