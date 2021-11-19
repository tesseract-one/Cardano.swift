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
import CardanoBlockfrost
import Bip39

final class CardanoSendApiTests: XCTestCase {
    private let networkProvider = NetworkProviderMock(getSlotNumberMock: { cb in
        cb(.success(50000000))
    }, submitMock: { tx, cb in
        guard try! tx.bytes() == testTransaction.bytes() else {
            cb(.failure(ApiTestError.error(from: "submit")))
            return
        }
        cb(.success(testTransactionHash))
    })
    
    private let signatureProvider = SignatureProviderMock(signMock: { tx, cb in
        cb(.success(testTransaction))
    })
    
    private let addressManager = AddressManagerMock(newMock: { account, change in
        guard account == testAccount, change else {
            throw ApiTestError.error(from: "new")
        }
        return testChangeAddress
    }, getCachedMock: { account in
        guard account == testAccount else {
            throw ApiTestError.error(from: "get cached")
        }
        return [testExtendedAddress.address]
    }, extendedMock: { addresses in
        [testExtendedAddress]
    })
    
    private let utxoProvider = UtxoProviderMock(utxoIteratorNextMock: { cb in
        cb(.success([testUtxo]), nil)
    })
    
    private static let testMnemonic = try! Mnemonic()
    
    private static var testAccount: Account {
        let keychain = try! Keychain(mnemonic: testMnemonic.mnemonic(), password: Data())
        return try! keychain.addAccount(index: 0)
    }
    
    private static var testToAddress: Address {
        let keychain = try! Keychain(mnemonic: testMnemonic.mnemonic(), password: Data())
        let account = try! keychain.addAccount(index: 1)
        return try! account.baseAddress(
            index: 0,
            change: false,
            networkID: NetworkInfo.testnet.network_id
        ).address
    }
    
    private static var testExtendedAddress: ExtendedAddress {
        try! testAccount.baseAddress(
            index: 0,
            change: false,
            networkID: NetworkInfo.testnet.network_id
        )
    }
    
    private static var testChangeAddress: Address {
        try! testAccount.baseAddress(
            index: 1,
            change: true,
            networkID: NetworkInfo.testnet.network_id
        ).address
    }
    
    private static let testUtxo = TransactionUnspentOutput(
        input: TransactionInput(
            transaction_id: TransactionHash(),
            index: 1
        ),
        output: TransactionOutput(
            address: testExtendedAddress.address,
            amount: Value(coin: 10000000)
        )
    )
    
    private static let testTransactionHash = try! TransactionHash(bytes: Data(repeating: 0, count: 32))
    
    private static let testTransaction = Transaction(
        body: TransactionBody(inputs: [], outputs: [], fee: 0, ttl: nil),
        witnessSet: TransactionWitnessSet(),
        auxiliaryData: nil
    )
    
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
            let amountSent: UInt64 = 10000000
            let change = try! cardano.addresses.new(for: account, change: true)
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
                            let balanceTo = try! res.get()
                            XCTAssertEqual(balanceTo, amountSent)
                            sent.fulfill()
                        }
                    }
                }
            }
        }
        wait(for: [sent], timeout: 300)
    }
    
    func testSendAdaFromAccount() throws {
        let success = expectation(description: "success")
        let cardano = try Cardano(
            info: .testnet,
            signer: signatureProvider,
            network: networkProvider,
            addresses: addressManager,
            utxos: utxoProvider
        )
        cardano.send.ada(to: Self.testToAddress, lovelace: 1000000, from: Self.testAccount) { res in
            let transactionHash = try! res.get()
            XCTAssertEqual(transactionHash, Self.testTransactionHash)
            success.fulfill()
        }
        wait(for: [success], timeout: 10)
    }
    
    func testSendAdaFromAddresses() throws {
        let success = expectation(description: "success")
        let cardano = try Cardano(
            info: .testnet,
            signer: signatureProvider,
            network: networkProvider,
            addresses: addressManager,
            utxos: utxoProvider
        )
        cardano.send.ada(to: Self.testToAddress,
                         lovelace: 1000000,
                         from: [Self.testExtendedAddress.address],
                         change: Self.testChangeAddress) { res in
            let transactionHash = try! res.get()
            XCTAssertEqual(transactionHash, Self.testTransactionHash)
            success.fulfill()
        }
        wait(for: [success], timeout: 10)
    }
}
