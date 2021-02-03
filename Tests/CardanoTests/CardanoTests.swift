import XCTest
@testable import Cardano

final class CardanoTests: XCTestCase {
    func testRustCall() {
        XCTAssert(Cardano().callRust())
    }
}
