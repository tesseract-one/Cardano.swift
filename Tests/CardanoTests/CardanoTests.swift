import XCTest
@testable import Cardano

final class CardanoTests: XCTestCase {
    let publicKeyExample = "ed25519_pk1dgaagyh470y66p899txcl3r0jaeaxu6yd7z2dxyk55qcycdml8gszkxze2"
    
    func testInit() {
        let _ = Cardano()
    }
    
    func testLinearFee() throws {
        let _ = Cardano()
        let linearFee = try LinearFee(coefficient: 1, constant: 2)
        XCTAssertEqual(1, linearFee.coefficient)
        XCTAssertEqual(2, linearFee.constant)
    }
    
    func testValue() throws {
        let _ = Cardano()
        let v1 = Value(coin: 1)
        let v2 = Value(coin: 2)
        let added = try v1.checkedAdd(rhs: v2)
        XCTAssertEqual(added.coin, 3)
    }
    
    func testTransactionWitnessSet() throws {
        let _ = Cardano()
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
        XCTAssertNoThrow(transactionWitnessSet.vkeys?.withCArray { $0 })
        XCTAssertNoThrow(transactionWitnessSet.bootstraps?.withCArray { $0 })
    }
    
    func testMoveInstantaneousReward() throws {
        let _ = Cardano()
        let data = Data(repeating: 1, count: 28)
        var mir = MoveInstantaneousReward(pot: MIRPot.reserves)
        mir.rewards.updateValue(1, forKey: StakeCredential.keyHash(try Ed25519KeyHash(bytes: data)))
        XCTAssertNoThrow(try mir.bytes())
    }
}
