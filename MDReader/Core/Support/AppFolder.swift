import Foundation

/// Where MDReader keeps its files. In the sandboxed app these resolve inside its container.
enum AppFolder {
    private static let name = Bundle.main.bundleIdentifier ?? "com.push1kb.MDReader"

    /// The voice model and pronunciation data: downloaded once and needed to speak, so they live
    /// in Application Support rather than Caches, where the system may purge them.
    static let models = URL.applicationSupportDirectory.appending(path: "\(name)/Models")

    /// Generated speech. It can always be regenerated, so the system may purge it.
    static let audio = URL.cachesDirectory.appending(path: "\(name)/Audio")
}
