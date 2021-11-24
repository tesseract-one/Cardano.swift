//
//  CryptoTests.swift
//  
//
//  Created by Ostap Danylovych on 30.07.2021.
//

import Foundation
import XCTest
#if !COCOAPODS
@testable import CardanoCore
#else
@testable import Cardano
#endif

final class CryptoTests: XCTestCase {
    let initialize: Void = _initialize
    
    private func newBip32PrivateKey() throws -> Bip32PrivateKey {
        let entropy: [UInt8] = [0x0c, 0xcb, 0x74, 0xf3, 0x6b, 0x7d, 0xa1, 0x64, 0x9a, 0x81, 0x44, 0x67, 0x55, 0x22, 0xd4, 0xd8, 0x09, 0x7c, 0x64, 0x12]
        return try Bip32PrivateKey(bip39: Data(entropy), password: Data([]))
    }
    
    func testNonceIdentity() throws {
        let nonce = Nonce()
        XCTAssertNoThrow(try nonce.bytes())
    }
    
    func testNonceHash() throws {
        let nonce = try Nonce(nonceHash: Data([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31]))
        XCTAssertNoThrow(try nonce.bytes())
    }
    
    func testXprv128Test() throws {
        let rootKey = try newBip32PrivateKey()
        XCTAssertEqual(
            try rootKey.bytes().hex(prefix: false),
            "b8f2bece9bdfe2b0282f5bad705562ac996efb6af96b648f4445ec44f47ad95c10e3d72f26ed075422a36ed8585c745a0e1150bcceba2357d058636991f38a3791e248de509c070d812ab2fda57860ac876bc489192c1ef4ce253c197ee219a4"
        )
        let xprv128 = try rootKey.to128Xprv()
        XCTAssertEqual(
            xprv128.hex(prefix: false),
            "b8f2bece9bdfe2b0282f5bad705562ac996efb6af96b648f4445ec44f47ad95c10e3d72f26ed075422a36ed8585c745a0e1150bcceba2357d058636991f38a37cf76399a210de8720e9fa894e45e41e29ab525e30bc402801c076250d1585bcd91e248de509c070d812ab2fda57860ac876bc489192c1ef4ce253c197ee219a4"
        )
        let rootKeyCopy = try Bip32PrivateKey(xprv128: xprv128)
        XCTAssertEqual(try rootKey.bech32(), try rootKeyCopy.bech32())
    }
    
    func testChaincodeGen() throws {
        let chaincode = "91e248de509c070d812ab2fda57860ac876bc489192c1ef4ce253c197ee219a4"
        let rootKey = try newBip32PrivateKey()
        let prvChaincode = try rootKey.chaincode()
        XCTAssertEqual(prvChaincode.hex(prefix: false), chaincode)
        let pubChaincode = try rootKey.publicKey().chaincode()
        XCTAssertEqual(pubChaincode.hex(prefix: false), chaincode)
    }
}
