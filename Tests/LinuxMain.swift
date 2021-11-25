import XCTest

import BlockfrostTests
import CardanoTests
import CoreTests

var tests = [XCTestCaseEntry]()
tests += BlockfrostTests.__allTests()
tests += CardanoTests.__allTests()
tests += CoreTests.__allTests()

XCTMain(tests)
