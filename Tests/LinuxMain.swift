import XCTest

import NIOCoroutinesTests

var tests = [XCTestCaseEntry]()
tests += NIOCoroutinesTests.allTests()
XCTMain(tests)
