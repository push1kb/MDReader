import MDReaderCore
import SwiftUI

/// The spoken paragraphs, with the current one highlighted. Click a paragraph to jump to it.
struct SpeakingNowView: View {
    let controller: PlayerController

    var body: some View {
        if controller.chunks.isEmpty {
            ContentUnavailableView("Nothing generated yet", systemImage: "text.bubble",
                                   description: Text("Paste Markdown and press Play."))
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(controller.chunks.enumerated()), id: \.offset) { index, chunk in
                            ParagraphRow(text: chunk, isCurrent: index == controller.currentChunkIndex)
                                .id(index)
                                .onTapGesture { controller.jump(toChunk: index) }
                        }
                    }
                    .padding(4)
                }
                .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 6))
                .onChange(of: controller.currentChunkIndex) { _, index in
                    guard let index else { return }
                    withAnimation { proxy.scrollTo(index, anchor: .center) }
                }
            }
        }
    }
}

private struct ParagraphRow: View {
    let text: String
    let isCurrent: Bool

    var body: some View {
        Text(text)
            .fontWeight(isCurrent ? .semibold : .regular)
            .foregroundStyle(isCurrent ? .primary : .secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(isCurrent ? Color.accentColor.opacity(0.18) : .clear, in: .rect(cornerRadius: 5))
            .contentShape(.rect)
    }
}

#Preview("Playing") {
    SpeakingNowView(controller: .preview(playing: true))
        .padding()
        .frame(width: 420, height: 300)
}

#Preview("Empty") {
    SpeakingNowView(controller: .emptyPreview())
        .frame(width: 420, height: 300)
}
