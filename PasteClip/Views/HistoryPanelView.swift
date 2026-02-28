import SwiftUI
import SwiftData

struct HistoryPanelView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \ClipboardItem.copiedAt, order: .reverse)
    private var items: [ClipboardItem]

    var body: some View {
        ZStack {
            VisualEffectBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Capsule()
                    .fill(.quaternary.opacity(0.6))
                    .frame(width: 40, height: 4)
                    .padding(.top, 8)
                    .padding(.bottom, 2)

                if let previewItem = appState.previewItem {
                    PreviewView(
                        item: previewItem,
                        onClose: {
                            withAnimation(.easeOut(duration: 0.2)) {
                                appState.searchState.selectedIndex = nil
                                appState.selectForPreview(nil)
                            }
                        },
                        onPaste: {
                            appState.clipboardMonitor.skipNextChange()
                            appState.pasteService.paste(item: previewItem)
                            appState.hidePanel()
                        }
                    )
                }

                NavigationBarView()

                if appState.selectedTab == .history {
                    CardGridView()
                } else if case .pinboard(let id) = appState.selectedTab {
                    PinboardGridView(pinboardId: id)
                        .id(id)
                }
            }
            .onChange(of: appState.selectedTab) { _, _ in
                appState.searchState.selectedIndex = nil
                appState.selectForPreview(nil)
            }
        }
    }
}
