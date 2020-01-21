import XCTest
@testable import NIOCoroutines

final class NIOCoroutinesTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(NIOCoroutines().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
