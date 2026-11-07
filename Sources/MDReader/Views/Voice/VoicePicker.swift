import MDReaderCore
import SwiftUI

/// Every Kokoro voice, grouped by language.
struct VoicePicker: View {
    @Binding var selection: String

    var body: some View {
        Picker("Voice", selection: $selection) {
            ForEach(KokoroVoices.languages) { language in
                Section(language.name) {
                    ForEach(language.voices) { Text($0.label).tag($0.id) }
                }
            }
            if !KokoroVoices.contains(selection) {
                Text(selection).tag(selection)  // a saved id that's no longer in the list
            }
        }
    }
}

#Preview {
    @Previewable @State var voice = KokoroVoices.defaultVoice
    VoicePicker(selection: $voice)
        .padding()
        .frame(width: 360)
}
