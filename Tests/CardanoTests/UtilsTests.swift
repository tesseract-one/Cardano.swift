//
//  UtilsTests.swift
//  
//
//  Created by Ostap Danylovych on 06.08.2021.
//

import Foundation
import XCTest
@testable import Cardano

final class UtilsTests: XCTestCase {
    private let minimumUtxoVal: UInt64 = 1_000_000
    
    func testNoTokenMinimum() {
        let assets = Value(coin: 0)
        XCTAssertEqual(try assets.minAdaRequired(minimumUtxoVal: minimumUtxoVal), minimumUtxoVal)
    }
    
    func testOnePolicyOneSmallestName() throws {
        var assets = Value(coin: 1407406)
        assets.multiasset = [
            try PolicyID(bytes: Data(repeating: 0, count: 28)):
                [try AssetName(data: Data([])): UInt64(1)]
        ]
        XCTAssertEqual(try assets.minAdaRequired(minimumUtxoVal: minimumUtxoVal), 1407406)
    }
    
    func testOnePolicyOneSmallName() throws {
        var assets = Value(coin: 1444443)
        assets.multiasset = [
            try PolicyID(bytes: Data(repeating: 0, count: 28)):
                [try AssetName(data: Data([1])): UInt64(1)]
        ]
        XCTAssertEqual(try assets.minAdaRequired(minimumUtxoVal: minimumUtxoVal), 1444443)
    }
    
    func testOnePolicyOneLargestName() throws {
        var assets = Value(coin: 1555554)
        assets.multiasset = [
            try PolicyID(bytes: Data(repeating: 0, count: 28)):
                [try AssetName(data: Data(repeating: 1, count: 32)): UInt64(1)]
        ]
        XCTAssertEqual(try assets.minAdaRequired(minimumUtxoVal: minimumUtxoVal), 1555554)
    }
    
    func testOnePolicyThreeSmallNames() throws {
        var assets = Value(coin: 1555554)
        assets.multiasset = [
            try PolicyID(bytes: Data(repeating: 0, count: 28)):
                [
                    try AssetName(data: Data([1])): UInt64(1),
                    try AssetName(data: Data([2])): UInt64(1),
                    try AssetName(data: Data([3])): UInt64(1)
                ]
        ]
        XCTAssertEqual(try assets.minAdaRequired(minimumUtxoVal: minimumUtxoVal), 1555554)
    }
    
    func testOnePolicyThreeLargestNames() throws {
        var assets = Value(coin: 1962961)
        assets.multiasset = [
            try PolicyID(bytes: Data(repeating: 0, count: 28)):
                [
                    try AssetName(data: Data(repeating: 1, count: 32)): UInt64(1),
                    try AssetName(data: Data(repeating: 2, count: 32)): UInt64(1),
                    try AssetName(data: Data(repeating: 3, count: 32)): UInt64(1)
                ]
        ]
        XCTAssertEqual(try assets.minAdaRequired(minimumUtxoVal: minimumUtxoVal), 1962961)
    }
    
    func testTwoPoliciesOneSmallestName() throws {
        let assetList = [try AssetName(data: Data([])): UInt64(1)]
        var assets = Value(coin: 1592591)
        assets.multiasset = [
            try PolicyID(bytes: Data(repeating: 0, count: 28)): assetList,
            try PolicyID(bytes: Data(repeating: 1, count: 28)): assetList
        ]
        XCTAssertEqual(try assets.minAdaRequired(minimumUtxoVal: minimumUtxoVal), 1592591)
    }
    
    func testTwoPoliciesTwoSmallNames() throws {
        let assetList = [try AssetName(data: Data([])): UInt64(1)]
        let tokenBundle = [
            try PolicyID(bytes: Data(repeating: 0, count: 28)): assetList,
            try PolicyID(bytes: Data(repeating: 1, count: 28)): assetList
        ]
        var assets = Value(coin: 1592591)
        assets.multiasset = tokenBundle
        XCTAssertEqual(try assets.minAdaRequired(minimumUtxoVal: minimumUtxoVal), 1592591)
    }
    
