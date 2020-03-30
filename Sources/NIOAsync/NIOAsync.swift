import class NIOConcurrencyHelpers.Lock
import class NIO.EventLoopFuture
import protocol NIO.EventLoop
import protocol SwiftCoroutine.CoroutineScheduler
import struct SwiftCoroutine.Coroutine

/// Indicates whether the current scope is in a coroutine or not.
@inlinable public var inCoroutine: Bool { Coroutine.isInsideCoroutine }

private struct EventLoopScheduler: CoroutineScheduler {
    let eventLoop: EventLoop
    
    @inlinable func scheduleTask(_ task: @escaping () -> Void) {
        eventLoop.inEventLoop ? task() : eventLoop.execute(task)
    }
}

extension EventLoop {

    /// Runs a block in which `EventLoopFuture.await` can be used.
    ///
    /// - Parameter closure: The block that will be run in a coroutine.
    /// - Returns: The result from the closure, wrapped in an `EventLoopFuture`.
    public func async<T>(_ closure: @escaping () throws -> T) -> EventLoopFuture<T> {
        let promise = self.makePromise(of: T.self)
        
        EventLoopScheduler(eventLoop: self).startCoroutine {
            promise.completeWith(Result(catching: closure))
        }
        
        return promise.futureResult
    }
}

extension EventLoopFuture {

    /// Awaits the result of the future in a coroutine, allowing the rest of the thread to continue running.
    ///
    /// - Returns: The final result of the `EventLoopFuture`.
    @inlinable public func await() throws -> Value {
        precondition(inCoroutine, "- [BUG]: `EventLoopFuture.await()` must be called in a coroutine or `EventLoop.async` block.")

        return try Coroutine.await(whenComplete).get()
    }
}
