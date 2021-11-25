//
//  AddressManagerTests.swift
//
//
//  Created by Ostap Danylovych on 06.11.2021.
//

import XCTest
@testable import Cardano
import Bip39

final class AddressManagerTests: XCTestCase {
    private let networkProvider = NetworkProviderMock(getTransactionCountMock: { address, cb in
        guard address == testAddress.address || address == testChangeAddress.address else {
            cb(.success(0))
            return
        }
        cb(.success(1))
    })
    
    private let networkProviderTestNew = NetworkProviderMock(getTransactionCountMock: { address, cb in
        cb(.success(0))
    })
    
    private let signatureProvider = SignatureProviderMock()
    
    private let signatureProviderWithAccounts = SignatureProviderMock(accountsMock: { cb in
        cb(.success([testAccount]))
    })
    
    private static let testMnemonic = try! Mnemonic()
    
    private static var testAccount: Account {
        let keychain = try! Keychain(mnemonic: testMnemonic.mnemonic(), password: Data())
        return try! keychain.addAccount(index: 0)
    }
    
    private static var testAddress: ExtendedAddress {
        try! testAccount.baseAddress(
            index: 0,
            change: false,
            networkID: NetworkInfo.testnet.network_id
        )
    }
    
    private static var testChangeAddress: ExtendedAddress {
        try! testAccount.baseAddress(
            index: 0,
            change: true,
            networkID: NetworkInfo.testnet.network_id
        )
    }
    
    func testAccounts() throws {
        let success = expectation(description: "success")
        let cardano = try Cardano(
            info: .testnet,
            signer: signatureProviderWithAccounts,
            network: networkProvider,
            addresses: SimpleAddressManager(),
            utxos: NonCachingUtxoProvider()
        )
        cardano.addresses.accounts { res in
            let accounts = try! res.get()
            XCTAssertEqual(accounts, [Self.testAccount])
            success.fulfill()
        }
        wait(for: [success], timeout: 10)
    }
    
    func testNew() throws {
        let success = expectation(description: "success")
        let cardano = try Cardano(
            info: .testnet,
            signer: signatureProviderWithAccounts,
            network: networkProviderTestNew,
            addresses: SimpleAddressManager(),
            utxos: NonCachingUtxoProvider()
        )
        cardano.addresses.accounts { res in
            let accounts = try! res.get()
            cardano.addresses.fetch(for: accounts) { res in
                try! res.get()
                do {
                    let address = try cardano.addresses.new(for: accounts[0], change: false)
                    XCTAssertEqual(address, Self.testAddress.address)
                    success.fulfill()
                } catch {
                    XCTFail(error.localizedDescription)
                }
            }
        }
        wait(for: [success], timeout: 10)
    }
    
    func testGetCached() throws {
        let success = expectation(description: "success")
        let cardano = try Cardano(
            info: .testnet,
            signer: signatureProviderWithAccounts,
            network: networkProvider,
            addresses: SimpleAddressManager(),
            utxos: NonCachingUtxoProvider()
        )
        cardano.addresses.accounts { res in
            let accounts = try! res.get()
            cardano.addresses.fetch(for: accounts) { res in
                try! res.get()
                do {
                    let addresses = try cardano.addresses.get(cached: accounts[0])
                    XCTAssertEqual(addresses, [
                        Self.testAddress.address,
                        Self.testChangeAddress.address
                    ])
                    success.fulfill()
                } catch {
                    XCTFail(error.localizedDescription)
                }
            }
        }
        wait(for: [success], timeout: 10)
    }
    
    func testGet() throws {
        let success = expectation(description: "success")
        let cardano = try Cardano(
            info: .testnet,
            signer: signatureProviderWithAccounts,
            network: networkProvider,
            addresses: SimpleAddressManager(),
            utxos: NonCachingUtxoProvider()
        )
        cardano.addresses.accounts { res in
            let accounts = try! res.get()
            cardano.addresses.get(for: accounts[0]) { res in
                let addresses = try! res.get()
                XCTAssertEqual(addresses, [
                    Self.testAddress.address,
                    Self.testChangeAddress.address
                ])
                success.fulfill()
            }
        }
        wait(for: [success], timeout: 10)
    }
    
    func testFetch() throws {
        let success = expectation(description: "success")
        let cardano = try Cardano(
            info: .testnet,
            signer: signatureProviderWithAccounts,
            network: networkProvider,
            addresses: SimpleAddressManager(),
            utxos: NonCachingUtxoProvider()
        )
        cardano.addresses.accounts { res in
            let accounts = try! res.get()
            cardano.addresses.fetch(for: accounts) { res in
                try! res.get()
                XCTAssertEqual(cardano.addresses.fetchedAccounts(), accounts)
                do {
                    let addresses = try cardano.addresses.get(cached: accounts[0])
                    XCTAssertEqual(addresses, [
                        Self.testAddress.address,
                        Self.testChangeAddress.address
                    ])
                    success.fulfill()
                } catch {
                    XCTFail(error.localizedDescription)
                }
            }
        }
        wait(for: [success], timeout: 10)
    }
    
    func testExtended() throws {
        let success = expectation(description: "success")
        let cardano = try Cardano(
            info: .testnet,
            signer: signatureProviderWithAccounts,
            network: networkProviderTestNew,
            addresses: SimpleAddressManager(),
            utxos: NonCachingUtxoProvider()
        )
        cardano.addresses.accounts { res in
            let accounts = try! res.get()
            cardano.addresses.fetch(for: accounts) { res in
                try! res.get()
                do {
                    let address = try cardano.addresses.new(for: accounts[0], change: false)
                    let extended = try cardano.addresses.extended(addresses: [address])
                    XCTAssertEqual(extended, [Self.testAddress])
                    success.fulfill()
                } catch {
                    XCTFail(error.localizedDescription)
                }
            }
        }
        wait(for: [success], timeout: 10)
    }
}
