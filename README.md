# Cardano.swift

![🐧 linux: ready](https://img.shields.io/badge/%F0%9F%90%A7%20linux-ready-red.svg)
[![GitHub license](https://img.shields.io/badge/license-Apache%202.0-lightgrey.svg)](LICENSE)
[![Build Status](https://github.com/tesseract-one/Cardano.swift/workflows/Build%20&%20Tests/badge.svg?branch=main)](https://github.com/tesseract-one/Cardano.swift/actions/workflows/build.yml?query=branch%3Amain)
[![GitHub release](https://img.shields.io/github/release/tesseract-one/Cardano.swift.svg)](https://github.com/tesseract-one/Cardano.swift/releases)
[![SPM compatible](https://img.shields.io/badge/SwiftPM-Compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![CocoaPods version](https://img.shields.io/cocoapods/v/Cardano.svg)](https://cocoapods.org/pods/Cardano)
![Platform macOS | iOS | Linux](https://img.shields.io/badge/platform-Linux%20%7C%20macOS%20%7C%20iOS-orange.svg)

Swift SDK for Cardano network (Shelley).

## Installation

Cardano.swift uses [cardano-serialization-lib](https://github.com/Emurgo/cardano-serialization-lib) Rust library inside.

Cardano.swift deploys to macOS 10.12, iOS 11 and Linux. It has been tested on the latest OS releases only however, as the module uses very few platform-provided APIs, there should be very few issues with earlier versions.

Setup instructions:

- **Swift Package Manager:**
  Add this to the dependency section of your `Package.swift` manifest:

    ```Swift
    .package(url: "https://github.com/tesseract-one/Cardano.swift.git", from: "0.0.1")
    ```

- **CocoaPods:** Put this in your `Podfile`:

    ```Ruby
    pod 'Cardano', '~> 0.0.1'
    ```
  
- **CocoaPods with Rust part built from sources:**
  
  If you want to build Rust part from sources add this in your `Podfile`:
    ```Ruby
    pod 'Cardano/Build', '~> 0.0.1'
    ```
  And install Rust targets:
    ```sh
    rustup target add aarch64-apple-ios x86_64-apple-ios aarch64-apple-darwin x86_64-apple-darwin
    ```

- **Linux:**
  
  Linux supported through `SPM`. For build you have to build Rust library manually. You can build it using `rust/scripts/build_binary_linux.sh` script from this repository.
  ```sh
  rust/scripts/build_binary_linux.sh "SOME_INSTALL_PATH"
  ```
  And provide path to it as parameters to SPM for build.
  ```sh
  swift build -Xlinker -L"SOME_INSTALL_PATH/lib" -Xcc -I"SOME_INSTALL_PATH/include"
  ```

## Usage Examples

**SDK is in active development stage. We will provide usage examples soon. Stay tuned!**

## Development Plan

Right now SDK is in the active development stage. You can check our progress and plan below.

### Part 1: Core ![70%](https://progress-bar.dev/70?title=progress)

This is the core part of the SDK. Has all needed primitives for transaction building and signing.
This is a wrapper for [cardano-serialization-lib](https://github.com/Emurgo/cardano-serialization-lib).

Provided structures:
- [x] Address
- [x] AssetName
- [x] Assets
- [x] Bip32PrivateKey
- [x] Bip32PublicKey
- [x] BootstrapWitness
- [x] Ed25519Signature
- [x] LinearFee
- [x] MultiAsset
- [x] NetworkInfo
- [x] PrivateKey
- [x] PublicKey
- [x] StakeCredential
- [x] TransactionHash
- [x] TransactionInput
- [x] TransactionWitnessSet
- [x] Vkey
- [x] Vkeywitness
- [x] Withdrawals
- [ ] Certificate
- [ ] GeneralTransactionMetadata
- [ ] TransactionBody
- [ ] TransactionBuilder
- [ ] TransactionMetadata
- [ ] TransactionMetadatumLabels
- [ ] Transaction
- [ ] Value

### Part 2: Networking ![0%](https://progress-bar.dev/0?title=progress)

This part provides Swift APIs for communication with the Cardano node through GraphQL. Methods for connection to the Cardano node, obtaining info from it, and submitting new transactions will be implemented.

Models:
- [ ] Transactions
- [ ] Addresses
- [ ] UtXOs
- [ ] Balances

### Part 3: Developer-friendly APIs ![0%](https://progress-bar.dev/0?title=progress)

Having GraphQL and Core wrapped is great, but it's not developer-friendly yet. In this part, we are covering up all "exposed wires" under the hood with Swift-style neat APIs available for rapid dApps development.

We will provide APIs for:
- [ ] Obtaining the list of accounts from Keychain
- [ ] Obtaining all used addresses for account
- [ ] Obtaining balance for account / address
- [ ] Obtaining list of transactions for account / address
- [ ] Signing transaction with the account
- [ ] Submitting signed transaction 
- [ ] Transferring ADA (a simple way to build, sign and submit transfer transaction)

### Part 4: Keychain ![0%](https://progress-bar.dev/0?title=progress)

In this part, we will provide Keychain with easy private/public key management inside the dApp and Keychain API for more Keychain implementations.
The Keychain API will allow integration with signers and key providers, which is critical for further integration with Tesseract or any solution that keep private keys safe apart from the dApp.

### Part 5: Tests, Documentation and Examples ![0%](https://progress-bar.dev/0?title=progress)

Having a library is good but it should have proper documentation, examples and be properly tested for real-life usage.
In this part, we will work on that.

We will provide:
- [ ] unit-tests for Core
- [ ] unit-tests for Keychain
- [ ] integration tests for Networking
- [ ] integration tests for developer-friendly APIs
- [ ] usage examples
- [ ] example dApp which will show how to integrate and use SDK

## License

Cardano.swift can be used, distributed and modified under [the Apache 2.0 license](LICENSE).
