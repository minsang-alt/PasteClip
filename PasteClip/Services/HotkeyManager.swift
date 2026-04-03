import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleHistoryPanel = Self(
        "toggleHistoryPanel",
        default: .init(.v, modifiers: [.shift, .command])
    )
    static let clearHistory = Self(
        "clearHistory",
        default: .init(.delete, modifiers: [.shift, .command])
    )
}
