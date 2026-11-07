import MDReaderCore
import SwiftUI

/// Plays, or stops, a short sample of the selected voice.
struct VoiceTestButton: View {
    let previewer: VoicePreviewer
    let voiceID: String

    var body: some View {
        let isBusy = previewer.isBusy(with: voiceID)
        Button(isBusy ? "Stop" : "Test", systemImage: isBusy ? "stop.fill" : "play.fill") {
            isBusy ? previewer.stop() : previewer.play(voiceID)
        }
        .help(isBusy ? "Stop the voice sample" : "Hear a short sample of this voice")
    }
}

/// Progress while the sample is prepared, or why it failed.
struct VoiceTestStatus: View {
    let previewer: VoicePreviewer
    let voiceID: String

    var body: some View {
        if previewer.voiceID == voiceID {
            switch previewer.state {
            case .preparingModel(let progress):
                HStack {
                    ProgressView(value: progress).frame(maxWidth: 120)
                    Text(ModelProgress.label(for: progress))
                }
                .statusStyle()
            case .generating:
                HStack {
                    ProgressView().controlSize(.small)
                    Text("Generating sample…")
                }
                .statusStyle()
            case .failed(let message):
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            case .idle, .playing:
                EmptyView()
            }
        }
    }
}

private extension View {
    func statusStyle() -> some View {
        font(.caption).foregroundStyle(.secondary)
    }
}

#Preview {
    Form {
        HStack {
            Text("Heart (female)")
            Spacer()
            VoiceTestButton(previewer: PlayerController.preview().voicePreview, voiceID: KokoroVoices.defaultVoice)
        }
    }
    .formStyle(.grouped)
    .frame(width: 360, height: 120)
}
