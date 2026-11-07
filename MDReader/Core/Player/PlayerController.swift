import Foundation
import Observation

/// The text being read, its generated audio, and playback. One instance backs every window.
@MainActor
@Observable
final class PlayerController {
    enum Phase: Equatable {
        case empty
        /// Downloading (first run only) and loading the voice model.
        case preparingModel(progress: Double)
        case generating(done: Int, total: Int)
        case ready
        case failed(ReaderError)
    }

    static let skipInterval: TimeInterval = 10
    static let speedRange: ClosedRange<Float> = 0.5...2.5
    static let speedStep: Float = 0.25
    /// "Previous paragraph" restarts the current one unless you're within this long of its start.
    static let previousParagraphGrace: TimeInterval = 1.5
    static let paragraphGap: TimeInterval = 0.35

    var text = ""
    var phase = Phase.empty
    var chunks: [String] = []
    var chunkStarts: [TimeInterval] = []
    var duration: TimeInterval = 0
    var currentTime: TimeInterval = 0
    var isPlaying = false
    /// The generated audio on disk, for export.
    var audioURL: URL?

    var rate: Float {
        didSet {
            // @Observable makes this a computed property, so assigning here re-enters didSet.
            let clamped = rate.clamped(to: Self.speedRange)
            guard clamped == rate else { rate = clamped; return }
            playback.rate = rate
            defaults.set(rate, forKey: SettingsKey.playbackSpeed)
            nowPlaying.update(from: self)
        }
    }

    var volume: Float {
        didSet {
            playback.volume = volume
            voicePreview.volume = volume
            defaults.set(volume, forKey: SettingsKey.volume)
        }
    }

    let voicePreview: VoicePreviewer

    let cache: AudioCache
    let defaults: UserDefaults
    let playback = AudioPlayback()
    private let nowPlaying = NowPlayingBridge()
    @ObservationIgnored var loadedKey: String?
    @ObservationIgnored var generation: Task<Void, Never>?
    @ObservationIgnored private var ticker: Task<Void, Never>?

    init(cache: AudioCache = AudioCache(), defaults: UserDefaults = .standard) {
        self.cache = cache
        self.defaults = defaults
        voicePreview = VoicePreviewer(cache: cache)
        rate = Self.storedFloat(SettingsKey.playbackSpeed, in: defaults) ?? 1
        volume = Self.storedFloat(SettingsKey.volume, in: defaults) ?? 1

        playback.rate = rate
        playback.volume = volume
        voicePreview.volume = volume
        playback.onFinish = { [weak self] in self?.syncWithPlayback() }
        voicePreview.willPlay = { [weak self] in self?.pause() }
        nowPlaying.attach(to: self)
    }

    var hasAudio: Bool { phase == .ready && duration > 0 }

    var isGenerating: Bool {
        switch phase {
        case .preparingModel, .generating: true
        default: false
        }
    }

    var currentChunkIndex: Int? {
        guard hasAudio, !chunkStarts.isEmpty else { return nil }
        return chunkStarts.lastIndex { $0 <= currentTime + 0.05 } ?? 0
    }

    /// What the phase returns to once generation stops or an error is dismissed.
    var restingPhase: Phase { loadedKey == nil ? .empty : .ready }

    // MARK: Transport

    func togglePlayPause() {
        isPlaying ? pause() : play()
    }

    func pause() {
        playback.pause()
        syncWithPlayback()
    }

    func stop() {
        generation?.cancel()
        if isGenerating { phase = restingPhase }
        playback.stop()
        syncWithPlayback()
    }

    func seek(to time: TimeInterval) {
        guard hasAudio else { return }
        playback.seek(to: time.clamped(to: 0...duration))
        syncWithPlayback()
    }

    func skip(by seconds: TimeInterval) {
        seek(to: playback.currentTime + seconds)
    }

    func previousParagraph() {
        guard let index = currentChunkIndex else { return }
        let isNearStart = playback.currentTime - chunkStarts[index] <= Self.previousParagraphGrace
        seek(to: chunkStarts[isNearStart ? max(index - 1, 0) : index])
    }

    func nextParagraph() {
        guard let index = currentChunkIndex, chunkStarts.indices.contains(index + 1) else { return }
        seek(to: chunkStarts[index + 1])
    }

    func jump(toChunk index: Int) {
        guard chunkStarts.indices.contains(index) else { return }
        seek(to: chunkStarts[index])
        if !isPlaying { startPlayback() }
    }

    func adjustRate(by delta: Float) {
        rate = ((rate + delta) * 100).rounded() / 100
    }

    func dismissError() {
        if case .failed = phase { phase = restingPhase }
    }

    func clear() {
        stop()
        playback.unload()
        text = ""
        loadedKey = nil
        audioURL = nil
        chunks = []
        chunkStarts = []
        duration = 0
        phase = .empty
        syncWithPlayback()
    }

    func exportAudio(to destination: URL) async throws {
        guard let source = audioURL else { throw ReaderError("Generate audio first.") }
        try await Task.detached(priority: .userInitiated) {
            try AudioExporter.exportM4A(from: source, to: destination)
        }.value
    }

    // MARK: Playback state

    func startPlayback() {
        do {
            try playback.play()
        } catch {
            phase = .failed(ReaderError("Audio output failed: \(error.localizedDescription)"))
        }
        syncWithPlayback()
        startTicker()
    }

    func syncWithPlayback() {
        isPlaying = playback.isPlaying
        currentTime = playback.currentTime
        if !isPlaying { ticker?.cancel() }
        nowPlaying.update(from: self)
    }

    private func startTicker() {
        ticker?.cancel()
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let self, self.playback.isPlaying else { return }
                self.currentTime = self.playback.currentTime
            }
        }
    }

    private static func storedFloat(_ key: String, in defaults: UserDefaults) -> Float? {
        (defaults.object(forKey: key) as? NSNumber)?.floatValue
    }
}
