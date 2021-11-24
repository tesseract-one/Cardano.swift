//
//  UtilsTests.swift
//  
//
//  Created by Ostap Danylovych on 06.08.2021.
//

import Foundation
import XCTest
#if !COCOAPODS
@testable import CardanoCore
#else
@testable import Cardano
#endif

final class UtilsTests: XCTestCase {
    let initialize: Void = _initialize
    
    private let coinsPerUtxoWord: UInt64 = 34_482
    
    private func onePolicyOne0CharAsset() throws -> Value {
        var assets = Value(coin: 0)
        assets.multiasset = [
            try PolicyID(bytes: Data(repeating: 0, count: 28)):
                [try AssetName(name: Data([])): UInt64(1)]
        ]
        return assets
    }
    
    private func onePolicyOne1CharAsset() throws -> Value {
        var assets = Value(coin: 1407406)
        assets.multiasset = [
            try PolicyID(bytes: Data(repeating: 0, count: 28)):
                [try AssetName(name: Data([1])): UInt64(1)]
        ]
        return assets
    }
    
    private func onePolicyThree1CharAssets() throws -> Value {
        var assets = Value(coin: 1555554)
        assets.multiasset = [
            try PolicyID(bytes: Data(repeating: 0, count: 28)):
                [
                    try AssetName(name: Data([1])): UInt64(1),
                    try AssetName(name: Data([2])): UInt64(1),
                    try AssetName(name: Data([3])): UInt64(1)
                ]
        ]
        return assets
    }
    
    private func twoPoliciesOne0CharAsset() throws -> Value {
        let assetList = [try AssetName(name: Data([])): UInt64(1)]
        var assets = Value(coin: 1592591)
        assets.multiasset = [
            try PolicyID(bytes: Data(repeating: 0, count: 28)): assetList,
            try PolicyID(bytes: Data(repeating: 1, count: 28)): assetList
        ]
        return assets
    }
    
    private func twoPoliciesOne1CharAsset() throws -> Value {
        let assetList = [try AssetName(name: Data([1])): UInt64(1)]
        var assets = Value(coin: 1592591)
        assets.multiasset = [
            try PolicyID(bytes: Data(repeating: 0, count: 28)): assetList,
            try PolicyID(bytes: Data(repeating: 1, count: 28)): assetList
        ]
        return assets
    }
    
    private func threePolicies961CharAssets() throws -> Value {
        var tokenBundle = MultiAsset()
        for p: UInt8 in 1...3 {
            var assetList = Assets()
            for an: UInt8 in 0..<32 {
                assetList.updateValue(UInt64(1), forKey: try AssetName(name: Data([p * 32 + an])))
            }
            tokenBundle.updateValue(assetList, forKey: try PolicyID(bytes: Data(repeating: p, count: 28)))
        }
        var assets = Value(coin: 7592585)
        assets.multiasset = tokenBundle
        return assets
    }
    
    private func onePolicyThree32CharAssets() throws -> Value {
        var assets = Value(coin: 1555554)
        assets.multiasset = [
            try PolicyID(bytes: Data(repeating: 0, count: 28)):
                [
                    try AssetName(name: Data(repeating: 1, count: 32)): UInt64(1),
                    try AssetName(name: Data(repeating: 2, count: 32)): UInt64(1),
                    try AssetName(name: Data(repeating: 3, count: 32)): UInt64(1)
                ]
        ]
        return assets
    }
    
    func testMinAdaValueNoMultiasset() throws {
        XCTAssertEqual(try Value(coin: 0).minAdaRequired(hasDataHash: false, coinsPerUtxoWord: coinsPerUtxoWord), 999978)
    }
    
    func testMinAdaValueOnePolicyOne0CharAsset() throws {
        XCTAssertEqual(try onePolicyOne0CharAsset().minAdaRequired(hasDataHash: false, coinsPerUtxoWord: coinsPerUtxoWord), 1_310_316)
    }
    
    func testMinAdaValueOnePolicyOne1CharAsset() throws {
        XCTAssertEqual(try onePolicyOne1CharAsset().minAdaRequired(hasDataHash: false, coinsPerUtxoWord: coinsPerUtxoWord), 1_344_798)
    }
    
    func testMinAdaValueOnePolicyThree1CharAssets() throws {
        XCTAssertEqual(try onePolicyThree1CharAssets().minAdaRequired(hasDataHash: false, coinsPerUtxoWord: coinsPerUtxoWord), 1_448_244)
    }
    
    func testMinAdaValueTwoPoliciesOne0CharAsset() throws {
        XCTAssertEqual(try twoPoliciesOne0CharAsset().minAdaRequired(hasDataHash: false, coinsPerUtxoWord: coinsPerUtxoWord), 1_482_726)
    }
    
    func testMinAdaValueTwoPoliciesOne1CharAsset() throws {
        XCTAssertEqual(try twoPoliciesOne1CharAsset().minAdaRequired(hasDataHash: false, coinsPerUtxoWord: coinsPerUtxoWord), 1_517_208)
    }
    
    func testMinAdaValueThreePolicies961CharAssets() throws {
        XCTAssertEqual(try threePolicies961CharAssets().minAdaRequired(hasDataHash: false, coinsPerUtxoWord: coinsPerUtxoWord), 6_896_400)
    }
    
    func testMinAdaValueOnePolicyOne0CharAssetDatumHash() throws {
        XCTAssertEqual(try onePolicyOne0CharAsset().minAdaRequired(hasDataHash: true, coinsPerUtxoWord: coinsPerUtxoWord), 1_655_136)
    }
    
    func testMinAdaValueOnePolicyThree32CharAssetsDatumHash() throws {
        XCTAssertEqual(try onePolicyThree32CharAssets().minAdaRequired(hasDataHash: true, coinsPerUtxoWord: coinsPerUtxoWord), 2_172_366)
    }
    
    func testMinAdaValueTwoPoliciesOne0CharAssetDatumHash() throws {
        XCTAssertEqual(try twoPoliciesOne0CharAsset().minAdaRequired(hasDataHash: true, coinsPerUtxoWord: coinsPerUtxoWord), 1_827_546)
    }
    
    func testSubtractValues() throws {
        let policy1 = try PolicyID(bytes: Data(repeating: 0, count: 28))
        let policy2 = try PolicyID(bytes: Data(repeating: 1, count: 28))
        let asset1 = try AssetName(name: Data([1]))
        let asset2 = try AssetName(name: Data([2]))
        let asset3 = try AssetName(name: Data([3]))
        let asset4 = try AssetName(name: Data([4]))
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
        let asset1 = try AssetName(name: Data([1]))
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
        var a1 = Value(coin: 1)
        a1.multiasset = [policy1: [asset1: UInt64(1)]]
        let b1 = Value(coin: 1)
        XCTAssertEqual(try a1.partialCmp(other: b1), Ordering.greater)
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
        ].forEach { try testWithMultiassets($0, $1, $2, $3, $4) }
        let asset2 = try AssetName(name: Data([2]))
        var a3 = Value(coin: 1)
        a3.multiasset = [policy1: [asset1: 1]]
        var b3 = Value(coin: 1)
        b3.multiasset = [policy1: [asset2: 1]]
        XCTAssertEqual(try a3.partialCmp(other: b3), nil)
    }
}
