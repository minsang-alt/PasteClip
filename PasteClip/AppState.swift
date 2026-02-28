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
        }
        setupHotkey()
    }

    func togglePanel() {
        guard let container = modelContainer else { return }
        panelController.toggle(modelContainer: container, appState: self)
    }

    func selectForPreview(_ item: ClipboardItem?) {
        let wasShowing = previewItem != nil
        let willShow = item != nil
        previewItem = item
        if wasShowing != willShow {
            panelController.resizePanel(showPreview: willShow)
        }
    }

    func hidePanel() {
        previewItem = nil
        searchState.reset()
        selectedTab = .history
        panelController.hidePanel()
    }

    private func setupHotkey() {
        KeyboardShortcuts.onKeyDown(for: .toggleHistoryPanel) { [weak self] in
            Task { @MainActor in
                self?.togglePanel()
            }
        }
    }
}
