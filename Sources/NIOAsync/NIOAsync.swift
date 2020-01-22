import SwiftCoroutine
import NIO
import Foundation.NSLock

/// Indicates whether the current scope is in a coroutine or not.
public var inCoroutine: Bool { Coroutine.isInsideCoroutine }

extension EventLoop {

    /// Runs a block in which `EventLoopFuture.await` can be used.
    ///
    /// - Parameter closure: The block that will be run in a coroutine.
    /// - Returns: The result from the closure, wrapped in an `EventLoopFuture`.
    public func async<Result>(_ closure: @escaping () throws -> Result) -> EventLoopFuture<Result> {
        let coroutine = Coroutine.newFromPool(dispatcher: .global)
        let promies = self.makePromise(of: Result.self)

        coroutine.start {
            do {
                let value = try closure()
                promies.succeed(value)
            } catch let error {
                promies.fail(error)
            }
        }

        return promies.futureResult
    }
}

extension EventLoopFuture {

    /// Awaits the result of the future in a coroutine, allowing the rest of the thread to continue running.
    ///
    /// - Returns: The final result of the `EventLoopFuture`.
    public func await() throws -> Value {
        precondition(inCoroutine, "- [BUG]: `EventLoopFuture.await()` must be called in a coroutine or `EventLoop.async` block.")

        let coroutine = try Coroutine.current()
        let lock = NSLock()
        var awaitResult: Result<Value, Error>?
        
        self.whenComplete { result in
            lock.lock()
            awaitResult = result
            lock.unlock()
            if coroutine.state == .suspended { coroutine.resume() }
        }

        lock.lock()
        if awaitResult == nil {
            coroutine.suspend(with: lock.unlock)
        } else {
            lock.unlock()
        }
        
        guard let value = try awaitResult?.get() else {
            throw AwaitError.completedWithoutValue
        }

        return value
    }
}

public enum AwaitError: Error {
    case completedWithoutValue
}
