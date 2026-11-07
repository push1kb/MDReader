import Foundation

/// The 54 voices that ship with Kokoro-82M, grouped by language.
///
/// A voice id is a language letter, a gender letter and a name: `af_heart` is an American
/// English female voice called Heart.
public enum KokoroVoices {
    public static let defaultVoice = "af_heart"

    public struct Voice: Identifiable, Hashable, Sendable {
        public let id: String

        public var name: String {
            let name = id.split(separator: "_").last.map(String.init) ?? id
            return name.prefix(1).uppercased() + name.dropFirst()
        }

        public var label: String {
            "\(name) (\(id.dropFirst().first == "f" ? "female" : "male"))"
        }
    }

    public struct Language: Identifiable, Sendable {
        public let id: Character
        public let name: String
        /// Spoken by the Test button; `%@` is the voice's name.
        let sample: String
        public let voices: [Voice]

        init(_ id: Character, _ name: String, sample: String, voices: String) {
            self.id = id
            self.name = name
            self.sample = sample
            self.voices = voices.split(separator: " ").map { Voice(id: String($0)) }
        }
    }

    public static let languages: [Language] = [
        Language("a", "American English", sample: "Hi, I'm %@. This is how I'll read your Markdown.", voices: """
            af_alloy af_aoede af_bella af_heart af_jessica af_kore af_nicole af_nova af_river af_sarah af_sky \
            am_adam am_echo am_eric am_fenrir am_liam am_michael am_onyx am_puck am_santa
            """),
        Language("b", "British English", sample: "Hi, I'm %@. This is how I'll read your Markdown.",
                 voices: "bf_alice bf_emma bf_isabella bf_lily bm_daniel bm_fable bm_george bm_lewis"),
        Language("e", "Spanish", sample: "Hola, soy %@. Así es como leeré tu texto.",
                 voices: "ef_dora em_alex em_santa"),
        Language("f", "French", sample: "Bonjour, je suis %@. Voici comment je vais lire votre texte.",
                 voices: "ff_siwis"),
        Language("h", "Hindi", sample: "नमस्ते, मैं %@ हूँ। मैं आपका पाठ ऐसे पढ़ूँगी।",
                 voices: "hf_alpha hf_beta hm_omega hm_psi"),
        Language("i", "Italian", sample: "Ciao, sono %@. Ecco come leggerò il tuo testo.",
                 voices: "if_sara im_nicola"),
        Language("j", "Japanese", sample: "こんにちは、%@です。このようにテキストを読み上げます。",
                 voices: "jf_alpha jf_gongitsune jf_nezumi jf_tebukuro jm_kumo"),
        Language("p", "Brazilian Portuguese", sample: "Olá, eu sou %@. É assim que vou ler o seu texto.",
                 voices: "pf_dora pm_alex pm_santa"),
        Language("z", "Mandarin Chinese", sample: "你好，我是%@。我会这样朗读你的文字。",
                 voices: "zf_xiaobei zf_xiaoni zf_xiaoxiao zf_xiaoyi zm_yunjian zm_yunxi zm_yunxia zm_yunyang"),
    ]

    public static func contains(_ voiceID: String) -> Bool {
        languages.contains { $0.voices.contains { $0.id == voiceID } }
    }

    /// A short sentence introducing the voice, in the voice's own language.
    static func sampleText(for voiceID: String) -> String {
        let language = languages.first { $0.id == voiceID.first } ?? languages[0]
        return String(format: language.sample, Voice(id: voiceID).name)
    }
}
