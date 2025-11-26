//
//  PriorityExecutor.swift
//  CustomExecutorsKit
//
//  Created by Dambert Muñoz
//

import Foundation

/// An executor that runs jobs on a queue matching a specific priority level.
/// Useful when you need actors with different priority characteristics.
///
/// Example: A high-priority executor for UI-related actors,
/// and a background executor for data processing actors.
///
public final class PriorityExecutor: SerialExecutor {

    // MARK: - Priority Levels

    public enum Priority: Int, Comparable, Sendable {
        case background = 0
        case utility = 1
        case normal = 2
        case userInitiated = 3
        case userInteractive = 4

        public static func < (lhs: Priority, rhs: Priority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }

        var dispatchQoS: DispatchQoS {
            switch self {
            case .background: return .background
            case .utility: return .utility
            case .normal: return .default
            case .userInitiated: return .userInitiated
            case .userInteractive: return .userInteractive
            }
        }
    }

    // MARK: - Properties

    public let priority: Priority
    private let queue: DispatchQueue

    // MARK: - Shared Executors

    /// Shared executor pool for common priority levels
    public static let background = PriorityExecutor(priority: .background)
    public static let utility = PriorityExecutor(priority: .utility)
    public static let normal = PriorityExecutor(priority: .normal)
    public static let userInitiated = PriorityExecutor(priority: .userInitiated)
    public static let userInteractive = PriorityExecutor(priority: .userInteractive)

    // MARK: - Initialization

    /// Creates a priority executor with the specified priority level.
    /// - Parameter priority: The priority level for this executor
    public init(priority: Priority) {
        self.priority = priority
        self.queue = DispatchQueue(
            label: "com.dambertmunoz.executor.\(priority)",
            qos: priority.dispatchQoS
        )
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
}

// MARK: - Hashable

extension PriorityExecutor: Hashable {
    public static func == (lhs: PriorityExecutor, rhs: PriorityExecutor) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
