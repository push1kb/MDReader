import AVFoundation

/// Re-encodes generated audio as AAC in an .m4a file.
enum AudioExporter {
    static func exportM4A(from source: URL, to destination: URL) throws {
        let input = try AVAudioFile(forReading: source)
        let format = input.processingFormat
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: format.sampleRate,
            AVNumberOfChannelsKey: format.channelCount,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]

        try? FileManager.default.removeItem(at: destination)
        let output = try AVAudioFile(forWriting: destination, settings: settings,
                                     commonFormat: format.commonFormat, interleaved: format.isInterleaved)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 32_768)!
        while input.framePosition < input.length {
            try input.read(into: buffer)
            try output.write(from: buffer)
        }
    }
}
