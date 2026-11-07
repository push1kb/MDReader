import SwiftUI

/// Previous/next paragraph, ±10 s, play/pause and stop.
struct TransportBar: View {
    let controller: PlayerController

    var body: some View {
        HStack(spacing: 18) {
            TransportButton("Previous paragraph (⇧←)", symbol: "backward.end.fill", action: controller.previousParagraph)
                .disabled(!controller.hasAudio)
            TransportButton("Back 10 seconds (←)", symbol: "gobackward.10") {
                controller.skip(by: -PlayerController.skipInterval)
            }
            .disabled(!controller.hasAudio)

            TransportButton(controller.isPlaying ? "Pause (Space)" : "Play (Space)",
                            symbol: controller.isPlaying ? "pause.circle.fill" : "play.circle.fill",
                            size: 34, action: controller.togglePlayPause)
                .disabled(controller.isGenerating)

            TransportButton("Forward 10 seconds (→)", symbol: "goforward.10") {
                controller.skip(by: PlayerController.skipInterval)
            }
            .disabled(!controller.hasAudio)
            TransportButton("Next paragraph (⇧→)", symbol: "forward.end.fill", action: controller.nextParagraph)
                .disabled(!controller.hasAudio)
            TransportButton("Stop", symbol: "stop.fill", action: controller.stop)
                .disabled(!controller.hasAudio && !controller.isGenerating)
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .glassIfAvailable(in: .capsule)
    }
}

private struct TransportButton: View {
    let title: String
    let symbol: String
    let size: CGFloat
    let action: () -> Void

    init(_ title: String, symbol: String, size: CGFloat = 18, action: @escaping () -> Void) {
        self.title = title
        self.symbol = symbol
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(title, systemImage: symbol, action: action)
            .labelStyle(.iconOnly)
            .font(.system(size: size))
            .help(title)
    }
}

#Preview {
    TransportBar(controller: .preview(playing: true))
        .padding()
}
