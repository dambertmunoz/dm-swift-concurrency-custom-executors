//
//  ExecutorTests.swift
//  CustomExecutorsKitTests
//
//  Created by Dambert Muñoz
//

import Testing
import Foundation
@testable import CustomExecutorsKit

@Suite("Custom Executors Tests")
struct ExecutorTests {

    // MARK: - PriorityExecutor Tests

    @Test("PriorityExecutor respects priority levels")
    func testPriorityExecutor() async throws {
        let background = PriorityExecutor.background
        let userInteractive = PriorityExecutor.userInteractive

        #expect(background.priority < userInteractive.priority)
        #expect(background.priority == .background)
        #expect(userInteractive.priority == .userInteractive)
    }

    @Test("PriorityExecutor shared instances are singleton")
    func testPriorityExecutorSingleton() {
        let first = PriorityExecutor.background
        let second = PriorityExecutor.background

        #expect(first === second)
    }

    // MARK: - DatabaseActor Tests

    @Test("DatabaseActor performs CRUD operations")
    func testDatabaseActorCRUD() async throws {
        let db = DatabaseActor()

        // Save
        await db.save(value: "test-value", forKey: "key1")

        // Fetch
        let value: String? = await db.fetch(key: "key1")
        #expect(value == "test-value")

        // Count
        let count = await db.count
        #expect(count == 1)

        // Delete
        let deleted = await db.delete(key: "key1")
        #expect(deleted == true)

        // Verify deletion
        let afterDelete: String? = await db.fetch(key: "key1")
        #expect(afterDelete == nil)
    }

    @Test("DatabaseActor handles transactions")
    func testDatabaseActorTransaction() async throws {
        let db = DatabaseActor()

        let result = await db.transaction {
            await db.save(value: 1, forKey: "counter")
            let current: Int? = await db.fetch(key: "counter")
            await db.save(value: (current ?? 0) + 1, forKey: "counter")
            return await db.fetch(key: "counter") as Int?
        }

        #expect(result == 2)
    }

    // MARK: - AudioProcessingActor Tests

    @Test("AudioProcessingActor processes audio buffers")
    func testAudioProcessing() async throws {
        let audio = AudioProcessingActor()

        let input: [Float] = [1.0, 0.5, -0.5, -1.0]
        let output = await audio.processBuffer(input)

        #expect(output.count == input.count)
        #expect(output[0] == 0.8) // 1.0 * 0.8
        #expect(output[1] == 0.4) // 0.5 * 0.8
    }

    @Test("AudioProcessingActor applies low-pass filter")
    func testLowPassFilter() async throws {
        let audio = AudioProcessingActor()

        let input: [Float] = [1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 0.0]
        let filtered = await audio.applyLowPassFilter(input, cutoff: 1000.0)

        #expect(filtered.count == input.count)
        // Filter should smooth the transition
        #expect(filtered[4] > 0.0) // Not instant drop to 0
    }

    @Test("AudioProcessingActor tracks processed samples")
    func testProcessedSamplesCount() async throws {
        let audio = AudioProcessingActor()

        _ = await audio.processBuffer([1.0, 2.0, 3.0])
        _ = await audio.processBuffer([4.0, 5.0])

        let total = await audio.totalProcessedSamples
        #expect(total == 5)
    }

    @Test("AudioProcessingActor configuration")
    func testAudioConfiguration() async throws {
        let audio = AudioProcessingActor(sampleRate: 48000.0, bufferSize: 1024)

        let config = await audio.configuration
        #expect(config.sampleRate == 48000.0)
        #expect(config.bufferSize == 1024)

        await audio.setSampleRate(96000.0)
        let newConfig = await audio.configuration
        #expect(newConfig.sampleRate == 96000.0)
    }
}
