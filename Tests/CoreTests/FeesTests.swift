//
//  FeesTests.swift
//  
//
//  Created by Ostap Danylovych on 29.07.2021.
//

import Foundation
import XCTest
#if !COCOAPODS
@testable import CardanoCore
#else
@testable import Cardano
#endif

final class FeesTests: XCTestCase {
    let initialize: Void = _initialize
    
    func testTxSimpleUtxo() throws {
        let inputs = [
            TransactionInput(
                transaction_id: try TransactionHash(
                    bytes: Data(hex: "3b40265111d8bb3c3c608d95b3a0bf83461ace32d79336579a1939b3aad1c0b7")!
                ),
                index: 0
            )
        ]
        let outputs = [
            TransactionOutput(
                address: try Address(
                    bytes: Data(hex: "611c616f1acb460668a9b2f123c80372c2adad3583b9c6cd2b1deeed1c")!
                ),
                amount: Value(coin: 1)
            )
        ]
        let body = TransactionBody(inputs: inputs, outputs: outputs, fee: 94002, ttl: 10)
        var w = TransactionWitnessSet()
        let vkw = [
            try Vkeywitness(
                txBodyHash: try TransactionHash(txBody: body),
                sk: try PrivateKey(
                    normalBytes: Data(hex: "c660e50315d76a53d80732efda7630cae8885dfb85c46378684b3c6103e1284a")!
                )
            )
        ]
        w.vkeys = vkw
        let signedTx = Transaction(
            body: body,
            witnessSet: w,
            auxiliaryData: nil
        )
        let linearFee = LinearFee(constant: 2, coefficient: 500)
        XCTAssertEqual(
            try signedTx.bytes().hex(prefix: false),
            "84a400818258203b40265111d8bb3c3c608d95b3a0bf83461ace32d79336579a1939b3aad1c0b700018182581d611c616f1acb460668a9b2f123c80372c2adad3583b9c6cd2b1deeed1c01021a00016f32030aa10081825820f9aa3fccb7fe539e471188ccc9ee65514c5961c070b06ca185962484a4813bee5840fae5de40c94d759ce13bf9886262159c4f26a289fd192e165995b785259e503f6887bf39dfa23a47cf163784c6eee23f61440e749bc1df3c73975f5231aeda0ff5f6"
        )
        XCTAssertEqual(try signedTx.minFee(linearFee: linearFee), 94502)
    }
    
    func testTxSimpleByronUtxo() throws {
        let inputs = [
            TransactionInput(
                transaction_id: try TransactionHash(
                    bytes: Data(hex: "3b40265111d8bb3c3c608d95b3a0bf83461ace32d79336579a1939b3aad1c0b7")!
                ),
                index: 0
            )
        ]
        let outputs = [
            TransactionOutput(
                address: try Address(
                    bytes: Data(hex: "611c616f1acb460668a9b2f123c80372c2adad3583b9c6cd2b1deeed1c")!
                ),
                amount: Value(coin: 1)
            )
        ]
        let body = TransactionBody(inputs: inputs, outputs: outputs, fee: 112002, ttl: 10)
        var w = TransactionWitnessSet()
        let bootstrapWits = [
            try BootstrapWitness(
                txBodyHash: try TransactionHash(txBody: body),
                addr: ByronAddress(base58: "Ae2tdPwUPEZ6r6zbg4ibhFrNnyKHg7SYuPSfDpjKxgvwFX9LquRep7gj7FQ"),
                key: try Bip32PrivateKey(
                    bytes: Data(hex: "d84c65426109a36edda5375ea67f1b738e1dacf8629f2bb5a2b0b20f3cd5075873bf5cdfa7e533482677219ac7d639e30a38e2e645ea9140855f44ff09e60c52c8b95d0d35fe75a70f9f5633a3e2439b2994b9e2bc851c49e9f91d1a5dcbb1a3")!
                )
            )
        ]
        w.bootstraps = bootstrapWits
        let signedTx = Transaction(
            body: body,
            witnessSet: w,
            auxiliaryData: nil
        )
        let linearFee = LinearFee(constant: 2, coefficient: 500)
        XCTAssertEqual(
            try signedTx.bytes().hex(prefix: false),
            "84a400818258203b40265111d8bb3c3c608d95b3a0bf83461ace32d79336579a1939b3aad1c0b700018182581d611c616f1acb460668a9b2f123c80372c2adad3583b9c6cd2b1deeed1c01021a0001b582030aa10281845820473811afd4d939b337c9be1a2ceeb2cb2c75108bddf224c5c21c51592a7b204a5840f0b04a852353eb23b9570df80b2aa6a61b723341ab45a2024a05b07cf58be7bdfbf722c09040db6cee61a0d236870d6ad1e1349ac999ec0db28f9471af25fb0c5820c8b95d0d35fe75a70f9f5633a3e2439b2994b9e2bc851c49e9f91d1a5dcbb1a341a0f5f6"
        )
        XCTAssertEqual(try signedTx.minFee(linearFee: linearFee), 112502)
    }

