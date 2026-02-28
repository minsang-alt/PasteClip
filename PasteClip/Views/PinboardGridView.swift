import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct PinboardGridView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    let pinboardId: UUID

    @Query(sort: \Pinboard.displayOrder) private var allPinboards: [Pinboard]

    @State private var orderedEntries: [PinboardEntry] = []
    @State private var draggingEntry: PinboardEntry?

    private var pinboard: Pinboard? {
        allPinboards.first { $0.id == pinboardId }
    }

    var body: some View {
        Group {
            if orderedEntries.isEmpty {
                ContentUnavailableView(
                    "Empty Pinboard",
                    systemImage: "pin.slash",
                    description: Text("Right-click a card and select \"Add to Pinboard\"")
                )
            } else {
                GeometryReader { geo in
                    let cardH = max(geo.size.height - 24, 100)
                    let cardW = cardH * 0.8
                    let rows = [GridItem(.fixed(cardH), spacing: 14)]
                    let pinboardItems = orderedEntries.compactMap(\.clipboardItem)

                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: true) {
                            LazyHGrid(rows: rows, spacing: 12) {
                                ForEach(Array(orderedEntries.enumerated()), id: \.element.id) { index, entry in
                                    if let item = entry.clipboardItem {
                                        cardView(
                                            entry: entry,
                                            item: item,
                                            index: index,
                                            cardWidth: cardW,
                                            cardHeight: cardH
                                        )
                                        .id(entry.id)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .onChange(of: appState.searchState.selectedIndex) { _, newIndex in
                            if let idx = newIndex, idx < orderedEntries.count {
                                withAnimation(.easeOut(duration: 0.15)) {
                                    proxy.scrollTo(orderedEntries[idx].id, anchor: .center)
                                }
                            }
                        }
                    }
                    .onAppear {
                        appState.currentFilteredItems = pinboardItems
                    }
                    .onChange(of: orderedEntries.count) { _, _ in
                        appState.currentFilteredItems = orderedEntries.compactMap(\.clipboardItem)
                    }
                }
            }
        }
        .onAppear { syncEntries() }
        .onChange(of: pinboard?.entries.count) { _, _ in syncEntries() }
    }

    @ViewBuilder
    private func cardView(entry: PinboardEntry, item: ClipboardItem, index: Int, cardWidth: CGFloat, cardHeight: CGFloat) -> some View {
        let isDragging = draggingEntry?.id == entry.id

        ClipboardCardView(
            item: item,
            isSelected: appState.searchState.selectedIndex == index,
            searchText: "",
            cardWidth: cardWidth,
            cardHeight: cardHeight,
            pinboards: allPinboards,
            enableDrag: false,
            onSelect: { _ in
                appState.searchState.selectedIndex = index
            },
            onPaste: { selected in
                appState.clipboardMonitor.skipNextChange()
                appState.pasteService.paste(item: selected)
                appState.hidePanel()
            }
        )
        .opacity(isDragging ? 0.3 : 1.0)
        .scaleEffect(isDragging ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isDragging)
        .onDrag {
            draggingEntry = entry
            return item.dragProvider()
        }
        .onDrop(of: [.text], delegate: ReorderDropDelegate(
            target: entry,
            orderedEntries: $orderedEntries,
            draggingEntry: $draggingEntry,
            commitOrder: commitOrder
        ))
        .contextMenu {
            Button("Paste") {
                appState.clipboardMonitor.skipNextChange()
                appState.pasteService.paste(item: item)
                appState.hidePanel()
            }
            Divider()
            Button("Remove from Pinboard", role: .destructive) {
                removeEntry(entry)
            }
        }
    }

    private func syncEntries() {
        let current = (pinboard?.entries ?? []).sorted { $0.displayOrder < $1.displayOrder }
        if orderedEntries.map(\.id) != current.map(\.id) {
            orderedEntries = current
        }
    }

    private func commitOrder() {
        for (index, entry) in orderedEntries.enumerated() {
            entry.displayOrder = index
        }
    }

    private func removeEntry(_ entry: PinboardEntry) {
        orderedEntries.removeAll { $0.id == entry.id }
        modelContext.delete(entry)
        commitOrder()
    }
}

// MARK: - DropDelegate

private struct ReorderDropDelegate: DropDelegate {
    let target: PinboardEntry
    @Binding var orderedEntries: [PinboardEntry]
    @Binding var draggingEntry: PinboardEntry?
    let commitOrder: () -> Void

    func dropEntered(info: DropInfo) {
        guard let source = draggingEntry, source.id != target.id else { return }
        guard let sourceIndex = orderedEntries.firstIndex(where: { $0.id == source.id }),
              let destIndex = orderedEntries.firstIndex(where: { $0.id == target.id }) else { return }

        withAnimation(.easeInOut(duration: 0.2)) {
            orderedEntries.move(
                fromOffsets: IndexSet(integer: sourceIndex),
                toOffset: destIndex > sourceIndex ? destIndex + 1 : destIndex
            )
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        commitOrder()
        draggingEntry = nil
        return true
    }

    func dropExited(info: DropInfo) {
        // keep current order
    }

    func validateDrop(info: DropInfo) -> Bool {
        draggingEntry != nil
    }
}
