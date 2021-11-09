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
import CardanoBlockfrost

final class AddressManagerTests: XCTestCase {
    private struct TestSigner: SignatureProvider {
        func accounts(_ cb: @escaping (Result<[Account], Error>) -> Void) {
        }
        
        func sign(tx: ExtendedTransaction,
                  _ cb: @escaping (Result<Transaction, Error>) -> Void) {
        }
    }
    
    func testFetch() throws {
        let testAddresses = ProcessInfo.processInfo
            .environment["AddressManagerTests.testFetch.testAddresses"]!
            .components(separatedBy: "\n")
        let publicKey = try Bip32PublicKey(bech32: "")
        let fetchSuccessful = expectation(description: "Fetch successful")
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
            signer: TestSigner(),
            network: BlockfrostNetworkProvider(config: BlockfrostConfig(
                basePath: "https://cardano-testnet.blockfrost.io/api/v0"
            ))
        )
        let account = Account(publicKey: publicKey, index: 0)
        cardano.addresses.fetch(for: [account]) { res in
            try! res.get()
            let addresses = try! cardano.addresses.get(cached: account)
            XCTAssertEqual(testAddresses, try! addresses.map { try $0.bech32() })
            fetchSuccessful.fulfill()
        }
        wait(for: [fetchSuccessful], timeout: 10)
    }
}
