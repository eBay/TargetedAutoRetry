import XCTest

import TargetedAutoRetryTests

var tests = [XCTestCaseEntry]()
tests += TargetedAutoRetryTests.allTests()
XCTMain(tests)
