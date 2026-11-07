import MDReaderCore
import SwiftUI

/// Scrubber, transport, speed and volume.
struct PlayerControls: View {
    let controller: PlayerController

    var body: some View {
        VStack(spacing: 8) {
            Scrubber(controller: controller)
            TransportBar(controller: controller)
            HStack(spacing: 14) {
                SpeedSlider(controller: controller)
                VolumeSlider(controller: controller)
            }
        }
    }
}

#Preview("Paused") {
    PlayerControls(controller: .preview())
        .padding()
        .frame(width: 420)
}

#Preview("Playing") {
    PlayerControls(controller: .preview(playing: true))
        .padding()
        .frame(width: 420)
}