    func testTxMultiUtxo() throws {
        let inputs = [
            TransactionInput(
                transaction_id: try TransactionHash(
                    bytes: Data(hex: "3b40265111d8bb3c3c608d95b3a0bf83461ace32d79336579a1939b3aad1c0b7")!
                ),
                index: 42
            ),
            TransactionInput(
                transaction_id: try TransactionHash(
                    bytes: Data(hex: "82839f8200d81858248258203b40265111d8bb3c3c608d95b3a0bf83461ace32")!
                ),
                index: 7
            )
        ]
        let outputs = [
            TransactionOutput(
                address: try Address(
                    bytes: Data(hex: "611c616f1acb460668a9b2f123c80372c2adad3583b9c6cd2b1deeed1c")!
                ),
                amount: Value(coin: 289)
            ),
            TransactionOutput(
                address: try Address(
                    bytes: Data(hex: "61bcd18fcffa797c16c007014e2b8553b8b9b1e94c507688726243d611")!
                ),
                amount: Value(coin: 874551452)
            )
        ]
        let body = TransactionBody(inputs: inputs, outputs: outputs, fee: 183502, ttl: 999)
        var w = TransactionWitnessSet()
        let vkw = [
            try Vkeywitness(
                txBodyHash: try TransactionHash(txBody: body),
                sk: try PrivateKey(
                    normalBytes: Data(hex: "c660e50315d76a53d80732efda7630cae8885dfb85c46378684b3c6103e1284a")!
                )
            ),
            try Vkeywitness(
                txBodyHash: try TransactionHash(txBody: body),
                sk: try PrivateKey(
                    normalBytes: Data(hex: "13fe79205e16c09536acb6f0524d04069f380329d13949698c5f22c65c989eb4")!
                )
            )
        ]
        w.vkeys = vkw
        let signedTx = Transaction(
            body: body,
            witnessSet: w,
            auxiliaryData: nil
        )
        let linearFee = LinearFee(constant: 2, coefficient: 500)
        XCTAssertEqual(
            try signedTx.bytes().hex(prefix: false),
            "84a400828258203b40265111d8bb3c3c608d95b3a0bf83461ace32d79336579a1939b3aad1c0b7182a82582082839f8200d81858248258203b40265111d8bb3c3c608d95b3a0bf83461ace3207018282581d611c616f1acb460668a9b2f123c80372c2adad3583b9c6cd2b1deeed1c19012182581d61bcd18fcffa797c16c007014e2b8553b8b9b1e94c507688726243d6111a3420989c021a0002ccce031903e7a10082825820f9aa3fccb7fe539e471188ccc9ee65514c5961c070b06ca185962484a4813bee58401ec3e56008650282ba2e1f8a20e81707810b2d0973c4d42a1b4df65b732bda81567c7824904840b2554d2f33861da5d70588a29d33b2b61042e3c3445301d8008258206872b0a874acfe1cace12b20ea348559a7ecc912f2fc7f674f43481df973d92c5840a0718fb5b37d89ddf926c08e456d3f4c7f749e91f78bb3e370751d5b632cbd20d38d385805291b1ef2541b02543728a235e01911f4b400bfb50e5fce589de907f5f6"
        )
        XCTAssertEqual(try signedTx.minFee(linearFee: linearFee), 184002)
    }
    
