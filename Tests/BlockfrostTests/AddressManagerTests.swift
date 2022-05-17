//
//  AddressManagerTests.swift
//  
//
//  Created by Ostap Danylovych on 06.11.2021.
//

import Foundation
import XCTest
@testable import Cardano
import BlockfrostSwiftSDK
import Bip39
#if !COCOAPODS
@testable import CardanoBlockfrost
#endif


final class AddressManagerTests: XCTestCase {
    private let signatureProvider = SignatureProviderMock()
    
    func testFetchOnTestnet() throws {
        let fetchSuccessful = expectation(description: "Fetch successful")
        let cardano = try Cardano(
            blockfrost: TestEnvironment.instance.blockfrostProjectId,
            info: .testnet,
            signer: signatureProvider
        )
        let account = Account(publicKey: TestEnvironment.instance.publicKey, index: 0)
        var testAddresses = (0..<45).map {
            try! account.baseAddress(index: $0,
                                     change: false,
                                     networkID: cardano.info.networkID).address
        }
        let changeAddresses = (0..<4).map {
            try! account.baseAddress(index: $0,
                                     change: true,
                                     networkID: cardano.info.networkID).address
        }
        testAddresses.append(contentsOf: changeAddresses)
        cardano.addresses.fetch(for: [account]) { res in
            try! res.get()
            let addresses = try! cardano.addresses.get(cached: account)
            XCTAssertEqual(testAddresses, addresses)
            fetchSuccessful.fulfill()
        }
        wait(for: [fetchSuccessful], timeout: 100)
    }
}
