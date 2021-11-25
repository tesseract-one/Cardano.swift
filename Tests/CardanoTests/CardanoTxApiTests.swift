//
//  CardanoTxApiTests.swift
//  
//
//  Created by Ostap Danylovych on 06.11.2021.
//

import Foundation
import XCTest
@testable import Cardano
import Bip39

final class CardanoTxApiTests: XCTestCase {
    private let networkProvider = NetworkProviderMock(getTransactionMock: { hash, cb in
        guard hash == testTransactionHash else {
            cb(.success(nil))
            return
        }
        cb(.success(testChainTransaction))
    }, submitMock: { tx, cb in
        guard try! tx.bytes() == testTransaction.bytes() else {
            return
        }
        cb(.success(testTransactionHash))
    })
    
    private let signatureProvider = SignatureProviderMock(signMock: { tx, cb in
        guard try! tx.tx.bytes() == testTransaction.body.bytes(),
              tx.addresses[0] == testExtendedAddress else {
            return
        }
        cb(.success(testTransaction))
    })
    
    private let addressManager = AddressManagerMock(extendedMock: { addresses in
        let address = addresses[0]
        guard address == testAddress else {
            throw ApiTestError.error(from: "extended")
        }
        return [testExtendedAddress]
    })
    
    private static let testMnemonic = try! Mnemonic()
    
    private static var testAddress: Address {
        let keychain = try! Keychain(mnemonic: testMnemonic.mnemonic(), password: Data())
        let account = try! keychain.addAccount(index: 0)
        return try! account.baseAddress(
            index: 0,
            change: false,
            networkID: NetworkInfo.testnet.network_id
        ).address
    }
    
    private static let testExtendedAddress = ExtendedAddress(
        address: testAddress,
        path: Bip32Path.prefix
    )
    
    private static let testTransactionHash = try! TransactionHash(bytes: Data(count: 32))
    private static let testChainTransaction = ChainTransaction(
        hash: testTransactionHash.hex,
        block: "",
        blockHeight: 0,
        slot: 0,
        index: 0,
        outputAmount: [],
        fees: "",
        deposit: "",
        size: 0,
        invalidBefore: nil,
        invalidHereafter: nil,
        utxoCount: 0,
        withdrawalCount: 0,
        mirCertCount: 0,
        delegationCount: 0,
        stakeCertCount: 0,
        poolUpdateCount: 0,
        poolRetireCount: 0,
        assetMintOrBurnCount: 0,
        redeemerCount: 0
    )
    private static let testTransaction = Transaction(
        body: TransactionBody(inputs: [], outputs: [], fee: 0, ttl: nil),
        witnessSet: TransactionWitnessSet(),
        auxiliaryData: nil
    )
    
    func testGetTransaction() throws {
        let success = expectation(description: "success")
        let cardano = try Cardano(
            info: .testnet,
            signer: signatureProvider,
            network: networkProvider,
            addresses: SimpleAddressManager(),
            utxos: NonCachingUtxoProvider()
        )
        cardano.tx.get(hash: Self.testTransactionHash) { res in
            let chainTransaction = try! res.get()
            XCTAssertEqual(chainTransaction, Self.testChainTransaction)
            success.fulfill()
        }
        wait(for: [success], timeout: 10)
    }
    
    func testSubmit() throws {
        let success = expectation(description: "success")
        let cardano = try Cardano(
            info: .testnet,
            signer: signatureProvider,
            network: networkProvider,
            addresses: SimpleAddressManager(),
            utxos: NonCachingUtxoProvider()
        )
        cardano.tx.submit(tx: Self.testTransaction) { res in
            let transactionHash = try! res.get()
            XCTAssertEqual(transactionHash, Self.testTransactionHash)
            success.fulfill()
        }
        wait(for: [success], timeout: 10)
    }
    
    func testSignAndSubmit() throws {
        let success = expectation(description: "success")
        let cardano = try Cardano(
            info: .testnet,
            signer: signatureProvider,
            network: networkProvider,
            addresses: addressManager,
            utxos: NonCachingUtxoProvider()
        )
        cardano.tx.signAndSubmit(
            tx: Self.testTransaction.body,
            with: [Self.testAddress],
            auxiliaryData: nil
        ) { res in
            let transactionHash = try! res.get()
            XCTAssertEqual(transactionHash, Self.testTransactionHash)
            success.fulfill()
        }
        wait(for: [success], timeout: 10)
    }
}
