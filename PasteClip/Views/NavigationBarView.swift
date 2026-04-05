import SwiftUI
import SwiftData

struct NavigationBarView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Pinboard.displayOrder) private var pinboards: [Pinboard]

    @State private var isSearchExpanded = false
    @State private var isAddingPinboard = false
    @State private var newPinboardName = ""
    @State private var renamingPinboard: Pinboard?
    @State private var renameText = ""
    @State private var isShowingClearAlert = false
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        ZStack {
            if isSearchExpanded {
                searchExpandedBar
                    .transition(.opacity)
            } else {
                navigationBar
                    .transition(.opacity)
            }
        }
        .frame(height: DesignTokens.Nav.height)
        .animation(.easeInOut(duration: 0.2), value: isSearchExpanded)
        .alert("New Pinboard", isPresented: $isAddingPinboard) {
            TextField("Name", text: $newPinboardName)
            Button("Cancel", role: .cancel) { newPinboardName = "" }
            Button("Create") { createPinboard() }
        }
        .onChange(of: appState.clearHistoryRequested) { _, newValue in
            if newValue {
                appState.clearHistoryRequested = false
                isShowingClearAlert = true
            }
        }
        .alert("Clear All History", isPresented: $isShowingClearAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) { clearHistory() }
        } message: {
            Text("This will permanently delete all clipboard history. Pinboard items will not be affected.")
        }
        .alert("Rename Pinboard", isPresented: .init(
            get: { renamingPinboard != nil },
            set: { if !$0 { renamingPinboard = nil } }
        )) {
            TextField("Name", text: $renameText)
            Button("Cancel", role: .cancel) { renamingPinboard = nil }
            Button("Save") {
                renamingPinboard?.name = renameText
                renamingPinboard = nil
                try? modelContext.save()
            }
        }
    }

    // MARK: - Navigation Bar (default state)

    private var navigationBar: some View {
        HStack(spacing: 8) {
            // Search icon
            NavIconButton(
                icon: "magnifyingglass",
                iconSize: 12,
                colorScheme: colorScheme
            ) {
                isSearchExpanded = true
                isSearchFocused = true
            }

            // Tab scroll area
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    // History tab
                    navTab(
                        label: "History",
                        icon: "clock",
                        isActive: appState.selectedTab == .history
                    ) {
                        appState.selectedTab = .history
                    }

                    if !pinboards.isEmpty {
                        Divider()
                            .frame(height: 18)
                            .padding(.horizontal, 2)
                    }

                    // Pinboard tabs
                    ForEach(pinboards) { pinboard in
                        navTab(
                            label: pinboard.name,
                            dotColor: .orange,
                            isActive: appState.selectedTab == .pinboard(pinboard.id)
                        ) {
                            appState.selectedTab = .pinboard(pinboard.id)
                        }
                        .contextMenu {
                            Button("Rename") {
                                renameText = pinboard.name
                                renamingPinboard = pinboard
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                deletePinboard(pinboard)
                            }
                        }
                    }

                    // Add button
                    NavIconButton(
                        icon: "plus",
                        iconSize: 11,
                        colorScheme: colorScheme
                    ) {
                        newPinboardName = ""
                        isAddingPinboard = true
                    }
                }
            }

            // Options menu
            optionsMenuButton

            // Clear history button (only in History tab)
            if appState.selectedTab == .history {
                NavIconButton(
                    icon: "trash",
                    iconSize: 13,
                    colorScheme: colorScheme
                ) {
                    isShowingClearAlert = true
                }
                .help("Clear All History")
            }
        }
        .padding(.horizontal, DesignTokens.Nav.horizontalPadding)
    }

    // MARK: - Search Expanded Bar

    private var searchExpandedBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.tertiary)

                TextField("Search clips...", text: searchTextBinding)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .focused($isSearchFocused)
                    .onAppear {
                        isSearchFocused = true
                    }

                if !appState.searchState.searchText.isEmpty {
                    Button {
                        appState.searchState.clearSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.quaternary.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .frame(maxWidth: 260)

            Button("Cancel") {
                appState.searchState.clearSearch()
                isSearchExpanded = false
            }
            .buttonStyle(.plain)
            .font(.system(size: 13, weight: .regular))
            .foregroundStyle(.blue)

            Spacer()
        }
        .padding(.horizontal, DesignTokens.Nav.horizontalPadding)
    }

    // MARK: - Tab Component

    private func navTab(
        label: String,
        icon: String? = nil,
        dotColor: Color? = nil,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        NavTabButton(
            label: label,
            icon: icon,
            dotColor: dotColor,
            isActive: isActive,
            colorScheme: colorScheme,
            action: action
        )
    }

    // MARK: - Bindings & Actions

    private var searchTextBinding: Binding<String> {
        Binding(
            get: { appState.searchState.searchText },
            set: { appState.searchState.updateSearch($0) }
        )
    }

    private var optionsMenuButton: some View {
        OptionsMenuButton(
            colorScheme: colorScheme,
            searchState: appState.searchState
        )
    }

    private func createPinboard() {
        let name = newPinboardName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let pinboard = Pinboard(name: name, displayOrder: pinboards.count)
        modelContext.insert(pinboard)
        try? modelContext.save()
        newPinboardName = ""
        appState.selectedTab = .pinboard(pinboard.id)
    }

    private func clearHistory() {
        let pinnedDescriptor = FetchDescriptor<PinboardEntry>()
        let pinnedItemIDs: Set<UUID> = {
            guard let entries = try? modelContext.fetch(pinnedDescriptor) else { return [] }
            return Set(entries.compactMap { $0.clipboardItem?.id })
        }()

        let allItemsDescriptor = FetchDescriptor<ClipboardItem>()
        guard let allItems = try? modelContext.fetch(allItemsDescriptor) else { return }

        for item in allItems where !pinnedItemIDs.contains(item.id) {
            modelContext.delete(item)
        }
        try? modelContext.save()
    }

    private func deletePinboard(_ pinboard: Pinboard) {
        if appState.selectedTab == .pinboard(pinboard.id) {
            appState.selectedTab = .history
        }
        modelContext.delete(pinboard)
        try? modelContext.save()
    }
}

