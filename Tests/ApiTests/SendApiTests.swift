//
//  SendApiTests.swift
//  
//
//  Created by Ostap Danylovych on 02.11.2021.
//

import Foundation
import XCTest
@testable import Cardano
import BlockfrostSwiftSDK
import CardanoBlockfrost

final class SendApiTests: XCTestCase {
    func testSendAda() throws {
        let testMnemonic = ProcessInfo.processInfo
            .environment["SendApiTests.testSendAda.testMnemonic"]!
            .components(separatedBy: " ")
        let sent = expectation(description: "Ada sent")
        let info = NetworkApiInfo(
            networkID: NetworkInfo.testnet.network_id,
            linearFee: try LinearFee(coefficient: 0, constant: 0),
            minimumUtxoVal: 0,
            poolDeposit: 0,
            keyDeposit: 0
        )
        let cardano = try Cardano(
            info: info,
            addresses: SimpleAddressManager(),
            utxos: NonCachingUtxoProvider(),
            signer: Keychain(
                mnemonic: testMnemonic,
                password: Data()
            ),
            network: BlockfrostNetworkProvider(config: BlockfrostConfig(
                basePath: "https://cardano-testnet.blockfrost.io/api/v0"
            ))
        )
        let send = try CardanoSendApi(cardano: cardano)
        cardano.addresses.accounts { res in
            let accounts = try! res.get()
            let account = accounts[0]
            cardano.addresses.fetch(for: [account]) { res in
                try! res.get()
                let addresses = try! cardano.addresses.get(cached: account)
                let from = addresses.first!
                let to = addresses.count < 100
                    ? try! cardano.addresses.new(for: account, change: false)
                    : addresses.randomElement()!
                let amount1: UInt64 = 100
                send.ada(to: to, amount: amount1, from: [from]) { res in
                    let transactionHash = try! res.get()
                    cardano.tx.get(hash: transactionHash) { res in
                        let chainTransaction = try! res.get()
                        let amount2 = try! Value(
                            blockfrost: chainTransaction.outputAmount.map {
                                (unit: $0.unit, quantity: $0.quantity)
                            }
                        ).coin
                        XCTAssertEqual(amount1, amount2)
                        sent.fulfill()
                    }
                }
            }
        }
        wait(for: [sent], timeout: 10)
    }
}
