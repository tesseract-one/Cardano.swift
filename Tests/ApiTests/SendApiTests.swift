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
        let sent = expectation(description: "Ada sent")
        let info = NetworkApiInfo(
            networkId: NetworkId(123),
            linearFee: try LinearFee(coefficient: 0, constant: 0),
            minimumUtxoVal: 0,
            poolDeposit: 0,
            keyDeposit: 0
        )
        let addresses = SimpleAddressManager()
        let utxos = NonCachingUtxoProvider()
        let signer = SimpleSignatureProvider()
        let blockfrostConfig = BlockfrostConfig(
            basePath: "https://cardano-testnet.blockfrost.io/api/v0"
        )
        let network = BlockfrostNetworkProvider(config: blockfrostConfig)
        let cardano = try Cardano(
            info: info,
            addresses: addresses,
            utxos: utxos,
            signer: signer,
            network: network
        )
        let send = try CardanoSendApi(cardano: cardano)
        cardano.addresses.accounts { res in
            switch res {
            case .success(let accounts):
                do {
                    let account = accounts[0]
                    let address = try cardano.addresses.new(for: account, change: false)
                    let to = try Address(
                        bech32: "addr1u8pcjgmx7962w6hey5hhsd502araxp26kdtgagakhaqtq8sxy9w7g"
                    )
                    send.ada(to: to, amount: 1, from: [address]) { res in
                        switch res {
                        case .success(let transactionHash):
                            assert(!transactionHash.isEmpty)
                            sent.fulfill()
                        case .failure:
                            break
                        }
                    }
                } catch {
                    break
                }
            case .failure:
                break
            }
        }
        wait(for: [sent], timeout: 10)
    }
}