// MARK: - NavTabButton (extracted for @State hover)

private struct NavTabButton: View {
    let label: String
    let icon: String?
    let dotColor: Color?
    let isActive: Bool
    let colorScheme: ColorScheme
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .medium))
                } else if let dotColor {
                    Circle()
                        .fill(dotColor)
                        .frame(width: DesignTokens.Nav.dotSize, height: DesignTokens.Nav.dotSize)
                }

                Text(label)
                    .font(isActive ? DesignTokens.Nav.activeFont : DesignTokens.Nav.inactiveFont)
                    .lineLimit(1)
            }
            .foregroundStyle(
                isActive
                    ? DesignTokens.Nav.activeTextColor(for: colorScheme)
                    : DesignTokens.Nav.inactiveTextColor(for: colorScheme)
            )
            .padding(.horizontal, 10)
            .frame(height: DesignTokens.Nav.tabHeight)
            .background(
                isActive
                    ? DesignTokens.Nav.activeBackground(for: colorScheme)
                    : (isHovered ? DesignTokens.Nav.activeBackground(for: colorScheme) : Color.clear)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .animation(.easeInOut(duration: 0.15), value: isActive)
    }
}

// MARK: - NavIconButton (icon-only button with hover)

private struct NavIconButton: View {
    let icon: String
    let iconSize: CGFloat
    let colorScheme: ColorScheme
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundStyle(DesignTokens.Nav.inactiveTextColor(for: colorScheme))
                .frame(width: 28, height: DesignTokens.Nav.tabHeight)
                .background(
                    isHovered
                        ? DesignTokens.Nav.activeBackground(for: colorScheme)
                        : Color.clear
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }
}

// MARK: - OptionsMenuButton (NSMenu-based for proper centering)

private struct OptionsMenuButton: View {
    let colorScheme: ColorScheme
    let searchState: SearchState

    @State private var isHovered = false

    var body: some View {
        NavIconButton(
            icon: "ellipsis",
            iconSize: 14,
            colorScheme: colorScheme
        ) {
            showMenu()
        }
    }

    private func showMenu() {
        let menu = NSMenu()

        // Filter by Type submenu
        let typeMenu = NSMenu()
        for type in ContentType.allCases {
            let item = NSMenuItem(title: type.displayName, action: nil, keyEquivalent: "")
            let isSelected = searchState.selectedContentTypes.contains(type)
            if isSelected {
                item.state = .on
            }
            item.target = MenuActionTarget.shared
            item.representedObject = MenuAction.toggleContentType(type, searchState)
            item.action = #selector(MenuActionTarget.performAction(_:))
            typeMenu.addItem(item)
        }
        if !searchState.selectedContentTypes.isEmpty {
            typeMenu.addItem(.separator())
            let clearItem = NSMenuItem(title: "Clear Filters", action: nil, keyEquivalent: "")
            clearItem.target = MenuActionTarget.shared
            clearItem.representedObject = MenuAction.clearContentTypes(searchState)
            clearItem.action = #selector(MenuActionTarget.performAction(_:))
            typeMenu.addItem(clearItem)
        }
        let typeMenuItem = NSMenuItem(title: "Filter by Type", action: nil, keyEquivalent: "")
        typeMenuItem.submenu = typeMenu
        menu.addItem(typeMenuItem)

        // Filter by Date submenu
        let dateMenu = NSMenu()
        for filter in SearchState.DateFilter.allCases {
            let item = NSMenuItem(title: filter.rawValue, action: nil, keyEquivalent: "")
            if searchState.dateFilter == filter {
                item.state = .on
            }
            item.target = MenuActionTarget.shared
            item.representedObject = MenuAction.setDateFilter(filter, searchState)
            item.action = #selector(MenuActionTarget.performAction(_:))
            dateMenu.addItem(item)
        }
        let dateMenuItem = NSMenuItem(title: "Filter by Date", action: nil, keyEquivalent: "")
        dateMenuItem.submenu = dateMenu
        menu.addItem(dateMenuItem)

        // Show menu at mouse location
        menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }
}

// MARK: - NSMenu action helpers

private enum MenuAction {
    case toggleContentType(ContentType, SearchState)
    case clearContentTypes(SearchState)
    case setDateFilter(SearchState.DateFilter, SearchState)
}

@MainActor
private final class MenuActionTarget: NSObject {
    static let shared = MenuActionTarget()

    @objc func performAction(_ sender: NSMenuItem) {
        guard let action = sender.representedObject as? MenuAction else { return }
        Task { @MainActor in
            switch action {
            case .toggleContentType(let type, let state):
                state.toggleContentType(type)
            case .clearContentTypes(let state):
                state.selectedContentTypes = []
            case .setDateFilter(let filter, let state):
                state.dateFilter = filter
            }
        }
    }
}
