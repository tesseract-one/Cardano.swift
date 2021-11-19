//
//  CardanoBalanceApiTests.swift
//  
//
//  Created by Ostap Danylovych on 06.11.2021.
//

import Foundation
import XCTest
@testable import Cardano
import Bip39

final class CardanoBalanceApiTests: XCTestCase {
    private let networkProvider = NetworkProviderMock(getBalanceMock: { address, cb in
        guard [testAddress, testChangeAddress].contains(address) else {
            cb(.failure(ApiTestError.error(from: "getBalance")))
            return
        }
        if address == testAddress {
            cb(.success(testAmount))
        } else if address == testChangeAddress {
            cb(.success(testChangeAmount))
        }
    })
    
    private let signatureProvider = SignatureProviderMock()
    
    private let addressManager = AddressManagerMock(getCachedMock: { account in
        guard account == testAccount else {
            throw ApiTestError.error(from: "get cached account")
        }
        return [testAddress, testChangeAddress]
    }, getForAccountMock: { account, cb in
        guard account == testAccount else {
            cb(.failure(ApiTestError.error(from: "get for account")))
            return
        }
        cb(.success([testAddress, testChangeAddress]))
    })
    
    private static let testAmount: UInt64 = 100
    private static let testChangeAmount: UInt64 = 1
    private static let testMnemonic = try! Mnemonic()
    
    private static var testAccount: Account {
        let keychain = try! Keychain(mnemonic: testMnemonic.mnemonic(), password: Data())
        return try! keychain.addAccount(index: 0)
    }
    
    private static var testAddress: Address {
        try! testAccount.baseAddress(
            index: 0,
            change: false,
            networkID: NetworkInfo.testnet.network_id
        ).address
    }
    
    private static var testChangeAddress: Address {
        try! testAccount.baseAddress(
            index: 1,
            change: true,
            networkID: NetworkInfo.testnet.network_id
        ).address
    }
    
    func testAdaInAccount() throws {
        let success = expectation(description: "success")
        let cardano = try Cardano(
            info: .testnet,
            signer: signatureProvider,
            network: networkProvider,
            addresses: addressManager,
            utxos: NonCachingUtxoProvider()
        )
        cardano.balance.ada(in: Self.testAccount) { res in
            let amount = try! res.get()
            XCTAssertEqual(amount, Self.testAmount + Self.testChangeAmount)
            success.fulfill()
        }
        wait(for: [success], timeout: 10)
    }

    func testAdaInAccountUpdate() throws {
        let success = expectation(description: "success")
        let cardano = try Cardano(
            info: .testnet,
            signer: signatureProvider,
            network: networkProvider,
            addresses: addressManager,
            utxos: NonCachingUtxoProvider()
        )
        cardano.balance.ada(in: Self.testAccount, update: true) { res in
            let amount = try! res.get()
            XCTAssertEqual(amount, Self.testAmount + Self.testChangeAmount)
            success.fulfill()
        }
        wait(for: [success], timeout: 10)
    }

    func testAdaInAddress() throws {
        let success = expectation(description: "success")
        let cardano = try Cardano(
            info: .testnet,
            signer: signatureProvider,
            network: networkProvider,
            addresses: SimpleAddressManager(),
            utxos: NonCachingUtxoProvider()
        )
        cardano.balance.ada(in: Self.testAddress) { res in
            let amount = try! res.get()
            XCTAssertEqual(amount, Self.testAmount)
            success.fulfill()
        }
        wait(for: [success], timeout: 10)
    }
}
