import Foundation
import HuggingFace
import MLXAudioCore
import MLXAudioTTS

/// Owns the one loaded Kokoro model.
///
/// An actor because a model instance must be used serially, and so inference stays off the
/// main thread. The weights are downloaded from Hugging Face on first use into
/// `AppFolder.models`, then read from disk.
actor KokoroRuntime {
    static let shared = KokoroRuntime()
    static let modelID = "mlx-community/Kokoro-82M-bf16"

    /// The model isn't `Sendable`; it's only ever touched inside this actor.
    private struct Loaded: @unchecked Sendable {
        let model: SpeechGenerationModel
    }

    private var loaded: Loaded?
    private var loading: Task<Loaded, Error>?

    func load(progress: @escaping @MainActor @Sendable (Double) -> Void) async throws {
        _ = try await loadedModel(progress: progress)
    }

    func synthesize(_ text: String, voice: String) async throws -> AudioClip {
        let model = try await loadedModel(progress: { _ in }).model
        let audio = try await model.generate(text: text, voice: voice, refAudio: nil, refText: nil, language: nil)
        return AudioClip(samples: audio.asArray(Float.self), sampleRate: Double(model.sampleRate))
    }

    private func loadedModel(progress: @escaping @MainActor @Sendable (Double) -> Void) async throws -> Loaded {
        if let loaded { return loaded }
        if let loading { return try await loading.value }

        let task = Task { Loaded(model: try await Self.downloadAndLoad(progress: progress)) }
        loading = task
        defer { loading = nil }
        let model = try await task.value
        loaded = model
        return model
    }

    private static func downloadAndLoad(progress: @escaping @MainActor @Sendable (Double) -> Void) async throws -> SpeechGenerationModel {
        guard let repo = Repo.ID(rawValue: modelID) else { throw ReaderError("Invalid model id \(modelID).") }
        let cache = HubCache(cacheDirectory: AppFolder.models)
        let directory: URL
        do {
            directory = try await ModelUtils.resolveOrDownloadModel(
                client: HubClient(cache: cache),
                cache: cache,
                repoID: repo,
                requiredExtension: "safetensors",
                progressHandler: { progress($0.fractionCompleted) }
            )
        } catch {
            throw ReaderError("Couldn't download the voice model. Check your connection and press Play again.")
        }
        return try await KokoroModel.fromModelDirectory(directory, textProcessor: KokoroMultilingualProcessor(cache: cache))
    }
}
