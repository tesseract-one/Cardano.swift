import XCTest
#if !COCOAPODS
@testable import CardanoCore
#else
@testable import Cardano
#endif

internal let _initialize: Void = {
    InitCardanoCore()
}()

final class CoreTests: XCTestCase {
    let initialize: Void = _initialize
    
    let publicKeyExample = "ed25519_pk1dgaagyh470y66p899txcl3r0jaeaxu6yd7z2dxyk55qcycdml8gszkxze2"
    
    func testLinearFee() throws {
        let linearFee = LinearFee(constant: 2, coefficient: 1)
        XCTAssertEqual(1, linearFee.coefficient)
        XCTAssertEqual(2, linearFee.constant)
    }
    
    func testValue() throws {
        let v1 = Value(coin: 1)
        let v2 = Value(coin: 2)
        let added = try v1.checkedAdd(rhs: v2)
        XCTAssertEqual(added.coin, 3)
    }
    
    func testTransactionWitnessSet() throws {
        let data = Data(repeating: 1, count: 64)
        let vkeys = [
            Vkeywitness(
                vkey: try Vkey(_0: PublicKey(bech32: publicKeyExample)),
                signature: try Ed25519Signature(data: data)
            )
        ]
        let bootstraps = [
            BootstrapWitness(
                vkey: try Vkey(_0: PublicKey(bech32: publicKeyExample)),
                signature: try Ed25519Signature(data: data),
                chainCode: data,
                attributes: data
            )
        ]
        var transactionWitnessSet = TransactionWitnessSet()
        transactionWitnessSet.vkeys = vkeys
        transactionWitnessSet.bootstraps = bootstraps
        XCTAssertNoThrow(transactionWitnessSet.vkeys?.withCArray {
            XCTAssertEqual($0.len, 1)
        })
        XCTAssertNoThrow(transactionWitnessSet.bootstraps?.withCArray {
            XCTAssertEqual($0.len, 1)
        })
    }
    
    func testNativeScriptHash() throws {
        let hash = try Ed25519KeyHash(bytes: Data([143, 180, 186, 93, 223, 42, 243, 7, 81, 98, 86, 125, 97, 69, 110, 52, 130, 243, 244, 98, 246, 13, 33, 212, 128, 168, 136, 40]))
        XCTAssertEqual(try hash.data().hex(prefix: false), "8fb4ba5ddf2af3075162567d61456e3482f3f462f60d21d480a88828")
        let script = NativeScript.scriptPubkey(ScriptPubkey(addr_keyhash: hash))
        let scriptHash = try ScriptHash(bytes: Data(script.hash(namespace: ScriptHashNamespace.nativeScript).bytesArray))
        XCTAssertEqual(
            try scriptHash.data().hex(prefix: false), "187b8d3ddcb24013097c003da0b8d8f7ddcf937119d8f59dccd05a0f"
        )
    }
}