    func testTxRegisterStake() throws {
        let network: UInt8 = 1
        let inputs = [
            TransactionInput(
                transaction_id: try TransactionHash(
                    bytes: Data(hex: "3b40265111d8bb3c3c608d95b3a0bf83461ace32d79336579a1939b3aad1c0b7")!
                ),
                index: 0
            )
        ]
        let outputs = [
            TransactionOutput(
                address: try Address(
                    bytes: Data(hex: "611c616f1acb460668a9b2f123c80372c2adad3583b9c6cd2b1deeed1c")!
                ),
                amount: Value(coin: 1)
            )
        ]
        var body = TransactionBody(inputs: inputs, outputs: outputs, fee: 266002, ttl: 10)
        let poolOwners = [
            try PublicKey(bytes: Data(hex: "54d1a9c5ad69586ceeb839c438400c376c0bd34825fb4c17cc2f58c54e1437f3")!).hash()
        ]
        let registrationCert = PoolRegistration(
            poolParams: PoolParams(
                operator: try PublicKey(
                    bytes: Data(hex: "b24c040e65994bd5b0621a060166d32d356ef4be3cc1f848426a4cf386887089")!
                ).hash(),
                vrfKeyhash: try VRFKeyHash(
                    bytes: Data(hex: "bd0000f498ccacdc917c28274cba51c415f3f21931ff41ca8dc1197499f8e124")!
                ),
                pledge: 1000000,
                cost: 1000000,
                margin: UnitInterval(numerator: 3, denominator: 100),
                rewardAccount: RewardAddress(
                    network: network,
                    payment: StakeCredential.keyHash(
                        try PublicKey(
                            bytes: Data(hex: "54d1a9c5ad69586ceeb839c438400c376c0bd34825fb4c17cc2f58c54e1437f3")!
                        ).hash()
                    )
                ),
                poolOwners: poolOwners,
                relays: [],
                poolMetadata: nil
            )
        )
        let certs = [Certificate.poolRegistration(registrationCert)]
        body.certs = certs
        var w = TransactionWitnessSet()
        let vkw = [
            try Vkeywitness(
                txBodyHash: try TransactionHash(txBody: body),
                sk: try PrivateKey(
                    normalBytes: Data(hex: "c660e50315d76a53d80732efda7630cae8885dfb85c46378684b3c6103e1284a")!
                )
            ),
            try Vkeywitness(
                txBodyHash: try TransactionHash(txBody: body),
                sk: try PrivateKey(
                    normalBytes: Data(hex: "2363f3660b9f3b41685665bf10632272e2d03c258e8a5323436f0f3406293505")!
                )
            ),
            try Vkeywitness(
                txBodyHash: try TransactionHash(txBody: body),
                sk: try PrivateKey(
                    normalBytes: Data(hex: "5ada7f4d92bce1ee1707c0a0e211eb7941287356e6ed0e76843806e307b07c8d")!
                )
            )
        ]
        w.vkeys = vkw
        let signedTx = Transaction(
            body: body,
            witnessSet: w,
            auxiliaryData: nil
        )
        let linearFee = LinearFee(constant: 2, coefficient: 500)
        XCTAssertEqual(
            try signedTx.bytes().hex(prefix: false),
            "84a500818258203b40265111d8bb3c3c608d95b3a0bf83461ace32d79336579a1939b3aad1c0b700018182581d611c616f1acb460668a9b2f123c80372c2adad3583b9c6cd2b1deeed1c01021a00040f12030a04818a03581c1c13374874c68016df54b1339b6cacdd801098431e7659b24928efc15820bd0000f498ccacdc917c28274cba51c415f3f21931ff41ca8dc1197499f8e1241a000f42401a000f4240d81e82031864581de151df9ba1b74a1c9608a487e114184556801e927d31d96425cb80af7081581c51df9ba1b74a1c9608a487e114184556801e927d31d96425cb80af7080f6a10083825820f9aa3fccb7fe539e471188ccc9ee65514c5961c070b06ca185962484a4813bee5840a7f305d7e46abfe0f7bea6098bdf853ab9ce8e7aa381be5a991a871852f895a718e20614e22be43494c4dc3a8c78c56cd44fd38e0e5fff3e2fbd19f70402fc02825820b24c040e65994bd5b0621a060166d32d356ef4be3cc1f848426a4cf386887089584013c372f82f1523484eab273241d66d92e1402507760e279480912aa5f0d88d656d6f25d41e65257f2f38c65ac5c918a6735297741adfc718394994f20a1cfd0082582054d1a9c5ad69586ceeb839c438400c376c0bd34825fb4c17cc2f58c54e1437f35840d326b993dfec21b9b3e1bd2f80adadc2cd673a1d8d033618cc413b0b02bc3b7efbb23d1ff99138abd05c398ce98e7983a641b50dcf0f64ed33f26c6e636b0b0ff5f6"
        )
        XCTAssertEqual(try signedTx.minFee(linearFee: linearFee), 269502)
    }
    
