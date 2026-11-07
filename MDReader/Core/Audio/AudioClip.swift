import AVFoundation

/// Mono, 32-bit float audio held in memory.
struct AudioClip: Sendable {
    var samples: [Float]
    var sampleRate: Double

    var duration: TimeInterval { Double(samples.count) / sampleRate }

    init(samples: [Float], sampleRate: Double) {
        self.samples = samples
        self.sampleRate = sampleRate
    }

    /// Plays clips back to back with `gap` seconds of silence between them.
    /// Returns the joined clip and the time at which each input clip starts.
    static func joining(_ clips: [AudioClip], gap: TimeInterval) throws -> (clip: AudioClip, starts: [TimeInterval]) {
        guard let sampleRate = clips.first?.sampleRate, clips.contains(where: { !$0.samples.isEmpty }) else {
            throw ReaderError("The text produced no audio.")
        }
        let silence = [Float](repeating: 0, count: Int(gap * sampleRate))
        var samples: [Float] = []
        var starts: [TimeInterval] = []

        for (index, clip) in clips.enumerated() {
            starts.append(Double(samples.count) / sampleRate)
            samples += clip.samples
            if !clip.samples.isEmpty, index < clips.count - 1 {
                samples += silence
            }
        }
        return (AudioClip(samples: samples, sampleRate: sampleRate), starts)
    }
}

// MARK: - Files

extension AudioClip {
    private static func format(sampleRate: Double) -> AVAudioFormat {
        AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
    }

    init(contentsOf url: URL) throws {
        let file = try AVAudioFile(forReading: url)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                            frameCapacity: AVAudioFrameCount(file.length)) else {
            throw ReaderError("Couldn't read \(url.lastPathComponent).")
        }
        try file.read(into: buffer)
        samples = Array(UnsafeBufferPointer(start: buffer.floatChannelData?[0], count: Int(buffer.frameLength)))
        sampleRate = file.processingFormat.sampleRate
    }

    /// Writes the clip as an uncompressed CAF file.
    func write(to url: URL) throws {
        let format = Self.format(sampleRate: sampleRate)
        guard !samples.isEmpty,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count))
        else { throw ReaderError("There's no audio to save.") }

        buffer.frameLength = buffer.frameCapacity
        samples.withUnsafeBufferPointer { buffer.floatChannelData![0].update(from: $0.baseAddress!, count: $0.count) }
        let file = try AVAudioFile(forWriting: url, settings: format.settings,
                                   commonFormat: .pcmFormatFloat32, interleaved: false)
        try file.write(from: buffer)
    }
}
