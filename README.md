# Custom Executors for Swift Actors

[![Swift](https://img.shields.io/badge/Swift-5.9+-F05138.svg?style=flat&logo=swift)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-17.0+-007AFF.svg?style=flat&logo=apple)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Control where and how your Swift actors execute their code.

## The Problem

By default, Swift actors run on the cooperative thread pool. You have no control over which thread or queue executes your actor's code. This becomes a problem when:

- Your database library requires all calls from the same thread
- You need real-time performance that GCD can't guarantee
- You're integrating with legacy code that expects a specific queue
- You need different actors to run at different priority levels

## The Solution

Swift 5.9 introduced custom executors. By implementing `SerialExecutor`, you can control exactly where your actor code runs.

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/dambertmunoz/dm-swift-concurrency-custom-executors", from: "1.0.0")
]
```

## Executors Included

### SerialDispatchQueueExecutor

Runs actor code on a specific serial dispatch queue.

```swift
actor DatabaseActor {
    private static let executor = SerialDispatchQueueExecutor(
        label: "com.app.database",
        qos: .userInitiated
    )

    nonisolated var unownedExecutor: UnownedSerialExecutor {
        Self.executor.asUnownedSerialExecutor()
    }

    func query(_ sql: String) async -> [Row] {
        // Always runs on the database queue
    }
}
```

### DedicatedThreadExecutor

Runs actor code on its own dedicated thread. Use when GCD overhead is unacceptable.

```swift
actor AudioProcessor {
    private static let executor = DedicatedThreadExecutor(
        name: "com.app.audio",
        qualityOfService: .userInteractive
    )

    nonisolated var unownedExecutor: UnownedSerialExecutor {
        Self.executor.asUnownedSerialExecutor()
    }

    func processBuffer(_ samples: [Float]) -> [Float] {
        // Runs on dedicated audio thread
    }
}
```

### PriorityExecutor

Pre-configured executors for different priority levels.

```swift
actor BackgroundSync {
    nonisolated var unownedExecutor: UnownedSerialExecutor {
        PriorityExecutor.background.asUnownedSerialExecutor()
    }
}

actor UIStateManager {
    nonisolated var unownedExecutor: UnownedSerialExecutor {
        PriorityExecutor.userInteractive.asUnownedSerialExecutor()
    }
}
```

## How It Works

1. Implement `SerialExecutor` protocol
2. Store jobs and execute them on your chosen context
3. Override `unownedExecutor` in your actor to return your executor

```swift
public final class MyExecutor: SerialExecutor {
    public func enqueue(_ job: consuming ExecutorJob) {
        let unownedJob = UnownedJob(job)
        let executor = asUnownedSerialExecutor()

        // Run on your context
        myQueue.async {
            unownedJob.runSynchronously(on: executor)
        }
    }

    public func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }
}
```

## When to Use Custom Executors

| Use Case | Executor |
|----------|----------|
| Database operations | `SerialDispatchQueueExecutor` |
| Real-time audio/video | `DedicatedThreadExecutor` |
| Background sync | `PriorityExecutor.background` |
| UI-critical operations | `PriorityExecutor.userInteractive` |
| Legacy API integration | `SerialDispatchQueueExecutor` with existing queue |

## When NOT to Use

- Default actor behavior is sufficient
- You don't have specific threading requirements
- You're not experiencing performance issues

The cooperative thread pool is highly optimized. Only use custom executors when you have a concrete reason.

## Requirements

- iOS 17.0+
- macOS 14.0+
- Swift 5.9+

## Author

**Dambert Muñoz** - Senior iOS Engineer

- [GitHub](https://github.com/dambertmunoz)
- [LinkedIn](https://linkedin.com/in/dambert-m-4b772397)

## License

MIT License - see [LICENSE](LICENSE) for details.
