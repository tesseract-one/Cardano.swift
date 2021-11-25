//
//  UtxoProviderTests.swift
//  
//
//  Created by Ostap Danylovych on 06.11.2021.
//

import Foundation
import XCTest
@testable import Cardano
import Bip39

final class UtxoProviderTests: XCTestCase {
    private let networkProvider = NetworkProviderMock(getUtxosForAddressesMock: { addresses, page, cb in
        guard addresses[0] == testAddress, page == 1 else {
            cb(.failure(ApiTestError.error(from: "getUtxos for addresses")))
            return
        }
        cb(.success([testUtxo]))
    }, getUtxosForTransactionMock: { transaction, cb in
        guard try! transaction.bytes() == testUtxo.input.transaction_id.bytes() else {
            cb(.failure(ApiTestError.error(from: "getUtxos for transaction")))
            return
        }
        cb(.success([testUtxo]))
    })
    
    private let signatureProvider = SignatureProviderMock()
    
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
    
    private static let testUtxo = TransactionUnspentOutput(
        input: TransactionInput(
            transaction_id: try! TransactionHash(bytes: Data(count: 32)),
            index: 1
        ),
        output: TransactionOutput(
            address: testAddress,
            amount: Value(coin: 1)
        )
    )
    
    private func getUtxos(iterator: UtxoProviderAsyncIterator,
                          all: [TransactionUnspentOutput],
                          _ cb: @escaping (Result<[TransactionUnspentOutput], Error>) -> Void) {
        iterator.next { (res, iterator) in
            switch res {
            case .success(let utxos):
                let all = all + utxos
                guard let iterator = iterator else {
                    cb(.success(all))
                    return
                }
                self.getUtxos(iterator: iterator, all: all, cb)
            case .failure(let error):
                cb(.failure(error))
            }
        }
    }
    
    func testGetForAddresses() throws {
        let success = expectation(description: "success")
        let cardano = try Cardano(
            info: .testnet,
            signer: signatureProvider,
            network: networkProvider,
            addresses: SimpleAddressManager(),
            utxos: NonCachingUtxoProvider()
        )
        getUtxos(iterator: cardano.utxos.get(for: [Self.testAddress], asset: nil), all: []) { res in
            let utxos = try! res.get()
            let utxo = utxos[0]
            XCTAssertEqual(utxo, Self.testUtxo)
            success.fulfill()
        }
        wait(for: [success], timeout: 10)
    }
    
    func testGetForTransaction() throws {
        let success = expectation(description: "success")
        let cardano = try Cardano(
            info: .testnet,
            signer: signatureProvider,
            network: networkProvider,
            addresses: SimpleAddressManager(),
            utxos: NonCachingUtxoProvider()
        )
        cardano.utxos.get(for: Self.testUtxo.input.transaction_id) { res in
            let utxos = try! res.get()
            let utxo = utxos[0]
            XCTAssertEqual(utxo, Self.testUtxo)
            success.fulfill()
        }
        wait(for: [success], timeout: 10)
    }
}
