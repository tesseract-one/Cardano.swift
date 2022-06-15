// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let useLocalBinary = false

var package = Package(
    name: "Cardano",
    platforms: [.iOS(.v13), .macOS(.v10_15)],
    products: [
        .library(
            name: "Cardano",
            targets: ["Cardano"]),
        .library(
            name: "CardanoCore",
            targets: ["CardanoCore"]),
        .library(
            name: "OrderedCollections",
            targets: ["OrderedCollections"])
    ],
    dependencies: [
        .package(url: "https://github.com/attaswift/BigInt.git", from: "5.2.1"),
        .package(name: "BlockfrostSwiftSDK", url: "https://github.com/blockfrost/blockfrost-swift.git", from: "0.0.6"),
        .package(name: "Bip39", url: "https://github.com/tesseract-one/Bip39.swift.git", from: "0.1.1"),
    ],
    targets: [
        .target(
            name: "Cardano",
            dependencies: ["CardanoCore", "Bip39"]),
        .target(
            name: "CardanoCore",
            dependencies: ["CCardano", "BigInt", "OrderedCollections"],
            path: "Sources/Core"),
        
        .target(
            name: "OrderedCollections",
            dependencies: [],
            exclude: ["CMakeLists.txt", "LICENSE.txt"]),
        .testTarget(
            name: "CoreTests",
            dependencies: ["CardanoCore"]),
        .testTarget(
            name: "CardanoTests",
            dependencies: ["Cardano"])
    ]
)

#if os(Linux)
package.targets.append(
    .systemLibrary(name: "CCardano")
)
#else
let ccardano: Target = useLocalBinary ?
    .binaryTarget(
        name: "CCardano",
        path: "rust/binaries/CCardano.xcframework") :
    .binaryTarget(
        name: "CCardano",
        url: "https://github.com/tesseract-one/Cardano.swift/releases/download/0.1.2/CCardano.binaries.zip",
        checksum: "2352e340c34bea53d7a1877f9017d964f624b7a8d2a2fd41386ccdfa06846393")
package.targets.append(contentsOf: [
    ccardano,
    .target(
        name: "CardanoBlockfrost",
        dependencies: ["Cardano", "BlockfrostSwiftSDK"],
        path: "Sources/Blockfrost"),
    .testTarget(
        name: "BlockfrostTests",
        dependencies: ["CardanoBlockfrost"])
])
package.products.append(
    .library(
        name: "CardanoBlockfrost",
        targets: ["CardanoBlockfrost"])
)
#endif
