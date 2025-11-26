//
//  AudioProcessingActor.swift
//  CustomExecutorsKit
//
//  Created by Dambert Muñoz
//

import Foundation

/// An actor designed for real-time audio processing.
/// Uses a dedicated thread executor to minimize latency
/// and avoid GCD scheduling overhead.
///
/// Real-time audio has strict timing requirements:
/// - Audio callbacks must complete within buffer duration
/// - GCD can introduce unpredictable delays
/// - A dedicated thread provides consistent timing
///
public actor AudioProcessingActor {

    // MARK: - Custom Executor

    private static let executor = DedicatedThreadExecutor(
        name: "com.dambertmunoz.audio",
        qualityOfService: .userInteractive
    )

    public nonisolated var unownedExecutor: UnownedSerialExecutor {
        Self.executor.asUnownedSerialExecutor()
    }

    // MARK: - Properties

    private var sampleRate: Double = 44100.0
    private var bufferSize: Int = 512
    private var isProcessing: Bool = false
    private var processedSamples: Int = 0

    // MARK: - Initialization

    public init(sampleRate: Double = 44100.0, bufferSize: Int = 512) {
        self.sampleRate = sampleRate
        self.bufferSize = bufferSize
    }

    // MARK: - Audio Processing

    /// Processes an audio buffer. This runs on the dedicated audio thread.
    /// - Parameter samples: Array of audio samples to process
    /// - Returns: Processed audio samples
    public func processBuffer(_ samples: [Float]) -> [Float] {
        guard !samples.isEmpty else { return [] }

        isProcessing = true
        defer {
            isProcessing = false
            processedSamples += samples.count
        }

        // Example: Simple gain processing
        return samples.map { $0 * 0.8 }
    }

    /// Applies a low-pass filter to the samples.
    /// - Parameters:
    ///   - samples: Input samples
    ///   - cutoff: Cutoff frequency in Hz
    /// - Returns: Filtered samples
    public func applyLowPassFilter(_ samples: [Float], cutoff: Double) -> [Float] {
        guard samples.count > 1 else { return samples }

        let rc = 1.0 / (cutoff * 2.0 * .pi)
        let dt = 1.0 / sampleRate
        let alpha = Float(dt / (rc + dt))

        var output = [Float](repeating: 0, count: samples.count)
        output[0] = samples[0]

        for i in 1..<samples.count {
            output[i] = output[i-1] + alpha * (samples[i] - output[i-1])
        }

        return output
    }

    // MARK: - Configuration

    /// Updates the sample rate.
    public func setSampleRate(_ rate: Double) {
        sampleRate = rate
    }

    /// Updates the buffer size.
    public func setBufferSize(_ size: Int) {
        bufferSize = size
    }

    // MARK: - Status

    /// Returns true if currently processing audio.
    public var isCurrentlyProcessing: Bool {
        isProcessing
    }

    /// Returns the total number of samples processed.
    public var totalProcessedSamples: Int {
        processedSamples
    }

    /// Returns the current configuration.
    public var configuration: (sampleRate: Double, bufferSize: Int) {
        (sampleRate, bufferSize)
    }
}
