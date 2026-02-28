import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleHistoryPanel = Self(
        "toggleHistoryPanel",
        default: .init(.v, modifiers: [.shift, .command])
    )
}
