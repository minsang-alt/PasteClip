import AppKit

@MainActor
final class PasteClipPanel: NSPanel {

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .resizable],
            backing: .buffered,
            defer: true
        )

        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        isOpaque = false
        backgroundColor = .clear
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = false
        hasShadow = true

        minSize = NSSize(width: 100, height: 200)
        maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: 800)
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
