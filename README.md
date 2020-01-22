# NIOAsync

**:warning: `setjmp`/`longjpm` use to implement SwiftCoroutine is generally considered to by undefined behaviour. It's probably a bad idea to use this project for anything other than experimentation. Use at your own risk.**

## :package: Getting Started

Oh, you're still reading, huh? Alright, I guess I'll get you up to speed. This project is pretty small, so there isn't much to it. Start by adding it as a dependency to your SPM project:

```swift
.package(url: "https://github.com/calebkleveter/NIOAsync.git", from: "0.1.0")
```

Then run `swift package update`, or feel smug that you have Xcode 11 and wait for it to install.

## :hammer: API

There are really 2 methods that this package provides. The first is `EventLoop.async(_:)`:

```swift
let result: EventLoopFuture<OperationResult> = eventLoop.async {
    return someReallyLongAsyncOperation()
}
```

This method starts a coroutine and runs the provided closure inside of that coroutine. The value that is returned from the closure is the result that you get in the `EventLoopFuture` that is returned. The closure also allows you to throw errors. If that happens, your `EventLoopFuture` will be failed.

The second piece to the puzzel is `EventLoopFuture.await()`:

```swift
let user = try User.query(on: database).first().await()
```

Note that this method is different from the `wait` method provided by NIO. You should only call it inside the closure of an `async` call (or inside any other coroutine that you happen to have started). It waits for the future result and returns it, without blocking the current thread because you are in a coroutine.

In the end, your code might look a little like this:

```swift
eventLoop.async {
    guard let user = try User.query(on: database).filter(\.$id == id).first().await() else {
        throw Abort(.notFound)
    }
    guard let id = user.id else {
        throw Abort(.internalServerError, reason: "All saved models must have an ID")
    }
    
    return try s3Client.fetch("\(id)/profile-image.png").await()
}
```

## :page_facing_up: License

All code, documents, and other resources contained in this repository is under the MIT license agreement.
