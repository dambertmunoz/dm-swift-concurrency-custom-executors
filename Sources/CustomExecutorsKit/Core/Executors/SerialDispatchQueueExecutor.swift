//
//  SerialDispatchQueueExecutor.swift
//  CustomExecutorsKit
//
//  Created by Dambert Muñoz
//

import Foundation

/// A custom executor that runs actor code on a specific serial dispatch queue.
/// This allows you to control exactly which queue your actor's code runs on.
///
/// Use cases:
/// - Database actors that need to run on a dedicated background queue
/// - Legacy code integration where a specific queue is required
/// - Performance isolation for heavy computational actors
///
public final class SerialDispatchQueueExecutor: SerialExecutor {

    // MARK: - Properties

    private let queue: DispatchQueue

    // MARK: - Initialization

    /// Creates an executor backed by a new serial dispatch queue.
    /// - Parameters:
    ///   - label: The label for the dispatch queue (useful for debugging)
    ///   - qos: Quality of service for the queue. Defaults to `.userInitiated`
    public init(label: String, qos: DispatchQoS = .userInitiated) {
        self.queue = DispatchQueue(label: label, qos: qos)
    }

    /// Creates an executor backed by an existing serial dispatch queue.
    /// - Parameter queue: The dispatch queue to use. Must be serial.
    /// - Warning: Using a concurrent queue will lead to undefined behavior.
    public init(queue: DispatchQueue) {
        self.queue = queue
    }

    // MARK: - SerialExecutor Conformance

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

    /// Checks if the current execution context is on this executor's queue.
    /// Useful for assertions and debugging.
    public func isCurrent() -> Bool {
        let key = DispatchSpecificKey<Bool>()
        queue.setSpecific(key: key, value: true)
        defer { queue.setSpecific(key: key, value: nil) }
        return DispatchQueue.getSpecific(key: key) == true
    }
}

// MARK: - Hashable

extension SerialDispatchQueueExecutor: Hashable {
    public static func == (lhs: SerialDispatchQueueExecutor, rhs: SerialDispatchQueueExecutor) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
