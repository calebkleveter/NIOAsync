import NIO
import XCTest
import NIOCoroutines

final class NIOCoroutinesTests: XCTestCase {
    var elg: EventLoopGroup!

    override func setUp() {
        super.setUp()

        self.elg = MultiThreadedEventLoopGroup(numberOfThreads: 4)
    }

    override func tearDown() {
        do {
            try self.elg.syncShutdownGracefully()
        } catch let error {
            XCTFail("- [ELG SHUTDOWN FAILURE]: \(error)")
        }

        super.tearDown()
    }

    func testAsync() throws {
        let eventLoop = self.elg.next()
        let list = NumberList()

        let sum = eventLoop.async { () -> Int in
            let two = try eventLoop.future(2, after: 2).await()
            list.numbers.append(two)

            let five = try eventLoop.future(5, after: 2).await()
            list.numbers.append(five)

            let six = try eventLoop.future(6, after: 2).await()
            list.numbers.append(six)

            return two + five + six
        }

        list.numbers.append(1)
        sleep(3)
        list.numbers.append(3)
        list.numbers.append(4)

        try XCTAssertEqual(sum.wait(), 13)
        XCTAssertEqual(list.numbers, [1, 2, 3, 4, 5, 6])
    }
}

final class NumberList {
    var numbers: [Int] {
        didSet { print(self.numbers) }
    }

    init() {
        self.numbers = []
    }
}

extension EventLoop {
    func future<Value>(_ value: Value, after: UInt32) -> EventLoopFuture<Value> {
        sleep(after)
        return self.makeSucceededFuture(value)
    }
}