    func testTxWithdrawal() throws {
        let inputs = [
            TransactionInput(
                transaction_id: try TransactionHash(
                    bytes: Data(hex: "3b40265111d8bb3c3c608d95b3a0bf83461ace32d79336579a1939b3aad1c0b7")!
                ),
                index: 0
            )
        ]
        let outputs = [
            TransactionOutput(
                address: try Address(
                    bytes: Data(hex: "611c616f1acb460668a9b2f123c80372c2adad3583b9c6cd2b1deeed1c")!
                ),
                amount: Value(coin: 1)
            )
        ]
        var body = TransactionBody(inputs: inputs, outputs: outputs, fee: 162502, ttl: 10)
        let withdrawals = [
            try Address(bytes: Data(hex: "e151df9ba1b74a1c9608a487e114184556801e927d31d96425cb80af70")!).reward!: UInt64(1337)
        ]
        body.withdrawals = withdrawals
        var w = TransactionWitnessSet()
        let vkw = [
            try Vkeywitness(
                txBodyHash: try TransactionHash(txBody: body),
                sk: try PrivateKey(
                    normalBytes: Data(hex: "c660e50315d76a53d80732efda7630cae8885dfb85c46378684b3c6103e1284a")!
                )
            ),
            try Vkeywitness(
                txBodyHash: try TransactionHash(txBody: body),
                sk: try PrivateKey(
                    normalBytes: Data(hex: "5ada7f4d92bce1ee1707c0a0e211eb7941287356e6ed0e76843806e307b07c8d")!
                )
            )
        ]
        w.vkeys = vkw
        let signedTx = Transaction(
            body: body,
            witnessSet: w,
            auxiliaryData: nil
        )
        let linearFee = LinearFee(constant: 2, coefficient: 500)
        XCTAssertEqual(
            try signedTx.bytes().hex(prefix: false),
            "84a500818258203b40265111d8bb3c3c608d95b3a0bf83461ace32d79336579a1939b3aad1c0b700018182581d611c616f1acb460668a9b2f123c80372c2adad3583b9c6cd2b1deeed1c01021a00027ac6030a05a1581de151df9ba1b74a1c9608a487e114184556801e927d31d96425cb80af70190539a10082825820f9aa3fccb7fe539e471188ccc9ee65514c5961c070b06ca185962484a4813bee5840fc0493f7121efe385d72830680e735ccdef99c3a31953fe877b89ad3a97fcdb871cc7f2cdd6a8104e52f6963bd9e10d814d4fabdbcdc8475bc63e872dcc94d0a82582054d1a9c5ad69586ceeb839c438400c376c0bd34825fb4c17cc2f58c54e1437f35840a051ba927582004aedab736b9f1f9330ff867c260f4751135d480074256e83cd23d2a4bb109f955c43afdcdc5d1841b28d5c1ea2148dfbb6252693590692bb00f5f6"
        )
        XCTAssertEqual(try signedTx.minFee(linearFee: linearFee), 163002)
    }
}
