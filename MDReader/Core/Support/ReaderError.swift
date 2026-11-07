import Foundation

/// An error with a message that can be shown to the user as is.
struct ReaderError: LocalizedError, Equatable, Sendable {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    init(_ error: any Error) {
        self = error as? ReaderError ?? ReaderError(error.localizedDescription)
    }

    var errorDescription: String? { message }
}
