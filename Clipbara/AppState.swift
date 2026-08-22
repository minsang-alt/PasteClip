import SwiftUI
import SwiftData
import KeyboardShortcuts

enum PanelTab: Equatable, Hashable {
    case history
    case pinboard(UUID)
}

struct PanelToast: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let systemImage: String
}

@MainActor
@Observable
final class AppState {
    let clipboardMonitor = ClipboardMonitor()
    let pasteService = PasteService()
    let panelController = PanelController()
    let searchState = SearchState()

    var selectedTab: PanelTab = .history
    var previewItem: ClipboardItem?
    var panelToast: PanelToast?
    var panelPresentationID = 0
    var draggedClipboardItemID: UUID?
    @ObservationIgnored private var toastTask: Task<Void, Never>?
    private(set) var modelContainer: ModelContainer?

    /// Cached filtered items for keyboard navigation (updated by CardGridView)
    var currentFilteredItems: [ClipboardItem] = []

    func start(modelContext: ModelContext, modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        clipboardMonitor.start(modelContext: modelContext)
        panelController.onPanelWillHide = { [weak self] in
            self?.searchState.reset()
            self?.previewItem = nil
        }
        setupHotkey()
    }

    func togglePanel() {
        guard let container = modelContainer else { return }
        panelController.toggle(modelContainer: container, appState: self)
    }

    func markPanelPresented() {
        panelPresentationID += 1
    }

    func selectForPreview(_ item: ClipboardItem?) {
        previewItem = item
    }

    func showToast(_ message: String, systemImage: String = "checkmark.circle.fill") {
        toastTask?.cancel()
        panelToast = PanelToast(message: message, systemImage: systemImage)
        toastTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1400))
            guard !Task.isCancelled else { return }
            panelToast = nil
        }
    }

    /// 패널/핀보드 카드에서 공통으로 쓰는 붙여넣기 경로.
    /// - Parameter asPlainText: nil이면 설정 + Shift 조합으로 자동 판단
    func paste(_ item: ClipboardItem, asPlainText: Bool? = nil) {
        clipboardMonitor.skipNextChange()
        pasteService.paste(item: item, asPlainText: asPlainText)
        hidePanel()
    }

    func hidePanel() {
        previewItem = nil
        panelToast = nil
        toastTask?.cancel()
        draggedClipboardItemID = nil
        searchState.reset()
        selectedTab = .history
        panelController.hidePanel()
    }

    func finishClipboardDrag() {
        draggedClipboardItemID = nil
        searchState.ensureSelection(itemCount: currentFilteredItems.count)
        panelController.restoreKeyboardNavigationFocus(activateApp: true)

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(80))
            panelController.restoreKeyboardNavigationFocus(activateApp: true)
        }
    }

    var clearHistoryRequested = false

    private func setupHotkey() {
        KeyboardShortcuts.onKeyDown(for: .toggleHistoryPanel) { [weak self] in
            Task { @MainActor in
                self?.togglePanel()
            }
        }
        KeyboardShortcuts.onKeyDown(for: .clearHistory) { [weak self] in
            Task { @MainActor in
                guard self?.panelController.isVisible == true else { return }
                self?.clearHistoryRequested = true
            }
        }
    }
}
