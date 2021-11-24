//
//  TransactionBodyTests.swift
//  
//
//  Created by Ostap Danylovych on 30.07.2021.
//

import Foundation
import XCTest
#if !COCOAPODS
@testable import CardanoCore
#else
@testable import Cardano
#endif

final class TransactionBodyTests: XCTestCase {
    let initialize: Void = _initialize
    
    private let addressExample = "addr1u8pcjgmx7962w6hey5hhsd502araxp26kdtgagakhaqtq8sxy9w7g"
    
    func testTransactionBody() throws {
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
                    poolMetadataHash: PoolMetadataHash(bytes: data32)
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
        transactionBody.auxiliaryDataHash = try AuxiliaryDataHash(bytes: data32)
        transactionBody.validityStartInterval = 1
        transactionBody.mint = [
            try ScriptHash(bytes: data28): [
                try AssetName(name: data32): 1
            ]
        ]
        XCTAssertNoThrow(transactionBody.withCTransactionBody { $0 })
    }
    
}
