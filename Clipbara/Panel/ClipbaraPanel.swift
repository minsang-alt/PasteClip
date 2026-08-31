import AppKit

@MainActor
final class ClipbaraPanel: NSPanel {

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
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

    /// AppKit nudges ordinary windows back inside a screen's usable area. The
    /// panel is deliberately parked off the bottom edge while it animates, and
    /// the default behaviour both shifts that position and re-homes the panel
    /// to a neighbouring display. Place the panel exactly where asked.
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        frameRect
    }
}
