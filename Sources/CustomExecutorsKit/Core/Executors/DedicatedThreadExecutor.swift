//
//  DedicatedThreadExecutor.swift
//  CustomExecutorsKit
//
//  Created by Dambert Muñoz
//

import Foundation

/// An executor that runs actor code on a dedicated background thread.
/// Unlike dispatch queues, this executor owns its thread entirely.
///
/// Use cases:
/// - Real-time audio processing where thread priority must be controlled
/// - Game loops requiring consistent frame timing
/// - Low-latency operations where GCD overhead is unacceptable
///
/// - Warning: Creating many dedicated threads can exhaust system resources.
///   Use sparingly and only when dispatch queues don't meet your needs.
///
public final class DedicatedThreadExecutor: SerialExecutor, @unchecked Sendable {

    // MARK: - Properties

    private let thread: Thread
    private let runLoop: CFRunLoop
    private let source: CFRunLoopSource
    private var pendingJobs: [UnownedJob] = []
    private let lock = NSLock()
    private var isRunning = true

    // MARK: - Initialization

    /// Creates a new executor with its own dedicated thread.
    /// - Parameters:
    ///   - name: Name for the thread (visible in debugger)
    ///   - qualityOfService: Thread QoS. Defaults to `.userInitiated`
    public init(name: String, qualityOfService: QualityOfService = .userInitiated) {
        var runLoopRef: CFRunLoop!
        let semaphore = DispatchSemaphore(value: 0)

        var sourceContext = CFRunLoopSourceContext()
        sourceContext.version = 0

        self.source = CFRunLoopSourceCreate(nil, 0, &sourceContext)!

        self.thread = Thread { [source] in
            runLoopRef = CFRunLoopGetCurrent()
            CFRunLoopAddSource(runLoopRef, source, .defaultMode)
            semaphore.signal()

            while !Thread.current.isCancelled {
                CFRunLoopRunInMode(.defaultMode, 0.1, false)
            }
        }

        thread.name = name
        thread.qualityOfService = qualityOfService
        thread.start()

        semaphore.wait()
        self.runLoop = runLoopRef
    }

    deinit {
        shutdown()
    }

    // MARK: - SerialExecutor Conformance

    public func enqueue(_ job: consuming ExecutorJob) {
        let unownedJob = UnownedJob(job)

        lock.lock()
        guard isRunning else {
            lock.unlock()
            return
        }
        pendingJobs.append(unownedJob)
        lock.unlock()

        let executor = asUnownedSerialExecutor()

        CFRunLoopPerformBlock(runLoop, CFRunLoopMode.defaultMode.rawValue) { [weak self] in
            guard let self = self else { return }

            self.lock.lock()
            let jobs = self.pendingJobs
            self.pendingJobs.removeAll()
            self.lock.unlock()

            for job in jobs {
                job.runSynchronously(on: executor)
            }
        }

        CFRunLoopSourceSignal(source)
        CFRunLoopWakeUp(runLoop)
    }

    public func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }

    // MARK: - Public Methods

    /// Shuts down the executor and releases the dedicated thread.
    /// After calling this, the executor can no longer process jobs.
    public func shutdown() {
        lock.lock()
        isRunning = false
        lock.unlock()

        thread.cancel()
        CFRunLoopWakeUp(runLoop)
    }

    /// Returns true if the current thread is this executor's dedicated thread.
    public var isCurrentThread: Bool {
        Thread.current == thread
    }
}

// MARK: - Hashable

extension DedicatedThreadExecutor: Hashable {
    public static func == (lhs: DedicatedThreadExecutor, rhs: DedicatedThreadExecutor) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
