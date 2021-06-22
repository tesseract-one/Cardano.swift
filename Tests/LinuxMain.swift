import XCTest

import CardanoTests

var tests = [XCTestCaseEntry]()
tests += CardanoTests.__allTests()

XCTMain(tests)
