import SwiftUI

/// Model download and generation progress, or the latest error.
struct StatusBanner: View {
    let controller: PlayerController
    @Binding var exportError: String?

    var body: some View {
        switch controller.phase {
        case .preparingModel(let progress):
            ProgressRow(value: progress, label: ModelProgress.label(for: progress), cancel: controller.stop)
        case .generating(let done, let total):
            ProgressRow(value: Double(done) / Double(max(total, 1)),
                        label: "Generating \(done)/\(total)", cancel: controller.stop)
        case .failed(let error):
            ErrorRow(message: error.message, dismiss: controller.dismissError)
        case .empty, .ready:
            if let exportError {
                ErrorRow(message: "Export failed: \(exportError)") { self.exportError = nil }
            }
        }
    }
}

/// Wording shared by every place that shows the voice model loading.
enum ModelProgress {
    static func label(for progress: Double) -> String {
        progress > 0 && progress < 1
            ? "Downloading voice model \(Int(progress * 100))% (first run only)"
            : "Loading voice model…"
    }
}

private struct ProgressRow: View {
    let value: Double
    let label: String
    let cancel: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            ProgressView(value: value)
            Text(label)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .fixedSize()
            Button("Cancel", action: cancel)
                .controlSize(.small)
        }
    }
}

private struct ErrorRow: View {
    let message: String
    let dismiss: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.callout)
                .textSelection(.enabled)
            Spacer()
            Button("Dismiss", systemImage: "xmark", action: dismiss)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
        }
        .padding(8)
        .background(.orange.opacity(0.1), in: .rect(cornerRadius: 6))
    }
}

#Preview("Downloading") {
    ProgressRow(value: 0.42, label: ModelProgress.label(for: 0.42)) {}
        .padding()
        .frame(width: 420)
}

#Preview("Error") {
    ErrorRow(message: "Couldn't download the voice model. Check your connection and press Play again.") {}
        .padding()
        .frame(width: 420)
}
