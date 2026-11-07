import MDReaderCore
import SwiftUI

/// Where the Markdown is pasted or typed.
struct EditorPane: View {
    @Bindable var controller: PlayerController

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            toolbar
            TextEditor(text: $controller.text)
                .font(.body.monospaced())
                .scrollContentBackground(.hidden)
                .padding(4)
                .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.quaternary))
                .overlay(alignment: .topLeading) { placeholder }
        }
    }

    private var toolbar: some View {
        HStack {
            Button("Paste from Clipboard", systemImage: "doc.on.clipboard") {
                if let text = NSPasteboard.general.string(forType: .string) {
                    controller.text = text
                }
            }
            Button("Clear", systemImage: "trash", role: .destructive, action: controller.clear)
                .disabled(controller.text.isEmpty)
            Spacer()
            Text("\(controller.text.count) chars")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .controlSize(.small)
    }

    @ViewBuilder
    private var placeholder: some View {
        if controller.text.isEmpty {
            Text("Paste Markdown here…")
                .foregroundStyle(.tertiary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .allowsHitTesting(false)
        }
    }
}

#Preview {
    EditorPane(controller: .preview())
        .padding()
        .frame(width: 420, height: 300)
}
