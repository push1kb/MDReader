/// Turns plain text into audio.
protocol SpeechEngine: Sendable {
    /// Identifies the engine, model and voice. Part of the audio cache key.
    var cacheIdentity: String { get }

    /// Gets ready to speak (e.g. downloads the model), reporting progress from 0 to 1.
    func prepare(progress: @escaping @MainActor @Sendable (Double) -> Void) async throws

    func synthesize(_ text: String) async throws -> AudioClip
}
