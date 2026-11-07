import CryptoKit
import Foundation

/// Generated audio on disk, so unchanged text isn't synthesized twice.
///
/// Each entry is a CAF file plus a JSON sidecar with the paragraph texts and start times.
/// Entries are keyed by a hash of the engine identity and the spoken paragraphs.
public struct AudioCache: Sendable {
    struct Entry: Codable {
        var chunks: [String]
        var chunkStarts: [TimeInterval]
    }

    public let directory: URL

    /// - Parameter directory: Defaults to the app's Caches folder.
    public init(directory: URL? = nil) {
        let directory = directory ?? AppFolder.audio
        self.directory = directory
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    static func key(for chunks: [String], engine: String) -> String {
        var hash = SHA256()
        hash.update(data: Data(engine.utf8))
        for chunk in chunks {
            hash.update(data: Data([0x1E]))  // record separator, so chunk boundaries count
            hash.update(data: Data(chunk.utf8))
        }
        return hash.finalize().map { String(format: "%02x", $0) }.joined()
    }

    func audioURL(for key: String) -> URL { directory.appending(path: "\(key).caf") }

    func previewURL(for voiceID: String) -> URL { directory.appending(path: "preview-\(voiceID).caf") }

    private func entryURL(for key: String) -> URL { directory.appending(path: "\(key).json") }

    func load(_ key: String) -> (clip: AudioClip, entry: Entry)? {
        guard let data = try? Data(contentsOf: entryURL(for: key)),
              let entry = try? JSONDecoder().decode(Entry.self, from: data),
              let clip = try? AudioClip(contentsOf: audioURL(for: key))
        else { return nil }
        return (clip, entry)
    }

    func store(_ clip: AudioClip, _ entry: Entry, for key: String) throws {
        try clip.write(to: audioURL(for: key))
        try JSONEncoder().encode(entry).write(to: entryURL(for: key), options: .atomic)
    }
}
