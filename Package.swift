// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let useLocalBinary = true

var package = Package(
    name: "Cardano",
    platforms: [.iOS(.v11), .macOS(.v10_12)],
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
    ],
    targets: [
        .target(
            name: "Cardano",
            dependencies: ["CardanoCore"]),
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
            dependencies: ["CardanoCore"])
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
                url: "https://github.com/tesseract-one/Cardano.swift/releases/download/0.0.1/CCardano.binaries.zip",
                checksum: "08fcaf9e09b9c53a1823cc6131ed2d9b55f6ba595e4fd39cee7f77a51973921a")
        )
    }
#endif
