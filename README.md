# Custom Executors for Swift Actors: Take Full Control

[![Swift](https://img.shields.io/badge/Swift-5.9+-F05138.svg?style=flat&logo=swift)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-17.0+-007AFF.svg?style=flat&logo=apple)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> Stop letting the Swift runtime decide where your actor code runs.

---

## The Problem

Swift actors provide excellent thread safety guarantees. But there's a catch most developers don't know about: **you have zero control over where your code actually executes.**

By default, actors run on the cooperative thread pool. The runtime picks a thread. You hope for the best.

For most apps, this works fine. But some scenarios demand explicit control:

| Scenario | Why Default Fails |
|----------|-------------------|
| **Database access** | SQLite, Realm require same-thread access |
| **Real-time audio** | GCD scheduling latency breaks audio callbacks |
| **Legacy integration** | Existing code expects a specific queue |
| **Priority isolation** | Background work shouldn't compete with UI |

## The Solution: Custom Executors

Swift 5.9 introduced the `SerialExecutor` protocol. Implement it, and you control exactly where your actor's code runs.

The pattern is simple:

```swift
actor MyActor {
    // 1. Create your executor
    private static let executor = MyCustomExecutor()

    // 2. Tell the actor to use it
    nonisolated var unownedExecutor: UnownedSerialExecutor {
        Self.executor.asUnownedSerialExecutor()
    }

    // 3. All methods now run on YOUR executor
    func doWork() {
        // Runs where YOU decide
    }
}
```

---

## Quick Start

### Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/dambertmunoz/dm-swift-concurrency-custom-executors", from: "1.0.0")
]
```

### Run the Demo

Clone and run to see all executors in action:

```bash
git clone https://github.com/dambertmunoz/dm-swift-concurrency-custom-executors.git
cd dm-swift-concurrency-custom-executors
swift run Demo
```

You'll see output demonstrating each executor type with real operations.

---

## Three Executors You'll Actually Use

### 1. SerialDispatchQueueExecutor

**The workhorse.** Runs actor code on a specific serial dispatch queue.

```swift
public final class SerialDispatchQueueExecutor: SerialExecutor {
    private let queue: DispatchQueue

    public init(label: String, qos: DispatchQoS = .userInitiated) {
        self.queue = DispatchQueue(label: label, qos: qos)
    }

    public func enqueue(_ job: consuming ExecutorJob) {
        let unownedJob = UnownedJob(job)
        let unownedExecutor = asUnownedSerialExecutor()

        queue.async {
            unownedJob.runSynchronously(on: unownedExecutor)
        }
    }

    public func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }
}
```

**When to use:**
- Database actors (SQLite, Realm, Core Data)
- File I/O operations
- Wrapping legacy thread-bound APIs

### 2. DedicatedThreadExecutor

**For when GCD isn't enough.** Owns an entire thread. No scheduling delays.

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
        // Runs on dedicated thread - no GCD overhead
        samples.map { $0 * 0.8 }
    }
}
```

**When to use:**
- Real-time audio processing
- Game loops with strict timing
- Any latency-critical path

**Warning:** Don't create many of these. Threads are expensive.

### 3. PriorityExecutor

**Pre-configured executors for different QoS levels.**

```swift
// Background work - won't compete with UI
actor SyncActor {
    nonisolated var unownedExecutor: UnownedSerialExecutor {
        PriorityExecutor.background.asUnownedSerialExecutor()
    }
}

// UI-critical - highest priority
actor UIStateActor {
    nonisolated var unownedExecutor: UnownedSerialExecutor {
        PriorityExecutor.userInteractive.asUnownedSerialExecutor()
    }
}
```

Available levels: `background`, `utility`, `normal`, `userInitiated`, `userInteractive`

---

## Real-World Example: Database Actor

Here's a production-ready database actor. All operations run on the same queue—exactly what SQLite needs:

```swift
public actor DatabaseActor {
    private static let executor = SerialDispatchQueueExecutor(
        label: "com.app.database",
        qos: .userInitiated
    )

    public nonisolated var unownedExecutor: UnownedSerialExecutor {
        Self.executor.asUnownedSerialExecutor()
    }

    private var storage: [String: Any] = [:]

    public func fetch<T>(key: String) async -> T? {
        storage[key] as? T
    }

    public func save<T>(value: T, forKey key: String) async {
        storage[key] = value
    }

    public func transaction<T>(_ ops: () async throws -> T) async rethrows -> T {
        // All operations guaranteed sequential on same queue
        try await ops()
    }
}
```

Usage:

```swift
let db = DatabaseActor()

await db.save(value: "Dambert", forKey: "name")
let name: String? = await db.fetch(key: "name")

await db.transaction {
    await db.save(value: 1, forKey: "counter")
    let current: Int = await db.fetch(key: "counter") ?? 0
    await db.save(value: current + 1, forKey: "counter")
}
```

---

## When NOT to Use Custom Executors

The cooperative thread pool is highly optimized. **Don't use custom executors just because you can.**

Use them when:
- ✅ Your dependency requires same-thread access
- ✅ Latency requirements exceed GCD capabilities
- ✅ You need explicit priority control
- ✅ Integrating with thread-bound legacy code

Don't use them when:
- ❌ Default behavior works fine
- ❌ You're optimizing without measuring
- ❌ You haven't identified a real problem

---

## Project Structure

```
Sources/CustomExecutorsKit/
├── Core/Executors/
│   ├── SerialDispatchQueueExecutor.swift
│   ├── DedicatedThreadExecutor.swift
│   └── PriorityExecutor.swift
└── Domain/Actors/
    ├── DatabaseActor.swift
    └── AudioProcessingActor.swift

Examples/Demo/
└── main.swift          # Run with: swift run Demo

Tests/CustomExecutorsKitTests/
└── ExecutorTests.swift
```

---

## Key Takeaways

1. **Custom executors give you control** over where actor code runs
2. **SerialDispatchQueueExecutor** handles most threading requirements
3. **DedicatedThreadExecutor** is for real-time scenarios only
4. **PriorityExecutor** provides easy QoS-based isolation
5. **Measure first** - the default pool is already optimized

---

## Requirements

- iOS 17.0+ / macOS 14.0+
- Swift 5.9+
- Xcode 15.0+

## Author

**Dambert Muñoz** — Senior iOS Engineer

- [GitHub](https://github.com/dambertmunoz)
- [LinkedIn](https://linkedin.com/in/dambert-m-4b772397)

## License

MIT License - see [LICENSE](LICENSE) for details.
