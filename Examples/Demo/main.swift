//
//  main.swift
//  CustomExecutorsKit Demo
//
//  Created by Dambert Muñoz
//
//  Run with: swift run Demo
//

import Foundation
import CustomExecutorsKit

// MARK: - Demo Entry Point

print("""
╔══════════════════════════════════════════════════════╗
║     Custom Executors for Swift Actors - Demo       ║
║     by Dambert Muñoz                                ║
╚══════════════════════════════════════════════════════╝
""")

@main
struct DemoApp {
    static func main() async {
        await runDatabaseActorDemo()
        await runAudioProcessingDemo()
        await runPriorityExecutorDemo()
        
        print("\n✅ All demos completed!")
    }
}

// MARK: - Database Actor Demo

func runDatabaseActorDemo() async {
    print("\n┌──────────────────────────────────────────────────┐")
    print("│ Demo 1: DatabaseActor                           │")
    print("│ Uses: SerialDispatchQueueExecutor               │")
    print("└──────────────────────────────────────────────────┘")
    
    let db = DatabaseActor()
    
    // Save some data
    print("\n➤ Saving user data...")
    await db.save(value: "Dambert Muñoz", forKey: "user_name")
    await db.save(value: 28, forKey: "user_age")
    await db.save(value: ["Swift", "iOS", "Concurrency"], forKey: "user_skills")
    
    // Fetch data
    print("➤ Fetching user data...")
    let name: String? = await db.fetch(key: "user_name")
    let age: Int? = await db.fetch(key: "user_age")
    let skills: [String]? = await db.fetch(key: "user_skills")
    
    print("")
    print("   Name: \(name ?? "N/A")")
    print("   Age: \(age ?? 0)")
    print("   Skills: \(skills?.joined(separator: ", ") ?? "N/A")")
    
    // Transaction demo
    print("\n➤ Running transaction...")
    let result = await db.transaction {
        await db.save(value: 0, forKey: "counter")
        for i in 1...5 {
            let current: Int = await db.fetch(key: "counter") ?? 0
            await db.save(value: current + i, forKey: "counter")
        }
        return await db.fetch(key: "counter") as Int?
    }
    print("   Transaction result (1+2+3+4+5): \(result ?? 0)")
    
    // Count
    let count = await db.count
    print("\n   Total items in database: \(count)")
    
    print("\n✓ DatabaseActor demo complete")
}

// MARK: - Audio Processing Demo

func runAudioProcessingDemo() async {
    print("\n┌──────────────────────────────────────────────────┐")
    print("│ Demo 2: AudioProcessingActor                    │")
    print("│ Uses: DedicatedThreadExecutor                   │")
    print("└──────────────────────────────────────────────────┘")
    
    let audio = AudioProcessingActor(sampleRate: 44100.0, bufferSize: 512)
    
    // Show configuration
    let config = await audio.configuration
    print("\n➤ Audio configuration:")
    print("   Sample rate: \(config.sampleRate) Hz")
    print("   Buffer size: \(config.bufferSize) samples")
    
    // Process a test buffer (simulated sine wave)
    print("\n➤ Processing audio buffer...")
    let inputSamples: [Float] = (0..<16).map { i in
        sin(Float(i) * 0.5) // Simple sine wave
    }
    
    print("   Input samples (first 8): \(inputSamples.prefix(8).map { String(format: "%.2f", $0) })")
    
    let outputSamples = await audio.processBuffer(inputSamples)
    print("   Output samples (gain 0.8): \(outputSamples.prefix(8).map { String(format: "%.2f", $0) })")
    
    // Apply low-pass filter
    print("\n➤ Applying low-pass filter (1000 Hz cutoff)...")
    let filtered = await audio.applyLowPassFilter(inputSamples, cutoff: 1000.0)
    print("   Filtered samples: \(filtered.prefix(8).map { String(format: "%.2f", $0) })")
    
    // Stats
    let totalProcessed = await audio.totalProcessedSamples
    print("\n   Total samples processed: \(totalProcessed)")
    
    print("\n✓ AudioProcessingActor demo complete")
}

// MARK: - Priority Executor Demo

func runPriorityExecutorDemo() async {
    print("\n┌──────────────────────────────────────────────────┐")
    print("│ Demo 3: PriorityExecutor                        │")
    print("│ Shows: Different priority levels                │")
    print("└──────────────────────────────────────────────────┘")
    
    print("\n➤ Available priority levels:")
    print("")
    print("   ┌───────────────────┬──────────┬─────────────────────────┐")
    print("   │ Priority          │ Level    │ Use Case                │")
    print("   ├───────────────────┼──────────┼─────────────────────────┤")
    print("   │ background        │ 0        │ Sync, analytics         │")
    print("   │ utility           │ 1        │ Data processing         │")
    print("   │ normal            │ 2        │ Standard operations     │")
    print("   │ userInitiated     │ 3        │ User-triggered tasks    │")
    print("   │ userInteractive   │ 4        │ UI updates, animations  │")
    print("   └───────────────────┴──────────┴─────────────────────────┘")
    
    print("\n➤ Comparing priorities:")
    let bg = PriorityExecutor.background
    let ui = PriorityExecutor.userInteractive
    
    print("   background < userInteractive: \(bg.priority < ui.priority)")
    print("   background level: \(bg.priority.rawValue)")
    print("   userInteractive level: \(ui.priority.rawValue)")
    
    print("\n➤ Usage example:")
    print("""
   
   actor BackgroundSyncActor {
       nonisolated var unownedExecutor: UnownedSerialExecutor {
           PriorityExecutor.background.asUnownedSerialExecutor()
       }
   }
   
   actor UIStateActor {
       nonisolated var unownedExecutor: UnownedSerialExecutor {
           PriorityExecutor.userInteractive.asUnownedSerialExecutor()
       }
   }
   """)
    
    print("\n✓ PriorityExecutor demo complete")
}
