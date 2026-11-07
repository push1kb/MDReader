import SwiftUI

/// The voice (with a Test button) and how code blocks are read.
struct VoiceSettingsView: View {
    let controller: PlayerController

    @AppStorage(SettingsKey.voice) private var voice = KokoroVoices.defaultVoice
    @AppStorage(SettingsKey.codeBlockMode) private var codeBlockMode = CodeBlockMode.skip

    var body: some View {
        Form {
            Section {
                HStack {
                    VoicePicker(selection: $voice)
                    VoiceTestButton(previewer: controller.voicePreview, voiceID: voice)
                }
                VoiceTestStatus(previewer: controller.voicePreview, voiceID: voice)
            }

            Picker("Code blocks", selection: $codeBlockMode) {
                ForEach(CodeBlockMode.allCases) { Text($0.label).tag($0) }
            }
        }
        .formStyle(.grouped)
        .onChange(of: voice) { controller.voicePreview.stop() }
    }
}

#Preview {
    VoiceSettingsView(controller: .preview())
        .frame(width: 420, height: 300)
}
