import NIO
import XCTest
import NIOAsync

final class NIOAsyncTests: XCTestCase {
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

    func testAsyncQuick() throws {
        let eventLoop = self.elg.next()
        let list = NumberList()

        let result = eventLoop.async {
            for number in (1...9).map({ eventLoop.makeSucceededFuture($0) }) {
                try list.numbers.append(number.await())
            }
        }

        try XCTAssertNoThrow(result.wait())
        XCTAssertEqual(list.numbers, [1, 2, 3, 4, 5, 6, 7, 8, 9])
    }

    func testBaslineMetric() throws {
        let range = (0..<10_000).map { $0 }
        
        measure {
            for number in range {
                _ = self.instantReturn(number)
            }
        }
    }

    func testAsyncOverheadMetric() throws {
        let eventLoop = self.elg.next()
        let range = (0..<10_000).map { eventLoop.makeSucceededFuture($0) }

        measure {
            let result = eventLoop.async {
                for number in range {
                    _ = try self.instantReturn(number.await())
                }
            }

            do {
                try result.wait()
            } catch let error {
                XCTFail(error.localizedDescription)
            }
        }
    }

    func instantReturn(_ number: Int) -> Int { return number }
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
