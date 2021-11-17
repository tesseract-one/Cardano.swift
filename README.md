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
  SPM build provides 2 targets: `Cardano` and `CardanoBlockfrost` (networking library).

- **CocoaPods:** Put this in your `Podfile`:

    ```Ruby
    pod 'Cardano/Binary', '~> 0.0.1'
    pod 'Cardano/Blockfrost' # networking
    ```
  
- **CocoaPods with Rust part built from sources:**
  
  If you want to build Rust part from sources add this in your `Podfile`:
    ```Ruby
    pod 'Cardano/Build', '~> 0.0.1'
    pod 'Cardano/Blockfrost' # networking
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

## Usage

Library provides a set of high-level APIs for standard tasks.
Lets try to send ADA to another address on the test net.
We will use Blockfrost API for simplicity.

### Initialize library
```swift
import Foundation
import Cardano
// Needed for SPM only
import CardanoBlockfrost

// We need Keychain with our keys first to sign our transactions
let keychain = try Keychain(mnemonic: ["your", "mnemonic", "phrase"])

// Generate first account in keychain
try keychain.addAccount(index: 0)

// Create main Cardano object
let cardano = try! Cardano(blockfrost: "your-project-key",
                           info: .testnet,
                           signer: keychain)

//Sync addresses with network and call our sendAda method
cardano.addresses.fetch { _ in
  sendAda(cardano: cardano)
}
```

### Send ADA
```swift
func sendAda(cardano: Cardano) {
  // Get our account from fetched accounts
  let account = try cardano.addresses.fetchedAccounts()[0]

  // Create recepient address
  let to = try Address(bech32: "addr_test1qzdj7sr6ymlqmrpvvd5qg9ct55kx6kcev67u33uc9grgm3dc4rwdulp233ujjmc09g446unlhtt0ekdqds2t2qccxxmspd22lj")

  // Send ADA
  cardano.send.ada(to: to, lovelace: 10000000, from: account) { res in
    switch res {
      case .failure(let err): print("TX Failed: \(err)")
      case .success(let txId): print("TX Id: \(txId)")
    }
  }
}
```

### Addresses and UTXOs
We have two helper interfaces for `Address` and `UTXO` management. They can be obtained as `addresses` and `utxos` from `Cardano` object.

#### Address Manager
```swift
var account: Account? = nil
// Get list of accounts from Signer
cardano.addresses.accounts() { res in
  account = try res.get()[0]
}

// Fetch list of addresses from the network for provided accounts
cardano.addresses.fetch(for: [account]) { _ in }

// Get list and fetch addresses (bot methods together)
cardano.addresses.fetch() { _ in }

// Get list of fetched accounts
let accounts = cardano.addresses.fetchedAccounts()

// Get list of fetched addresses for Account
let addresses = try cardano.addresses.get(cached: account)

// Create new address for the Account
let address = try cardano.addresses.new(for: account, change: false)
```

#### UTXO provider
```swift
// Obtain list of UTXOs from the network for addresses
cardano.utxos.get(for: [address]).next { res, next in
  let utxos = try! res.get()
  print("UTXOs: \(utxos), has more: \(next != nil)")
}
// Obtain list of UTXOs from the network for transaction
cardano.utxos.get(for: try! TransactionHash(hex: "0x..")).next { res, next in
  let utxos = try! res.get()
  print("UTXOs: \(utxos), has more: \(next != nil)")
}
```

### Custom Transaction
`TransactionBuilder` class can be used for building custom transactions.
```swift
let info = NetworkApiInfo.testnet

var builder = try! TransactionBuilder(linearFee: info.linearFee,
                                      minimumUtxoVal: info.minimumUtxoVal,
                                      poolDeposit: info.poolDeposit,
                                      keyDeposit: info.keyDeposit,
                                      maxValueSize: info.maxValueSize,
                                      maxTxSize: info.maxTxSize)
// Add tx information
builder.addInput(....)
builder.addOutput(....)

// Build TX
let tx = try builder.build()

// Sign and submit
builder.tx.signAndSubmit(tx: tx, addresses: [/* used addresses in tx*/]) { res in
  print("Result: \(res)")
}
)
```

## Further Development

Further development plans based on requests from the users. If you need more APIs for your dApp - create Issue and we will add them.

## License

Cardano.swift can be used, distributed and modified under [the Apache 2.0 license](LICENSE).
