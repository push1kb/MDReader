import Foundation

extension PlayerController {
    /// Plays the text, first generating its audio — or loading it from the cache — if the text
    /// or voice changed since the last time.
    public func play() {
        voicePreview.stop()

        let settings = SpeechSettings(defaults: defaults)
        let chunks = MarkdownSanitizer(codeBlockMode: settings.codeBlockMode).paragraphs(from: text)
        guard !chunks.isEmpty else {
            phase = .failed(ReaderError("Nothing to read — paste some Markdown first."))
            return
        }

        let engine = KokoroEngine(voice: settings.voice)
        let key = AudioCache.key(for: chunks, engine: engine.cacheIdentity)
        if key == loadedKey, hasAudio {
            startPlayback()
        } else if !isGenerating {
            playback.stop()
            syncWithPlayback()
            if let cached = cache.load(key) {
                show(cached.clip, cached.entry, key: key)
                startPlayback()
            } else {
                generate(chunks, with: engine, key: key)
            }
        }
    }

    private func generate(_ chunks: [String], with engine: some SpeechEngine, key: String) {
        phase = .preparingModel(progress: 0)
        generation = Task {
            do {
                try await engine.prepare { progress in
                    guard case .preparingModel = self.phase else { return }
                    self.phase = .preparingModel(progress: progress)
                }

                var clips: [AudioClip] = []
                for chunk in chunks {
                    try Task.checkCancellation()
                    phase = .generating(done: clips.count, total: chunks.count)
                    clips.append(try await engine.synthesize(chunk))
                }
                try Task.checkCancellation()

                let (clip, starts) = try AudioClip.joining(clips, gap: Self.paragraphGap)
                let entry = AudioCache.Entry(chunks: chunks, chunkStarts: starts)
                try await Task.detached { [cache] in try cache.store(clip, entry, for: key) }.value

                show(clip, entry, key: key)
                startPlayback()
            } catch is CancellationError {
                // `stop()` already reset the phase.
            } catch {
                phase = .failed(ReaderError(error))
            }
        }
    }

    private func show(_ clip: AudioClip, _ entry: AudioCache.Entry, key: String) {
        playback.load(clip)
        loadedKey = key
        audioURL = cache.audioURL(for: key)
        chunks = entry.chunks
        chunkStarts = entry.chunkStarts
        duration = clip.duration
        phase = .ready
    }
}
