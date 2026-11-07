import Carbon.HIToolbox

/// A system-wide hot key (⌃⌥P). Carbon hot keys need no Accessibility permission.
final class GlobalHotKey {
    static let displayName = "⌃⌥P"

    /// Carbon's C callback can't capture context, so the one action lives here.
    private static var action: () -> Void = {}

    private var hotKey: EventHotKeyRef?
    private var handler: EventHandlerRef?

    init(action: @escaping () -> Void) {
        Self.action = action

        var pressed = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
            DispatchQueue.main.async { GlobalHotKey.action() }
            return noErr
        }, 1, &pressed, nil, &handler)

        let id = EventHotKeyID(signature: OSType(0x4D44_5244), id: 1)  // 'MDRD'
        RegisterEventHotKey(UInt32(kVK_ANSI_P), UInt32(controlKey | optionKey), id,
                            GetApplicationEventTarget(), 0, &hotKey)
    }

    deinit {
        if let hotKey { UnregisterEventHotKey(hotKey) }
        if let handler { RemoveEventHandler(handler) }
    }
}
