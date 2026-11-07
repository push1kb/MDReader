/// Kokoro-82M running in-process on MLX.
public struct KokoroEngine: SpeechEngine {
    public let voice: String

    public init(voice: String) {
        self.voice = voice
    }

    public var cacheIdentity: String { "kokoro:\(KokoroRuntime.modelID):\(voice)" }

    public func prepare(progress: @escaping @MainActor @Sendable (Double) -> Void) async throws {
        try await KokoroRuntime.shared.load(progress: progress)
    }

    public func synthesize(_ text: String) async throws -> AudioClip {
        try await KokoroRuntime.shared.synthesize(text, voice: voice)
    }
}
