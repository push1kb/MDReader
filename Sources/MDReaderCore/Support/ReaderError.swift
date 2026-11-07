import Foundation

/// An error with a message that can be shown to the user as is.
public struct ReaderError: LocalizedError, Equatable, Sendable {
    public let message: String

    public init(_ message: String) {
        self.message = message
    }

    init(_ error: any Error) {
        self = error as? ReaderError ?? ReaderError(error.localizedDescription)
    }

    public var errorDescription: String? { message }
}
