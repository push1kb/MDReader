/// Kokoro-82M running in-process on MLX.
struct KokoroEngine: SpeechEngine {
    let voice: String

    init(voice: String) {
        self.voice = voice
    }

    var cacheIdentity: String { "kokoro:\(KokoroRuntime.modelID):\(voice)" }

    func prepare(progress: @escaping @MainActor @Sendable (Double) -> Void) async throws {
        try await KokoroRuntime.shared.load(progress: progress)
    }

    func synthesize(_ text: String) async throws -> AudioClip {
        try await KokoroRuntime.shared.synthesize(text, voice: voice)
    }
}
