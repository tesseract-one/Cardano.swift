//
//  KeychainTests.swift
//  
//
//  Created by Ostap Danylovych on 06.11.2021.
//

import Foundation
import XCTest
@testable import Cardano
import Bip39

final class KeychainTests: XCTestCase {
    func testInit() throws {
        let mnemonic = try Mnemonic()
        let keychain = try Keychain(mnemonic: mnemonic.mnemonic(), password: Data())
        assert(keychain.accounts().isEmpty)
    }
    
    func testAddAccount() throws {
        let mnemonic = try Mnemonic()
        let keychain = try Keychain(mnemonic: mnemonic.mnemonic(), password: Data())
        let account = try keychain.addAccount(index: 0)
        XCTAssertEqual(try keychain.account(index: 0), account)
    }
    
    func testAccounts() throws {
        let mnemonic = try Mnemonic()
        let keychain = try Keychain(mnemonic: mnemonic.mnemonic(), password: Data())
        let account = try keychain.addAccount(index: 0)
        keychain.accounts { res in
            let accounts = try! res.get()
            XCTAssertEqual(accounts[0], account)
        }
    }
    
    func testSign() throws {
        let success = expectation(description: "success")
        let mnemonic = try Mnemonic()
        let keychain = try Keychain(mnemonic: mnemonic.mnemonic(), password: Data())
        let account = try keychain.addAccount(index: 0)
        let address = try account.baseAddress(
            index: 0,
            change: false,
            networkID: NetworkInfo.testnet.network_id
        )
        let extendedTransaction = ExtendedTransaction(
            tx: TransactionBody(
                inputs: [],
                outputs: [],
                fee: 0,
                ttl: nil
            ),
            addresses: [address],
            auxiliaryData: nil
        )
        let root = try KeyPair(sk: try Bip32PrivateKey(bip39: Data(mnemonic.entropy), password: Data()))
        let path = try Bip32Path
            .prefix
            .appending(0, hard: true)
        let keyPair = try root
            .derive(index: path.purpose!)
            .derive(index: path.coin!)
            .derive(index: path.accountIndex!)
            .derive(index: 0)
            .derive(index: 0)
        keychain.sign(tx: extendedTransaction) { res in
            let transaction = try! res.get()
            XCTAssertEqual(try! transaction.body.bytes(), try! extendedTransaction.tx.bytes())
            let expectedWitness = try! keyPair.vkeyWitness(
                transactionHash: try! TransactionHash(txBody: transaction.body)
            )
            let actualWitness = transaction.witnessSet.vkeys![0]
            XCTAssertEqual(try! actualWitness.bytes(), try! expectedWitness.bytes())
            success.fulfill()
        }
        wait(for: [success], timeout: 10)
    }
}
