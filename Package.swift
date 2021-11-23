// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let useLocalBinary = false

var package = Package(
    name: "Cardano",
    platforms: [.iOS(.v11), .macOS(.v10_15)],
    products: [
        .library(
            name: "Cardano",
            targets: ["Cardano"]),
        .library(
            name: "CardanoCore",
            targets: ["CardanoCore"]),
        .library(
            name: "CardanoBlockfrost",
            targets: ["CardanoBlockfrost"]),
        .library(
            name: "OrderedCollections",
            targets: ["OrderedCollections"])
    ],
    dependencies: [
        .package(url: "https://github.com/attaswift/BigInt.git", from: "5.2.1"),
        .package(url: "https://github.com/blockfrost/blockfrost-swift.git", from: "0.0.5"),
        .package(url: "https://github.com/tesseract-one/Bip39.swift.git", from: "0.1.1"),
    ],
    targets: [
        .target(
            name: "Cardano",
            dependencies: [
                "CardanoCore",
                .product(name: "Bip39", package: "Bip39.swift")
            ]),
        .target(
            name: "CardanoCore",
            dependencies: ["CCardano", "BigInt", "OrderedCollections"],
            path: "Sources/Core"),
        .target(
            name: "CardanoBlockfrost",
            dependencies: [
                "Cardano",
                .product(name: "BlockfrostSwiftSDK", package: "blockfrost-swift")
            ],
            path: "Sources/Blockfrost"),
        .target(
            name: "OrderedCollections",
            dependencies: [],
            exclude: ["CMakeLists.txt", "LICENSE.txt"]),
        .testTarget(
            name: "CoreTests",
            dependencies: ["CardanoCore"]),
        .testTarget(
            name: "ApiTests",
            dependencies: ["CardanoBlockfrost"])
    ]
)

#if os(Linux)
    package.targets.append(
        .systemLibrary(name: "CCardano")
    )
#else
    if useLocalBinary {
        package.targets.append(
            .binaryTarget(
                name: "CCardano",
                path: "rust/binaries/CCardano.xcframework")
        )
    } else {
        package.targets.append(
            .binaryTarget(
                name: "CCardano",
                url: "https://github.com/tesseract-one/Cardano.swift/releases/download/0.1.0/CCardano.binaries.zip",
                checksum: "0b9a5e4d768da0edc7fe3834a03d2b463633c64121cc76bc2ec338006a500b77")
        )
    }
#endif
