//
//  DatabaseActor.swift
//  CustomExecutorsKit
//
//  Created by Dambert Muñoz
//

import Foundation

/// An actor that runs all database operations on a dedicated serial queue.
/// This ensures database access is never performed on the main thread
/// and all operations are serialized to prevent data races.
///
/// The custom executor guarantees that all database operations happen
/// on the same queue, which is required by many database libraries
/// (SQLite, Realm, etc.) for thread-safety.
///
public actor DatabaseActor {

    // MARK: - Custom Executor

    private static let executor = SerialDispatchQueueExecutor(
        label: "com.dambertmunoz.database",
        qos: .userInitiated
    )

    public nonisolated var unownedExecutor: UnownedSerialExecutor {
        Self.executor.asUnownedSerialExecutor()
    }

    // MARK: - Properties

    private var storage: [String: Any] = [:]
    private var transactionCount: Int = 0

    // MARK: - Initialization

    public init() {}

    // MARK: - CRUD Operations

    /// Fetches a value from the database.
    /// - Parameter key: The key to fetch
    /// - Returns: The value if found, nil otherwise
    public func fetch<T>(key: String) async -> T? {
        // Simulate database read latency
        try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
        return storage[key] as? T
    }

    /// Saves a value to the database.
    /// - Parameters:
    ///   - value: The value to save
    ///   - key: The key to save under
    public func save<T>(value: T, forKey key: String) async {
        // Simulate database write latency
        try? await Task.sleep(nanoseconds: 2_000_000) // 2ms
        storage[key] = value
    }

    /// Deletes a value from the database.
    /// - Parameter key: The key to delete
    /// - Returns: True if the key existed and was deleted
    @discardableResult
    public func delete(key: String) async -> Bool {
        try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
        return storage.removeValue(forKey: key) != nil
    }

    // MARK: - Transaction Support

    /// Executes a block of operations within a transaction.
    /// All operations within the transaction are guaranteed to run
    /// sequentially on the database queue.
    ///
    /// - Parameter operations: The operations to perform
    /// - Returns: The result of the operations
    public func transaction<T>(_ operations: () async throws -> T) async rethrows -> T {
        transactionCount += 1
        defer { transactionCount -= 1 }

        return try await operations()
    }

    /// Returns true if currently executing within a transaction.
    public var isInTransaction: Bool {
        transactionCount > 0
    }

    /// Returns the number of stored items.
    public var count: Int {
        storage.count
    }
}
