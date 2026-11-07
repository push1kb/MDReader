import SwiftUI

/// Elapsed time, a position slider and the total duration.
struct Scrubber: View {
    let controller: PlayerController

    /// The position being dragged to; playback seeks there once the drag ends.
    @State private var dragPosition: TimeInterval?

    private var position: TimeInterval { dragPosition ?? controller.currentTime }

    var body: some View {
        HStack(spacing: 8) {
            Text(timestamp(position))
            Slider(value: Binding(get: { position }, set: { dragPosition = $0 }),
                   in: 0...max(controller.duration, 0.1)) { isDragging in
                guard !isDragging, let dragPosition else { return }
                controller.seek(to: dragPosition)
                self.dragPosition = nil
            }
            .disabled(!controller.hasAudio)
            Text(timestamp(controller.duration))
        }
        .font(.caption.monospacedDigit())
        .foregroundStyle(.secondary)
    }

    private func timestamp(_ seconds: TimeInterval) -> String {
        Duration.seconds(seconds.rounded(.down))
            .formatted(.time(pattern: seconds >= 3600 ? .hourMinuteSecond : .minuteSecond))
    }
}

#Preview {
    Scrubber(controller: .preview())
        .padding()
        .frame(width: 420)
}
