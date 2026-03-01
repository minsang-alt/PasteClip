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
            Button {
                isSearchExpanded = true
                isSearchFocused = true
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: DesignTokens.Nav.searchIconSize, weight: .medium))
                    .foregroundStyle(DesignTokens.Nav.inactiveTextColor(for: colorScheme))
            }
            .buttonStyle(.plain)

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
                    Button {
                        newPinboardName = ""
                        isAddingPinboard = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(DesignTokens.Nav.inactiveTextColor(for: colorScheme))
                            .frame(width: 24, height: 24)
                            .background(
                                colorScheme == .dark
                                    ? Color.white.opacity(0.06)
                                    : Color.black.opacity(0.04)
                            )
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }

            // Options menu
            Menu {
                // Content type filters
                Menu("Filter by Type") {
                    ForEach(ContentType.allCases, id: \.self) { type in
                        Button {
                            appState.searchState.toggleContentType(type)
                        } label: {
                            if appState.searchState.selectedContentTypes.contains(type) {
                                Label(type.displayName, systemImage: "checkmark")
                            } else {
                                Text(type.displayName)
                            }
                        }
                    }
                    if !appState.searchState.selectedContentTypes.isEmpty {
                        Divider()
                        Button("Clear Filters") {
                            appState.searchState.selectedContentTypes = []
                        }
                    }
                }

                // Date filters
                Menu("Filter by Date") {
                    ForEach(SearchState.DateFilter.allCases, id: \.self) { filter in
                        Button {
                            appState.searchState.dateFilter = filter
                        } label: {
                            if appState.searchState.dateFilter == filter {
                                Label(filter.rawValue, systemImage: "checkmark")
                            } else {
                                Text(filter.rawValue)
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(DesignTokens.Nav.inactiveTextColor(for: colorScheme))
                    .frame(width: 28, height: 28)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .frame(width: 28)
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

    private func createPinboard() {
        let name = newPinboardName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let pinboard = Pinboard(name: name, displayOrder: pinboards.count)
        modelContext.insert(pinboard)
        try? modelContext.save()
        newPinboardName = ""
        appState.selectedTab = .pinboard(pinboard.id)
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
                    : (isHovered ? DesignTokens.Nav.activeBackground(for: colorScheme).opacity(0.5) : Color.clear)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .animation(.easeInOut(duration: 0.15), value: isActive)
    }
}
