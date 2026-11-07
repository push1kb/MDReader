import SwiftUI

extension View {
    /// Liquid Glass in `shape` on macOS 26, a translucent material on macOS 14 and 15.
    func glassIfAvailable(in shape: some Shape = .rect(cornerRadius: 10)) -> some View {
        modifier(GlassIfAvailable(shape: shape))
    }

    /// Makes the window's whole background Liquid Glass on macOS 26. Older systems keep
    /// their normal window background.
    func windowGlassIfAvailable(_ isEnabled: Bool = true) -> some View {
        modifier(WindowGlassIfAvailable(isEnabled: isEnabled))
    }
}

private struct GlassIfAvailable<S: Shape>: ViewModifier {
    let shape: S

    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content.glassEffect(.regular, in: shape)
        } else {
            content.background(.regularMaterial, in: shape)
        }
    }
}

private struct WindowGlassIfAvailable: ViewModifier {
    let isEnabled: Bool

    func body(content: Content) -> some View {
        if #available(macOS 26.0, *), isEnabled {
            content.background(WindowGlassInstaller())
        } else {
            content
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        Text("Rounded rectangle")
            .frame(maxWidth: .infinity, minHeight: 80)
            .glassIfAvailable()
        Label("Capsule", systemImage: "play.fill")
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .glassIfAvailable(in: .capsule)
    }
    .padding()
    .frame(width: 420)
    .background(.linearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom))
}
