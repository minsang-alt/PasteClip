import SwiftUI
import SwiftData

struct ClipboardCardView: View {
    let item: ClipboardItem
    var isSelected: Bool = false
    var searchText: String = ""
    var cardWidth: CGFloat = 190
    var cardHeight: CGFloat = 240
    var pinboards: [Pinboard] = []
    var enableDrag: Bool = true
    var showsManagementMenu: Bool = true
    let onSelect: (ClipboardItem) -> Void
    let onPaste: (ClipboardItem) -> Void
    var onDelete: (() -> Void)? = nil
    var onRemoveFromPinboard: (() -> Void)? = nil

    @Environment(AppState.self) private var appState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @State private var isHovered = false
    @State private var isRenaming = false
    @State private var renameText = ""

    var body: some View {
        if item.isDeleted || item.modelContext == nil {
            EmptyView()
        } else {
            cardBody
        }
    }

    private var cardBody: some View {
        cardSurface
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture(perform: handleTap)
        .optionalDrag(enabled: enableDrag) {
            appState.draggedClipboardItemID = item.id
            return item.dragProvider()
        } preview: {
            dragPreview
        }
        .optionalContextMenu(enabled: hasMenu) {
            menuItems
        }
        .alert("Rename", isPresented: $isRenaming) {
            TextField("Card name", text: $renameText)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                let trimmed = renameText.trimmingCharacters(in: .whitespaces)
                item.userTitle = trimmed.isEmpty ? nil : trimmed
                try? modelContext.save()
            }
        }
    }

    private var hasMenu: Bool {
        showsManagementMenu || onRemoveFromPinboard != nil
    }

    @ViewBuilder
    private var menuItems: some View {
        if PasteService.supportsPlainText(item) {
            Button("Paste with Formatting") { appState.paste(item, asPlainText: false) }
            Button("Paste as Plain Text") { appState.paste(item, asPlainText: true) }
        } else {
            Button("Paste") { onPaste(item) }
        }
        if showsManagementMenu {
            Divider()
            Button("Rename") {
                renameText = item.userTitle ?? ""
                isRenaming = true
            }
            if !pinboards.isEmpty {
                Menu("Add to Pinboard") {
                    ForEach(pinboards) { pinboard in
                        let alreadyAdded = pinboard.entries.contains { $0.clipboardItem?.id == item.id }
                        Button {
                            addToPinboard(pinboard)
                        } label: {
                            if alreadyAdded {
                                Label(pinboard.name, systemImage: "checkmark")
                            } else {
                                Text(pinboard.name)
                            }
                        }
                        .disabled(alreadyAdded)
                    }
                }
            }
            Divider()
            Button("Delete Clip", role: .destructive) {
                deleteItem()
                onDelete?()
            }
        }
        if let onRemoveFromPinboard {
            Divider()
            Button("Remove from Pinboard", role: .destructive) {
                onRemoveFromPinboard()
            }
        }
    }

    private var cardSurface: some View {
        VStack(spacing: DesignTokens.Card.contentSpacing) {
            headerView

            contentView

            footerView
        }
        .padding(.top, DesignTokens.Card.topPadding)
        .padding(.horizontal, DesignTokens.Card.horizontalPadding)
        .padding(.bottom, 8)
        .frame(width: cardWidth, height: cardHeight)
        .background(cardFillColor)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Card.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.Card.cornerRadius, style: .continuous)
                .strokeBorder(
                    isSelected
                        ? DesignTokens.Selection.borderColor
                        : (isHovered
                            ? DesignTokens.Selection.borderColor.opacity(0.45)
                            : DesignTokens.Card.borderColor(for: colorScheme)),
                    lineWidth: isSelected
                        ? DesignTokens.Selection.borderWidth
                        : (isHovered ? DesignTokens.Selection.hoverBorderWidth : DesignTokens.Selection.defaultBorderWidth)
                )
        )
        .shadow(
            color: cardShadowColor,
            radius: isSelected ? DesignTokens.Selection.selectedShadowRadius
                : (isHovered ? DesignTokens.Selection.hoverShadowRadius : DesignTokens.Selection.defaultShadowRadius),
            y: isSelected ? 6 : (isHovered ? 5 : 2)
        )
        .scaleEffect(isSelected ? 1.01 : (isHovered ? DesignTokens.Selection.hoverScale : 1.0))
        .offset(y: isHovered && !isSelected ? DesignTokens.Selection.hoverLift : 0)
        .brightness(isHovered && !isSelected ? 0.04 : 0)
        .zIndex(isHovered ? 1 : 0)
        .animation(.spring(response: 0.28, dampingFraction: 0.75), value: isHovered)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private var dragPreview: some View {
        cardSurface
            .opacity(0.36)
            .scaleEffect(0.94)
    }

    private func handleTap() {
        onSelect(item)
        onPaste(item)
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack(alignment: .center, spacing: 8) {
            typeBadge

            Text(RelativeTimeFormatter.string(for: item.copiedAt))
                .font(DesignTokens.Header.subtitleFont)
                .foregroundStyle(DesignTokens.Body.textColor(for: colorScheme).opacity(0.62))
                .lineLimit(1)

            Spacer(minLength: 4)

            if let bundleId = item.sourceAppBundleId {
                Image(nsImage: AppIconProvider.icon(for: bundleId, size: 40))
                    .resizable()
                    .frame(
                        width: DesignTokens.Header.appIconSize,
                        height: DesignTokens.Header.appIconSize
                    )
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Header.appIconCornerRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.Header.appIconCornerRadius, style: .continuous)
                            .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.6), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.14), radius: 3, y: 1)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var typeBadge: some View {
        let tint = DesignTokens.typeTint(for: item.contentType, itemColor: item.textContent)

        return HStack(spacing: 5) {
            Image(systemName: item.contentType.systemImage)
                .font(.system(size: 10, weight: .semibold))

            Text(item.userTitle ?? item.contentType.displayName)
                .font(DesignTokens.Header.titleFont)
                .lineLimit(1)
        }
        .foregroundStyle(tint)
        .padding(.vertical, DesignTokens.Header.badgeVerticalPadding)
        .padding(.horizontal, DesignTokens.Header.badgeHorizontalPadding)
        .background(tint.opacity(colorScheme == .dark ? 0.18 : 0.20))
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Header.badgeCornerRadius, style: .continuous))
    }

    // MARK: - Footer View (Badge Style)

    @ViewBuilder
    private var footerView: some View {
        HStack(spacing: 6) {
            Text(footerInfo)
                .font(DesignTokens.Badge.font)
                .foregroundStyle(DesignTokens.Badge.textColor(for: colorScheme))
                .padding(.vertical, DesignTokens.Badge.verticalPadding)
                .padding(.horizontal, DesignTokens.Badge.horizontalPadding)
                .background(DesignTokens.Badge.backgroundColor(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Badge.cornerRadius, style: .continuous))

            Spacer()

            if hasMenu {
                Menu {
                    menuItems
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DesignTokens.Badge.textColor(for: colorScheme))
                        .opacity(isHovered || isSelected ? 0.72 : 0.34)
                        .frame(width: 24, height: 18)
                        .contentShape(Rectangle())
                }
                .menuStyle(.button)
                .buttonStyle(.plain)
                .menuIndicator(.hidden)
                .fixedSize()
                .help("More actions")
            }
        }
    }

    private var footerInfo: String {
        switch item.contentType {
        case .plainText, .richText, .html, .unknown:
            let count = item.textContent?.count ?? 0
            if count >= 1000 {
                return "\(String(format: "%.1f", Double(count) / 1000))K chars"
            }
            return "\(count) chars"
        case .url:
            return "URL"
        case .fileURL:
            return "File"
        case .image:
            let kb = item.rawData.count / 1024
            return "\(kb) KB"
        case .color:
            return item.textContent ?? ""
        }
    }

    // MARK: - Card Background

    private var cardFillColor: Color {
        if isSelected {
            return colorScheme == .dark
                ? Color(red: 0.105, green: 0.125, blue: 0.165)
                : Color(red: 0.965, green: 0.975, blue: 1.0)
        }
        return DesignTokens.Card.backgroundColor(for: colorScheme)
    }

    private var cardShadowColor: Color {
        if isSelected {
            return DesignTokens.Selection.borderColor.opacity(DesignTokens.Selection.selectedShadowOpacity)
        }
        return .black.opacity(isHovered ? DesignTokens.Selection.hoverShadowOpacity : DesignTokens.Selection.defaultShadowOpacity)
    }

    // MARK: - Content

    private var contentView: some View {
        Group {
            if item.contentType == .image || item.contentType == .color {
                cardContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .strokeBorder(DesignTokens.Card.borderColor(for: colorScheme), lineWidth: 0.5)
                    )
            } else {
                cardContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.vertical, 2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    @ViewBuilder
    private var cardContent: some View {
        switch item.contentType {
        case .plainText, .richText, .html:
            TextCardContent(item: item, searchText: searchText)
        case .image:
            ImageCardContent(item: item)
        case .url:
            LinkCardContent(item: item, searchText: searchText)
        case .fileURL:
            FileCardContent(item: item, searchText: searchText)
        case .color:
            ColorCardContent(item: item)
        case .unknown:
            TextCardContent(item: item, searchText: searchText)
        }
    }

    private func addToPinboard(_ pinboard: Pinboard) {
        let nextOrder = (pinboard.entries.map(\.displayOrder).max() ?? -1) + 1
        let entry = PinboardEntry(clipboardItem: item, pinboard: pinboard, displayOrder: nextOrder)
        modelContext.insert(entry)
        item.isPinned = true
        try? modelContext.save()
    }

    private func deleteItem() {
        let itemId = item.id
        let descriptor = FetchDescriptor<PinboardEntry>(
            predicate: #Predicate { $0.clipboardItem?.id == itemId }
        )
        if let entries = try? modelContext.fetch(descriptor) {
            for entry in entries {
                modelContext.delete(entry)
            }
        }
        modelContext.delete(item)
        try? modelContext.save()
    }
}

// MARK: - Conditional Drag Modifier

private extension View {
    @ViewBuilder
    func optionalDrag<Preview: View>(
        enabled: Bool,
        provider: @escaping () -> NSItemProvider,
        @ViewBuilder preview: () -> Preview
    ) -> some View {
        if enabled {
            self.onDrag(provider, preview: preview)
        } else {
            self
        }
    }

    @ViewBuilder
    func optionalContextMenu<Content: View>(
        enabled: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        if enabled {
            self.contextMenu(menuItems: content)
        } else {
            self
        }
    }
}
