import Foundation

/// The settings that change the generated audio, as opposed to how it's played back.
struct SpeechSettings {
    var voice: String
    var codeBlockMode: CodeBlockMode

    init(defaults: UserDefaults) {
        let voice = defaults.string(forKey: SettingsKey.voice) ?? ""
        self.voice = voice.isEmpty ? KokoroVoices.defaultVoice : voice
        codeBlockMode = defaults.string(forKey: SettingsKey.codeBlockMode).flatMap(CodeBlockMode.init) ?? .skip
    }
}
