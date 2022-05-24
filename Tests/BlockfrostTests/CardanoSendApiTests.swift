//
//  CardanoSendApiTests.swift
//  
//
//  Created by Ostap Danylovych on 02.11.2021.
//

import Foundation
import XCTest
@testable import Cardano
import BlockfrostSwiftSDK
import Bip39
#if !COCOAPODS
@testable import CardanoBlockfrost
#endif

final class CardanoSendApiTests: XCTestCase {
    private let dispatchQueue = DispatchQueue(label: "CardanoSendApiTests.Async.Queue", target: .global())
    
    private func getTransaction(cardano: Cardano,
                                transactionHash: TransactionHash,
                                _ cb: @escaping (ChainTransaction) -> Void) {
        cardano.tx.get(hash: transactionHash) { res in
            guard let chainTransaction = try! res.get() else {
                self.dispatchQueue.asyncAfter(deadline: .now() + 10) {
                    self.getTransaction(cardano: cardano, transactionHash: transactionHash, cb)
                }
                return
            }
            cb(chainTransaction)
        }
    }
    
    func testSendAdaOnTestnet() throws {
        let sent = expectation(description: "Ada sent")
        let keychain = try Keychain(
            mnemonic: TestEnvironment.instance.mnemonic,
            password: Data()
        )
        let cardano = try Cardano(
            blockfrost: TestEnvironment.instance.blockfrostProjectId,
            info: .testnet,
            signer: keychain
        )
        let account = try keychain.addAccount(index: 0)
        cardano.addresses.fetch(for: [account]) { res in
            try! res.get()
            let addresses = try! cardano.addresses.get(cached: account)
            let to = addresses.count < 100
                ? try! cardano.addresses.new(for: account, change: false)
                : addresses.randomElement()!
            let amountSent: UInt64 = 10_000_000
            let change = try! cardano.addresses.new(for: account, change: true)
            cardano.balance.ada(in: to) { res in
                let startBalance = try! res.get()
                cardano.send.ada(to: to, lovelace: amountSent, from: account, change: change) { res in
                    let transactionHash = try! res.get()
                    self.getTransaction(cardano: cardano,
                                        transactionHash: transactionHash) { chainTransaction in
                        let outputAmount = try! Value(
                            blockfrost: chainTransaction.outputAmount.map {
                                (unit: $0.unit, quantity: $0.quantity)
                            }
                        ).coin
                        cardano.balance.ada(in: change) { res in
                            let balanceChange = try! res.get()
                            XCTAssertEqual(outputAmount, amountSent + balanceChange)
                            cardano.balance.ada(in: to) { res in
                                let endBalance = try! res.get()
                                XCTAssertEqual(endBalance - startBalance, amountSent)
                                sent.fulfill()
                            }
                        }
                    }
                }
            }
        }
        wait(for: [sent], timeout: 300)
    }
}
