import SwiftUI

/// The whole UI, shown in the menu bar panel and in the resizable reader window.
struct ReaderView: View {
    static let windowID = "reader"

    enum Presentation { case panel, window }

    enum Tab: String, CaseIterable, Identifiable {
        case markdown = "Markdown"
        case speakingNow = "Speaking Now"
        case voice = "Voice"

        var id: Self { self }
    }

    @Bindable var controller: PlayerController
    let presentation: Presentation

    @State private var tab: Tab
    @State private var exportError: String?

    init(controller: PlayerController, presentation: Presentation, tab: Tab = .markdown) {
        self.controller = controller
        self.presentation = presentation
        _tab = State(initialValue: tab)
    }

    var body: some View {
        VStack(spacing: 10) {
            Picker("Section", selection: $tab) {
                ForEach(Tab.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            StatusBanner(controller: controller, exportError: $exportError)
            PlayerControls(controller: controller)
            Divider()
            ReaderFooter(controller: controller, showsOpenInWindow: presentation == .panel) {
                exportError = $0
            }
        }
        .padding(12)
        .frame(width: isPanel ? 420 : nil, height: isPanel ? 520 : nil)
        .frame(minWidth: 420, minHeight: 520)
        .windowGlassIfAvailable(isPanel)
        .onChange(of: controller.isPlaying) { _, isPlaying in
            if isPlaying, tab == .markdown { tab = .speakingNow }
        }
    }

    private var isPanel: Bool { presentation == .panel }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .markdown: EditorPane(controller: controller)
        case .speakingNow: SpeakingNowView(controller: controller)
        case .voice: VoiceSettingsView(controller: controller)
        }
    }
}

#Preview("Panel") {
    ReaderView(controller: .preview(), presentation: .panel)
}

#Preview("Window, playing") {
    ReaderView(controller: .preview(playing: true), presentation: .window)
        .frame(width: 720, height: 820)
}
