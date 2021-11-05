//
//  Bip32.swift
//  
//
//  Created by Yehor Popovych on 25.08.2021.
//

import Foundation

public struct Bip32Path: Equatable, Hashable {
    public enum Error: Swift.Error {
        case invalidMarker(String)
        case pathTooShort(Int)
        case shouldBeHard(UInt32)
        case shouldBeSoft(UInt32)
        case cantParse(String)
    }
    
    public let path: [UInt32]
    
    public init(path: [UInt32]) {
        self.path = path
    }
    
    public func appending(_ index: UInt32, hard: Bool = false) throws -> Self {
        var index = index
        if !hard && index >= Self.hard {
            throw Error.shouldBeSoft(index)
        }
        if hard && index < Self.hard {
            index += Self.hard
        }
        if let prev = path.last, prev < Self.hard && hard {
            throw Error.shouldBeSoft(index)
        }
        return Bip32Path(path: self.path + [index])
    }
    
    public var account: Bip32Path? {
        guard path.count > 2 else { return nil }
        return Bip32Path(path: Array(path.prefix(3)))
    }
    
    public var purpose: UInt32? {
        guard path.count > 0 else { return nil }
        return path[0] - Self.hard
    }
    
    public var coin: UInt32? {
        guard path.count > 1 else { return nil }
        return path[1] - Self.hard
    }
    
    public var accountIndex: UInt32? {
        guard path.count > 2 else { return nil }
        return path[2] - Self.hard
    }
    
    public var isChange: Bool? {
        guard path.count > 3 else { return nil }
        return path[3] == 1
    }
    
    public var addressIndex: UInt32? {
        guard path.count > 4 else { return nil }
        return path[4]
    }
    
    public static let purpose: UInt32 = 1852
    public static let coin: UInt32 = 1815
    
    public static let prefix = Bip32Path(
        path: [Self.hard + Self.purpose, Self.hard + Self.coin]
    )
    public static let hard: UInt32 = 0x80000000
}

extension Bip32Path {
    public var isValidAccount: Bool {
        path.count == 3 &&
            Array(path.prefix(2)) == Self.prefix.path &&
            path[3] >= Self.hard
    }
    
    public var isValidAddress: Bool {
        path.count == 5 &&
            Array(path.prefix(2)) == Self.prefix.path &&
            path[2] >= Self.hard && path[3] < Self.hard && path[4] < Self.hard
    }
}


extension Bip32Path {
    public init(parsing str: String) throws {
        let parts = str.split(separator: "/").map{String($0)}
        guard parts.first == "m" else {
            throw Error.invalidMarker(String(parts.first ?? ""))
        }
        guard parts.count > 1 else {
            throw Error.pathTooShort(parts.count)
        }
        self = try parts
            .dropFirst()
            .enumerated()
            .reduce(Bip32Path(path: [])) { (b32, part) in
                var hard: Bool
                var int: UInt32
                if part.element.hasSuffix("'") {
                    guard let parsed = UInt32(String(part.element.dropLast()), radix: 10) else {
                        throw Error.cantParse(part.element)
                    }
                    hard = true
                    int = parsed
                } else {
                    guard let parsed = UInt32(part.element, radix: 10) else {
                        throw Error.cantParse(part.element)
                    }
                    hard = false
                    int = parsed
                }
                if part.offset < 3 && !hard {
                    throw Error.shouldBeHard(int)
                }
                return try b32.appending(int, hard: hard)
            }
    }
}
