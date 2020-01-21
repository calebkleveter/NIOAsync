import SwiftCoroutine
import NIO

/// Indicates whether the current scope is in a coroutine or not.
public var inCoroutine: Bool { Coroutine.isInsideCoroutine }

extension EventLoop {

    /// Runs a block in which `EventLoopFuture.await` can be used.
    ///
    /// - Parameter closure: The block that will be run in a coroutine.
    /// - Returns: The result from the closure, wrapped in an `EventLoopFuture`.
    public func async<Result>(_ closure: @escaping () throws -> Result) -> EventLoopFuture<Result> {
        coroutine {
            return try closure()
        }.nioFuture(on: self)
    }
}

extension EventLoopFuture {

    /// Awaits the result of the future in a coroutine, allowing the rest of the thread to continue running.
    ///
    /// - Returns: The final result of the `EventLoopFuture`.
    public func await() throws -> Value {
        precondition(inCoroutine, "- [BUG]: `EventLoopFuture.await()` must be called in a coroutine or `EventLoop.async` block.")
        return try self.coroutineFuture().await()
    }

    internal func coroutineFuture() -> CoFuture<Value> {
        let promies = CoPromise<Value>()
        self.whenComplete(promies.send(completion:))
        return promies
    }
}

extension CoFuture {
    internal func nioFuture(on eventLoop: EventLoop) -> EventLoopFuture<Output> {
        let promise = eventLoop.makePromise(of: Output.self)
        self.addHandler(promise.completeWith(_:))
        return promise.futureResult
    }
}
