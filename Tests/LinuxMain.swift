import XCTest

import NIOAsyncTests

var tests = [XCTestCaseEntry]()
tests += NIOAsyncTests.__allTests()

XCTMain(tests)
