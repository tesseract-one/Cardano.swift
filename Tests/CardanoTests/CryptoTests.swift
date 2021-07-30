//
//  CryptoTests.swift
//  
//
//  Created by Ostap Danylovych on 30.07.2021.
//

import Foundation
import XCTest
@testable import Cardano

final class CryptoTests: XCTestCase {
    private func newBip32PrivateKey() throws -> Bip32PrivateKey {
        let entropy: [UInt8] = [0x0c, 0xcb, 0x74, 0xf3, 0x6b, 0x7d, 0xa1, 0x64, 0x9a, 0x81, 0x44, 0x67, 0x55, 0x22, 0xd4, 0xd8, 0x09, 0x7c, 0x64, 0x12];
        return try Bip32PrivateKey(bip39: Data(entropy), password: Data([]))
    }
    
    func testXprv128Test() throws {
        let rootKey = try newBip32PrivateKey()
        XCTAssertEqual(
            try rootKey.bytes().base64EncodedString(),
            "uPK+zpvf4rAoL1utcFVirJlu+2r5a2SPREXsRPR62VwQ49cvJu0HVCKjbthYXHRaDhFQvM66I1fQWGNpkfOKN5HiSN5QnAcNgSqy/aV4YKyHa8SJGSwe9M4lPBl+4hmk"
        )
        let xprv128 = try rootKey.to128Xprv()
        XCTAssertEqual(
            xprv128.base64EncodedString(),
            "uPK+zpvf4rAoL1utcFVirJlu+2r5a2SPREXsRPR62VwQ49cvJu0HVCKjbthYXHRaDhFQvM66I1fQWGNpkfOKN892OZohDehyDp+olOReQeKatSXjC8QCgBwHYlDRWFvNkeJI3lCcBw2BKrL9pXhgrIdrxIkZLB70ziU8GX7iGaQ="
        )
        let rootKeyCopy = try Bip32PrivateKey(xprv128: xprv128)
        XCTAssertEqual(try rootKey.bech32(), try rootKeyCopy.bech32())
    }
    
    func testChaincodeGen() throws {
        let chaincode = "keJI3lCcBw2BKrL9pXhgrIdrxIkZLB70ziU8GX7iGaQ="
        let rootKey = try newBip32PrivateKey()
        let prvChaincode = try rootKey.chaincode()
        XCTAssertEqual(prvChaincode.base64EncodedString(), chaincode)
        let pubChaincode = try rootKey.publicKey().chaincode()
        XCTAssertEqual(pubChaincode.base64EncodedString(), chaincode)
    }
}
