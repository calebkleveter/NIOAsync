import class NIOConcurrencyHelpers.Lock
import class NIO.EventLoopFuture
import protocol NIO.EventLoop
import class SwiftCoroutine.Coroutine

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
        let lock = Lock()
        var awaitResult: Result<Value, Error>?
        
        self.whenComplete { result in
            lock.withLockVoid { awaitResult = result }
            if coroutine.state == .suspended { coroutine.resume() }
        }

        lock.lock()
        if awaitResult == nil {
            coroutine.suspend(with: lock.unlock)
        } else {
            lock.unlock()
        }
        
        guard let value = try awaitResult?.get() else {
            preconditionFailure("How'd you get this far and `awaitResult` still be nil? I'd suggest you open an issue on the NIOAsync repo.")
        }

        return value
    }
}
