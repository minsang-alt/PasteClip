import SwiftUI
import SwiftData
import KeyboardShortcuts

enum PanelTab: Equatable, Hashable {
    case history
    case pinboard(UUID)
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

    func selectForPreview(_ item: ClipboardItem?) {
        previewItem = item
    }

    func hidePanel() {
        previewItem = nil
        searchState.reset()
        selectedTab = .history
        panelController.hidePanel()
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
