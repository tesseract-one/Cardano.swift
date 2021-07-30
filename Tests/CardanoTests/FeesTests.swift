//
//  FeesTests.swift
//  
//
//  Created by Ostap Danylovych on 29.07.2021.
//

import Foundation
import CryptoKit
import XCTest
@testable import Cardano

final class FeesTests: XCTestCase {
    func testTxSimpleUtxo() throws {
        let inputs = [
            TransactionInput(
                transaction_id: try TransactionHash(
                    bytes: Data(base64Encoded: "O0AmURHYuzw8YI2Vs6C/g0YazjLXkzZXmhk5s6rRwLc=")!
                ),
                index: 0
            )
        ]
        let outputs = [
            TransactionOutput(
                address: try Address(
                    bytes: Data(base64Encoded: "YRxhbxrLRgZoqbLxI8gDcsKtrTWDucbNKx3u7Rw=")!
                ),
                amount: Value(coin: 1)
            )
        ]
        let body = TransactionBody(inputs: inputs, outputs: outputs, fee: 94002, ttl: 10)
        var w = TransactionWitnessSet()
        let privateKey = try PrivateKey(
            normalBytes: Data(base64Encoded: "xmDlAxXXalPYBzLv2nYwyuiIXfuFxGN4aEs8YQPhKEo=")!
        )
        let transactionHash = try TransactionHash(bytes: Data(SHA256.hash(data: body.bytes()).map { $0 }))
        let vkw = [
            Vkeywitness(
                vkey: Vkey(_0: try privateKey.toPublic()),
                signature: try privateKey.sign(message: transactionHash.bytes())
            )
        ]
        w.vkeys = vkw
        let signedTx = Transaction(
            body: body,
            witnessSet: w,
            metadata: nil
        )
        let linearFee = try LinearFee(coefficient: 500, constant: 2)
        XCTAssertEqual(
            try signedTx.bytes().base64EncodedString(),
            "g6QAgYJYIDtAJlER2Ls8PGCNlbOgv4NGGs4y15M2V5oZObOq0cC3AAGBglgdYRxhbxrLRgZoqbLxI8gDcsKtrTWDucbNKx3u7RwBAhoAAW8yAwqhAIGCWCD5qj/Mt/5TnkcRiMzJ7mVRTFlhwHCwbKGFliSEpIE77lhA+uXeQMlNdZzhO/mIYmIVnE8moon9GS4WWZW3hSWeUD9oh78536I6R88WN4TG7uI/YUQOdJvB3zxzl19SMa7aD/Y="
        )
        let minFee = UInt64(try signedTx.bytes().count) * linearFee.coefficient + linearFee.constant
        XCTAssertEqual(minFee, 94002)
    }
}
