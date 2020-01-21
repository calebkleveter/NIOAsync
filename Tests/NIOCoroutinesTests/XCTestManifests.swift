import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(NIOCoroutinesTests.allTests),
    ]
}
#endif
