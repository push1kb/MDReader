import SwiftUI

struct SpeedSlider: View {
    let controller: PlayerController

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "gauge.with.dots.needle.33percent")
                .foregroundStyle(.secondary)
                .help("Speed (⌘↑ / ⌘↓)")
            // Snaps to 0.05× without `step:`, which would draw a tick mark for every step.
            Slider(value: Binding(get: { controller.rate }, set: { controller.rate = ($0 * 20).rounded() / 20 }),
                   in: PlayerController.speedRange)
            Text("\(controller.rate, format: .number.precision(.fractionLength(2)))×")
                .font(.caption.monospacedDigit())
                .frame(width: 42, alignment: .trailing)
        }
    }
}

struct VolumeSlider: View {
    @Bindable var controller: PlayerController

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "speaker.fill")
                .foregroundStyle(.secondary)
            Slider(value: $controller.volume, in: 0...1)
                .frame(maxWidth: 110)
        }
    }
}

#Preview {
    HStack(spacing: 14) {
        SpeedSlider(controller: .preview())
        VolumeSlider(controller: .preview())
    }
    .padding()
    .frame(width: 420)
}
