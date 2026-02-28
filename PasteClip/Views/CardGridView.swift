import SwiftUI
import SwiftData

struct CardGridView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \ClipboardItem.copiedAt, order: .reverse)
    private var items: [ClipboardItem]
    @Query(sort: \Pinboard.displayOrder)
    private var pinboards: [Pinboard]

    var body: some View {
        let filteredItems = appState.searchState.filteredItems(from: items)

        Group {
            if filteredItems.isEmpty {
                ContentUnavailableView(
                    appState.searchState.isActive ? "No Results" : "No Clipboard History",
                    systemImage: appState.searchState.isActive ? "magnifyingglass" : "clipboard",
                    description: Text(
                        appState.searchState.isActive
                            ? "Try a different search or filter"
                            : "Copy something to get started"
                    )
                )
            } else {
                GeometryReader { geo in
                    let cardH = max(geo.size.height - 20, 100)
                    let cardW = cardH * 0.8
                    let rows = [GridItem(.fixed(cardH), spacing: 14)]

                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHGrid(rows: rows, spacing: 10) {
                                ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                                    ClipboardCardView(
                                        item: item,
                                        isSelected: appState.searchState.selectedIndex == index,
                                        searchText: appState.searchState.debouncedSearchText,
                                        cardWidth: cardW,
                                        cardHeight: cardH,
                                        pinboards: pinboards,
                                        onSelect: { _ in
                                            appState.searchState.selectedIndex = index
                                        },
                                        onPaste: { selected in
                                            appState.clipboardMonitor.skipNextChange()
                                            appState.pasteService.paste(item: selected)
                                            appState.hidePanel()
                                        }
                                    )
                                    .id(item.id)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }
                        .onChange(of: appState.searchState.selectedIndex) { _, newIndex in
                            if let idx = newIndex, idx < filteredItems.count {
                                withAnimation(.easeOut(duration: 0.15)) {
                                    proxy.scrollTo(filteredItems[idx].id, anchor: .center)
                                }
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: items) { _, newItems in
            appState.currentFilteredItems = appState.searchState.filteredItems(from: newItems)
        }
        .onAppear {
            appState.currentFilteredItems = appState.searchState.filteredItems(from: items)
        }
    }
}
