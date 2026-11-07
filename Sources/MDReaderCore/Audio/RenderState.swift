import AudioToolbox

/// The samples and play position shared between the main actor and the real-time render callback.
///
/// The render callback must never lock or allocate, so this is plain memory: aligned 64-bit and
/// `Bool` loads and stores are atomic on Apple Silicon, and samples are only swapped while the
/// engine is stopped.
final class RenderState: @unchecked Sendable {
    private var samples = UnsafeMutableBufferPointer<Float>(start: nil, count: 0)
    var position = 0
    var isPlaying = false
    /// Set by the render thread when the end is reached.
    var didFinish = false

    var length: Int { samples.count }

    deinit {
        samples.deallocate()
    }

    func load(_ newSamples: [Float]) {
        unload()
        samples = .allocate(capacity: newSamples.count)
        _ = samples.initialize(from: newSamples)
    }

    func unload() {
        isPlaying = false
        didFinish = false
        position = 0
        samples.deallocate()
        samples = UnsafeMutableBufferPointer(start: nil, count: 0)
    }

    /// Copies the next `frameCount` samples into every output channel, padding with silence.
    func render(frameCount: Int, into bufferList: UnsafeMutablePointer<AudioBufferList>) -> OSStatus {
        let start = position
        let count = isPlaying ? max(0, min(frameCount, samples.count - start)) : 0

        for buffer in UnsafeMutableAudioBufferListPointer(bufferList) {
            guard let output = buffer.mData?.assumingMemoryBound(to: Float.self) else { continue }
            if count > 0, let source = samples.baseAddress {
                output.update(from: source + start, count: count)
            }
            (output + count).update(repeating: 0, count: frameCount - count)
        }

        if isPlaying {
            position = start + count
            if position >= samples.count {
                isPlaying = false
                didFinish = true
            }
        }
        return noErr
    }
}
