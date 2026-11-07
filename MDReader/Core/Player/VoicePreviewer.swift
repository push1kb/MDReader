import AVFoundation
import Observation

/// Speaks a short sample of a voice, for the Voice tab's Test button.
/// Each voice's sample is generated once and then played from the cache.
@MainActor
@Observable
final class VoicePreviewer {
    enum State: Equatable {
        case idle
        case preparingModel(progress: Double)
        case generating
        case playing
        case failed(String)
    }

    private(set) var state = State.idle
    /// The voice `state` refers to.
    private(set) var voiceID: String?

    @ObservationIgnored var volume: Float = 1
    /// Called before a sample starts, so the document can pause.
    @ObservationIgnored var willPlay: () -> Void = {}

    private let cache: AudioCache
    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private var player: AVAudioPlayer?

    init(cache: AudioCache) {
        self.cache = cache
    }

    /// Whether a sample of `voiceID` is being prepared or played.
    func isBusy(with voiceID: String) -> Bool {
        switch state {
        case .idle, .failed: false
        case .preparingModel, .generating, .playing: self.voiceID == voiceID
        }
    }

    func play(_ voiceID: String) {
        stop()
        willPlay()
        self.voiceID = voiceID
        task = Task {
            do {
                let player = try AVAudioPlayer(contentsOf: try await sample(of: voiceID))
                try Task.checkCancellation()
                player.volume = volume
                player.play()
                self.player = player
                state = .playing
                while player.isPlaying {
                    try await Task.sleep(for: .milliseconds(100))
                }
                state = .idle
            } catch is CancellationError {
                // `stop()` already reset the state.
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        player?.stop()
        player = nil
        state = .idle
    }

    private func sample(of voiceID: String) async throws -> URL {
        let url = cache.previewURL(for: voiceID)
        guard !FileManager.default.fileExists(atPath: url.path) else { return url }

        let engine = KokoroEngine(voice: voiceID)
        state = .preparingModel(progress: 0)
        try await engine.prepare { [weak self] progress in
            guard let self, case .preparingModel = self.state else { return }
            self.state = .preparingModel(progress: progress)
        }
        try Task.checkCancellation()

        state = .generating
        try await engine.synthesize(KokoroVoices.sampleText(for: voiceID)).write(to: url)
        return url
    }
}
