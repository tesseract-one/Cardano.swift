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
    private func jsonEncodingCheckExampleMetadatum(metadata: TransactionMetadatum) {
        let map = metadata.map!
        XCTAssertEqual(map[TransactionMetadatum.bytes(Data(hex: "8badf00d")!)]?.bytes, Data(hex: "deadbeef")!)
        XCTAssertEqual(map.getI32(key: 9)!.int, 5)
        let innerMap = map.getStr(key: "obj")!.map!
        let a = innerMap.getStr(key: "a")!.list!
        let a1 = a[0].map!
        XCTAssertEqual(a1.getI32(key: 5)!.int, 2)
        let a2 = a[1].map!
        XCTAssertEqual(a2.keys.count, 0)
    }
    
    func testBinaryEncoding() throws {
        let intRange = Array(0...1000)
        var bytesRange = [UInt8]()
        for int in intRange {
            bytesRange.append(UInt8(int))
        }
        let inputBytes = Data(bytesRange)
        let metadata = try TransactionMetadatum(arbitraryBytes: inputBytes)
        let outputBytes = try metadata.arbitraryBytes()
        XCTAssertEqual(inputBytes, outputBytes)
    }
    
    private func jsonFromStr(str: String) -> String {
        fatalError()
    }
    
    func testJsonEncodingNoConversions() throws {
        let inputStr = "{\"receiver_id\": \"SJKdj34k3jjKFDKfjFUDfdjkfd\",\"sender_id\": \"jkfdsufjdk34h3Sdfjdhfduf873\",\"comment\": \"happy birthday\",\"tags\": [0, 264, -1024, 32]}"
        let metadata = try TransactionMetadatum(
            json: inputStr, schema: MetadataJsonSchema.noConversions
        )
        let map = metadata.map!
        XCTAssertEqual(map.getStr(key: "receiver_id")!.text, "SJKdj34k3jjKFDKfjFUDfdjkfd")
        XCTAssertEqual(map.getStr(key: "sender_id")!.text, "jkfdsufjdk34h3Sdfjdhfduf873")
        XCTAssertEqual(map.getStr(key: "comment")!.text, "happy birthday")
        let tags = map.getStr(key: "tags")!.list!
        let tagsI32 = tags.map { Int32($0.int!) }
        XCTAssertEqual(tagsI32, [0, 264, -1024, 32])
        let outputStr = try metadata.json(schema: MetadataJsonSchema.noConversions)
        let inputJson = jsonFromStr(str: inputStr)
        let outputJson = jsonFromStr(str: outputStr)
        XCTAssertEqual(inputJson, outputJson)
    }
    
    func testJsonEncodingBasic() throws {
        let inputStr = "{\"0x8badf00d\": \"0xdeadbeef\",\"9\": 5,\"obj\": {\"a\":[{\"5\": 2},{}]}}"
        let metadata = try TransactionMetadatum(
            json: inputStr, schema: MetadataJsonSchema.basicConversions
        )
        jsonEncodingCheckExampleMetadatum(metadata: metadata)
        let outputStr = try metadata.json(schema: MetadataJsonSchema.basicConversions)
        let inputJson = jsonFromStr(str: inputStr)
        let outputJson = jsonFromStr(str: outputStr)
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
        jsonEncodingCheckExampleMetadatum(metadata: metadata)
        let outputStr = try metadata.json(schema: MetadataJsonSchema.detailedSchema)
        let inputJson = jsonFromStr(str: inputStr)
        let outputJson = jsonFromStr(str: outputStr)
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
        XCTAssertEqual(keyMap.getStr(key: "hello")!.text, "world")
        let keyBytes = keyList[1].bytes
        XCTAssertEqual(keyBytes, Data(hex: "ff00ff00"))
        let outputStr = try metadata.json(schema: MetadataJsonSchema.detailedSchema)
        let inputJson = jsonFromStr(str: inputStr)
        let outputJson = jsonFromStr(str: outputStr)
        XCTAssertEqual(inputJson, outputJson)
    }
    
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
