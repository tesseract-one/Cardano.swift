#if !canImport(ObjectiveC)
import XCTest

extension AddressManagerTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__AddressManagerTests = [
        ("testFetchOnTestnet", testFetchOnTestnet),
    ]
}

extension CardanoSendApiTests {
    // DO NOT MODIFY: This is autogenerated, use:
    //   `swift test --generate-linuxmain`
    // to regenerate.
    static let __allTests__CardanoSendApiTests = [
        ("testSendAdaOnTestnet", testSendAdaOnTestnet),
    ]
}

public func __allTests() -> [XCTestCaseEntry] {
    return [
        testCase(AddressManagerTests.__allTests__AddressManagerTests),
        testCase(CardanoSendApiTests.__allTests__CardanoSendApiTests),
    ]
}
#endif