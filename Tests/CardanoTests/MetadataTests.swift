//
//  MetadataTests.swift
//  
//
//  Created by Ostap Danylovych on 30.07.2021.
//

import Foundation
import XCTest
@testable import Cardano

final class MetadataTests: XCTestCase {
    func testAllegraMetadata() throws {
        let gmd = [UInt64(100): TransactionMetadatum.text("string md")]
        let md1 = TransactionMetadata(general: gmd)
        let md1Deser = try TransactionMetadata(bytes: md1.bytes())
        XCTAssertEqual(try md1.bytes(), try md1Deser.bytes())
        var md2 = TransactionMetadata(general: gmd)
        let scripts = [
            NativeScript.timelockStart(TimelockStart(slot: 20))
        ]
        md2.nativeScripts = scripts
        let md2Deser = try TransactionMetadata(bytes: md2.bytes())
        XCTAssertEqual(try md2.bytes(), try md2Deser.bytes())
    }
}