    func testThreePolicies99SmallNames() throws {
        var tokenBundle = MultiAsset()
        for p: UInt8 in 1...3 {
            var assetList = Assets()
            for an: UInt8 in 0...33 {
                assetList.updateValue(UInt64(1), forKey: try AssetName(data: Data([an])))
            }
            tokenBundle.updateValue(assetList, forKey: try PolicyID(bytes: Data(repeating: p, count: 28)))
        }
        var assets = Value(coin: 7592585)
        assets.multiasset = tokenBundle
        XCTAssertEqual(try assets.minAdaRequired(minimumUtxoVal: minimumUtxoVal), 7592585)
    }
    
    func testSubtractValues() throws {
        let policy1 = try PolicyID(bytes: Data(repeating: 0, count: 28))
        let policy2 = try PolicyID(bytes: Data(repeating: 1, count: 28))
        let asset1 = try AssetName(data: Data([1]))
        let asset2 = try AssetName(data: Data([2]))
        let asset3 = try AssetName(data: Data([3]))
        let asset4 = try AssetName(data: Data([4]))
        var assets1 = Value(coin: 1555554)
        assets1.multiasset = [
            policy1: [
                asset1: UInt64(1),
                asset2: UInt64(1),
                asset3: UInt64(1),
                asset4: UInt64(2)
            ],
            policy2: [
                asset1: UInt64(1)
            ]
        ]
        var assets2 = Value(coin: 2555554)
        assets2.multiasset = [
            policy1: [
                asset1: UInt64(2),
                asset2: UInt64(1),
                asset4: UInt64(1)
            ],
            policy2: [
                asset1: UInt64(1)
            ]
        ]
        let result = try assets1.clampedSub(rhs: assets2)
        XCTAssertEqual(result.coin, 0)
        XCTAssertEqual(result.multiasset?.count, 1)
        let policy1Content = result.multiasset?[policy1]
        XCTAssertEqual(policy1Content?.count, 2)
        XCTAssertEqual(policy1Content?[asset3], 1)
        XCTAssertEqual(policy1Content?[asset4], 1)
    }
    
    func testCompareValues() throws {
        let policy1 = try PolicyID(bytes: Data(repeating: 0, count: 28))
        let asset1 = try AssetName(data: Data([1]))
        let testWithoutMultiassets = { (v1: UInt64, v2: UInt64, o: Ordering?) in
            let a = Value(coin: v1)
            let b = Value(coin: v2)
            XCTAssertEqual(try a.partialCmp(other: b), o)
        }
        try [
            (1, 1, Ordering.equal),
            (2, 1, Ordering.greater),
            (1, 2, Ordering.less),
        ].forEach { try testWithoutMultiassets($0, $1, $2) }
        var a = Value(coin: 1)
        a.multiasset = [policy1: [asset1: UInt64(1)]]
        let b = Value(coin: 1)
        XCTAssertEqual(try a.partialCmp(other: b), Ordering.greater)
        let a2 = Value(coin: 1)
        var b2 = Value(coin: 1)
        b2.multiasset = [policy1: [asset1: UInt64(1)]]
        XCTAssertEqual(try a2.partialCmp(other: b2), Ordering.less)
        let testWithMultiassets = { (v1: UInt64, a1: UInt64, v2: UInt64, a2: UInt64, o: Ordering?) in
            var a = Value(coin: v1)
            a.multiasset = [policy1: [asset1: a1]]
            var b = Value(coin: v2)
            b.multiasset = [policy1: [asset1: a2]]
            XCTAssertEqual(try a.partialCmp(other: b), o)
        }
        try [
            (1, 1, 1, 1, Ordering.equal),
            (2, 1, 1, 1, Ordering.greater),
            (1, 1, 2, 1, Ordering.less),
            (1, 2, 1, 1, Ordering.greater),
            (2, 2, 1, 1, Ordering.greater),
            (1, 2, 2, 1, nil),
            (1, 1, 1, 2, Ordering.less),
            (1, 1, 2, 2, Ordering.less),
            (2, 1, 1, 2, nil),
            (1, 1, 1, 1, nil),
        ].forEach { try testWithMultiassets($0, $1, $2, $3, $4) }
        let asset2 = try AssetName(data: Data([2]))
        var a3 = Value(coin: 1)
        a3.multiasset = [policy1: [asset1: 1]]
        var b3 = Value(coin: 1)
        b3.multiasset = [policy1: [asset2: 1]]
        XCTAssertEqual(try a.partialCmp(other: b), nil)
    }
}
