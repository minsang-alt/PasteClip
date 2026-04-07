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

                NavigationBarView()

                ZStack {
                    // Cards layer
                    Group {
                        CardGridView()
                            .opacity(appState.selectedTab == .history ? 1 : 0)
                            .allowsHitTesting(appState.selectedTab == .history)

                        if case .pinboard(let id) = appState.selectedTab {
                            PinboardGridView(pinboardId: id)
                                .id(id)
                        }
                    }
                    .opacity(appState.previewItem == nil ? 1 : 0)

                    // Preview layer (replaces cards)
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
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.96, anchor: .bottom)),
                            removal: .opacity.combined(with: .scale(scale: 0.98, anchor: .bottom))
                        ))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .onChange(of: appState.selectedTab) { _, _ in
                appState.searchState.selectedIndex = nil
                appState.selectForPreview(nil)
            }
        }
    }
}
