import AppKit
import SwiftUI
import SwiftData

@MainActor
@Observable
final class PanelController {
    private var panel: PasteClipPanel?
    private(set) var isVisible: Bool = false
    private var clickMonitor: Any?
    private var keyMonitor: Any?
    var onPanelWillHide: (() -> Void)?
    weak var appState: AppState?

    private let baseHeight: CGFloat = 320
    private let previewHeight: CGFloat = 420

    func toggle(modelContainer: ModelContainer, appState: AppState) {
        if isVisible {
            hidePanel()
        } else {
            showPanel(modelContainer: modelContainer, appState: appState)
        }
    }

    func showPanel(modelContainer: ModelContainer, appState: AppState) {
        guard !isVisible else { return }
        self.appState = appState

        let screen = NSScreen.main ?? NSScreen.screens.first!
        let screenFrame = screen.visibleFrame
        let panelHeight: CGFloat = 320
        let panelWidth = screenFrame.width

        let startFrame = NSRect(
            x: screenFrame.origin.x,
            y: screenFrame.origin.y - panelHeight,
            width: panelWidth,
            height: panelHeight
        )

        let endFrame = NSRect(
            x: screenFrame.origin.x,
            y: screenFrame.origin.y,
            width: panelWidth,
            height: panelHeight
        )

        if panel == nil {
            panel = PasteClipPanel(contentRect: startFrame)

            let hostingView = NSHostingView(
                rootView: HistoryPanelView()
                    .environment(appState)
                    .modelContainer(modelContainer)
            )
            panel?.contentView = hostingView
        } else {
            panel?.setFrame(startFrame, display: false)
        }

        panel?.orderFrontRegardless()
        panel?.makeKey()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel?.animator().setFrame(endFrame, display: true)
        }

        isVisible = true
        installClickMonitor()
        installKeyMonitor()
    }

    func hidePanel() {
        guard isVisible, let panel else { return }
        onPanelWillHide?()

        let screenFrame = (NSScreen.main ?? NSScreen.screens.first!).visibleFrame
        let panelHeight = panel.frame.height

        let offscreenFrame = NSRect(
            x: panel.frame.origin.x,
            y: screenFrame.origin.y - panelHeight,
            width: panel.frame.width,
            height: panelHeight
        )

        removeClickMonitor()
        removeKeyMonitor()

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().setFrame(offscreenFrame, display: true)
        }, completionHandler: { [weak self] in
            panel.orderOut(nil)
            Task { @MainActor in
                self?.isVisible = false
            }
        })
    }

    func resizePanel(showPreview: Bool) {
        guard isVisible, let panel else { return }
        let screenFrame = (NSScreen.main ?? NSScreen.screens.first!).visibleFrame
        let targetHeight = showPreview ? baseHeight + previewHeight : baseHeight

        let newFrame = NSRect(
            x: panel.frame.origin.x,
            y: screenFrame.origin.y,
            width: panel.frame.width,
            height: targetHeight
        )

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(newFrame, display: true)
        }
    }

    // MARK: - Click Monitor (dismiss on outside click)

    private func installClickMonitor() {
        clickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            Task { @MainActor in
                guard let self, self.isVisible else { return }
                if let panel = self.panel,
                   !panel.frame.contains(NSEvent.mouseLocation) {
                    self.hidePanel()
                }
            }
        }
    }

    private func removeClickMonitor() {
        if let monitor = clickMonitor {
            NSEvent.removeMonitor(monitor)
            clickMonitor = nil
        }
    }

    // MARK: - Key Monitor (arrow keys, space, esc, return)

    private func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let keyCode = event.keyCode
            let handled: Bool = MainActor.assumeIsolated { [weak self] in
                guard let self, self.isVisible else { return false }

                // Check if a text field is focused (search bar) - let it handle the event
                if let firstResponder = self.panel?.firstResponder,
                   firstResponder is NSTextView || firstResponder is NSTextField {
                    // Still handle Escape to close search/panel
                    if keyCode == 53 {
                        return self.processKey(keyCode)
                    }
                    return false
                }

                return self.processKey(keyCode)
            }
            return handled ? nil : event
        }
    }

    private func processKey(_ keyCode: UInt16) -> Bool {
        guard let appState, isVisible else { return false }
        let items = appState.currentFilteredItems
        let maxIndex = items.count - 1

        switch keyCode {
        case 53: // Escape
            if appState.previewItem != nil {
                appState.searchState.selectedIndex = nil
                appState.selectForPreview(nil)
                return true
            }
            if appState.searchState.isActive {
                appState.searchState.reset()
                return true
            }
            if appState.selectedTab != .history {
                appState.selectedTab = .history
                return true
            }
            appState.hidePanel()
            return true

        case 123: // Left arrow
            appState.searchState.moveSelection(by: -1, maxIndex: maxIndex)
            return true

        case 124: // Right arrow
            appState.searchState.moveSelection(by: 1, maxIndex: maxIndex)
            return true

        case 49: // Space - toggle preview
            if appState.previewItem != nil {
                withAnimation(.easeOut(duration: 0.2)) {
                    appState.selectForPreview(nil)
                }
                return true
            }
            if let idx = appState.searchState.selectedIndex, idx < items.count {
                withAnimation(.spring(duration: 0.3, bounce: 0.1)) {
                    appState.selectForPreview(items[idx])
                }
                return true
            }
            return false

        case 36: // Return - paste
            guard let idx = appState.searchState.selectedIndex,
                  idx < items.count else { return false }
            let item = items[idx]
            appState.clipboardMonitor.skipNextChange()
            appState.pasteService.paste(item: item)
            appState.hidePanel()
            return true

        default:
            return false
        }
    }

    private func removeKeyMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }
}
