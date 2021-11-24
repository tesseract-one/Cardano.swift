//
//  MetadataTests.swift
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

final class MetadataTests: XCTestCase {
    let initialize: Void = _initialize
    
    private func jsonEncodingCheckExampleMetadatum(metadata: TransactionMetadatum) throws {
        let map = metadata.map!
        XCTAssertEqual(
            map[try TransactionMetadatum.newBytes(bytes: Data(hex: "8badf00d")!)]?.bytes, Data(hex: "deadbeef")!
        )
        XCTAssertEqual(map.getI32(key: 9)!.int, 5)
        let innerMap = try map.getStr(key: "obj")!.map!
        let a = try innerMap.getStr(key: "a")!.list!
        let a1 = a[0].map!
        XCTAssertEqual(a1.getI32(key: 5)!.int, 2)
        let a2 = a[1].map!
        XCTAssertEqual(a2.keys.count, 0)
    }
    
    func testBinaryEncoding() throws {
        var bytesRange = [UInt8]()
        for int in 0...255 {
            bytesRange.append(UInt8(int))
        }
        let inputBytes = Data(bytesRange)
        let metadata = try TransactionMetadatum(arbitraryBytes: inputBytes)
        let outputBytes = try metadata.arbitraryBytes()
        XCTAssertEqual(inputBytes, outputBytes)
    }
    
    func testJsonEncodingNoConversions() throws {
        let inputStr = "{\"receiver_id\": \"SJKdj34k3jjKFDKfjFUDfdjkfd\",\"sender_id\": \"jkfdsufjdk34h3Sdfjdhfduf873\",\"comment\": \"happy birthday\",\"tags\": [0, 264, -1024, 32]}"
        let metadata = try TransactionMetadatum(
            json: inputStr, schema: MetadataJsonSchema.noConversions
        )
        let map = metadata.map!
        XCTAssertEqual(try map.getStr(key: "receiver_id")!.text, "SJKdj34k3jjKFDKfjFUDfdjkfd")
        XCTAssertEqual(try map.getStr(key: "sender_id")!.text, "jkfdsufjdk34h3Sdfjdhfduf873")
        XCTAssertEqual(try map.getStr(key: "comment")!.text, "happy birthday")
        let tags = try map.getStr(key: "tags")!.list!
        let tagsI32 = tags.map { Int32($0.int!) }
        XCTAssertEqual(tagsI32, [0, 264, -1024, 32])
        let outputStr = try metadata.json(schema: MetadataJsonSchema.noConversions)
        let inputJson = try JsonValue(s: inputStr)
        let outputJson = try JsonValue(s: outputStr)
        XCTAssertEqual(inputJson, outputJson)
    }
    
    func testJsonEncodingBasic() throws {
        let inputStr = "{\"0x8badf00d\": \"0xdeadbeef\",\"9\": 5,\"obj\": {\"a\":[{\"5\": 2},{}]}}"
        let metadata = try TransactionMetadatum(
            json: inputStr, schema: MetadataJsonSchema.basicConversions
        )
        try jsonEncodingCheckExampleMetadatum(metadata: metadata)
        let outputStr = try metadata.json(schema: MetadataJsonSchema.basicConversions)
        let inputJson = try JsonValue(s: inputStr)
        let outputJson = try JsonValue(s: outputStr)
        XCTAssertEqual(inputJson, outputJson)
    }
    
    func testJsonEncodingDetailed() throws {
        let inputStr = "{\"map\":[" +
            "{" +
                "\"k\":{\"bytes\":\"8badf00d\"}," +
                "\"v\":{\"bytes\":\"deadbeef\"}" +
            "}," +
            "{" +
                "\"k\":{\"int\":9}," +
                "\"v\":{\"int\":5}" +
            "}," +
            "{" +
                "\"k\":{\"string\":\"obj\"}," +
                "\"v\":{\"map\":[" +
                    "{" +
                        "\"k\":{\"string\":\"a\"}," +
                        "\"v\":{\"list\":[" +
                        "{\"map\":[" +
                            "{" +
                                "\"k\":{\"int\":5}," +
                                "\"v\":{\"int\":2}" +
                            "}" +
                            "]}," +
                            "{\"map\":[" +
                            "]}" +
                        "]}" +
                    "}" +
                "]}" +
            "}" +
        "]}"
        let metadata = try TransactionMetadatum(
            json: inputStr, schema: MetadataJsonSchema.detailedSchema
        )
        try jsonEncodingCheckExampleMetadatum(metadata: metadata)
        let outputStr = try metadata.json(schema: MetadataJsonSchema.detailedSchema)
        let inputJson = try JsonValue(s: inputStr)
        let outputJson = try JsonValue(s: outputStr)
        XCTAssertEqual(inputJson, outputJson)
    }
    
    func testJsonEncodingDetailedComplexKey() throws {
        let inputStr = "{\"map\":[" +
            "{" +
            "\"k\":{\"list\":[" +
                "{\"map\": [" +
                    "{" +
                        "\"k\": {\"int\": 5}," +
                        "\"v\": {\"int\": -7}" +
                    "}," +
                    "{" +
                        "\"k\": {\"string\": \"hello\"}," +
                        "\"v\": {\"string\": \"world\"}" +
                    "}" +
                "]}," +
                "{\"bytes\": \"ff00ff00\"}" +
            "]}," +
            "\"v\":{\"int\":5}" +
            "}" +
        "]}"
        let metadata = try TransactionMetadatum(
            json: inputStr, schema: MetadataJsonSchema.detailedSchema
        )
        let map = metadata.map!
        let key = Array(map.keys)[0]
        XCTAssertEqual(map[key]?.int, 5)
        let keyList = key.list!
        XCTAssertEqual(keyList.count, 2)
        let keyMap = keyList[0].map!
        XCTAssertEqual(Int32(keyMap.getI32(key: 5)!.int!), -7)
        XCTAssertEqual(try keyMap.getStr(key: "hello")!.text, "world")
        let keyBytes = keyList[1].bytes
        XCTAssertEqual(keyBytes, Data(hex: "ff00ff00"))
        let outputStr = try metadata.json(schema: MetadataJsonSchema.detailedSchema)
        let inputJson = try JsonValue(s: inputStr)
        let outputJson = try JsonValue(s: outputStr)
        XCTAssertEqual(inputJson, outputJson)
    }
}
