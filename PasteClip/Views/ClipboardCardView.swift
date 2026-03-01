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
    let onSelect: (ClipboardItem) -> Void
    let onPaste: (ClipboardItem) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @State private var isHovered = false
    @State private var isRenaming = false
    @State private var renameText = ""

    private var headerHeight: CGFloat {
        max(DesignTokens.Header.minHeight, cardHeight * DesignTokens.Header.heightRatio)
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView

            if item.contentType == .image || item.contentType == .color {
                cardContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                VStack(spacing: 0) {
                    cardContent
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                    Spacer(minLength: 4)

                    footerView
                }
                .padding(.all, DesignTokens.Body.padding)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    isSelected
                        ? DesignTokens.Selection.borderColor
                        : (colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)),
                    lineWidth: isSelected ? DesignTokens.Selection.borderWidth : DesignTokens.Selection.defaultBorderWidth
                )
        )
        .shadow(
            color: .black.opacity(
                isSelected ? DesignTokens.Selection.selectedShadowOpacity
                : (isHovered ? DesignTokens.Selection.hoverShadowOpacity : DesignTokens.Selection.defaultShadowOpacity)
            ),
            radius: isSelected ? DesignTokens.Selection.selectedShadowRadius
                : (isHovered ? DesignTokens.Selection.hoverShadowRadius : DesignTokens.Selection.defaultShadowRadius),
            y: isSelected ? 6 : (isHovered ? 4 : 2)
        )
        .brightness(isHovered && !isSelected ? 0.03 : 0)
        .animation(.easeOut(duration: 0.15), value: isHovered)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture(count: 2) {
            onPaste(item)
        }
        .onTapGesture(count: 1) {
            onSelect(item)
        }
        .optionalDrag(enabled: enableDrag) { item.dragProvider() }
        .contextMenu {
            Button("Paste") { onPaste(item) }
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
            Button("Delete", role: .destructive) {
                deleteItem()
            }
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

    // MARK: - Header View

    private var headerView: some View {
        ZStack {
            DesignTokens.headerColor(for: item.contentType, itemColor: item.textContent)

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.userTitle ?? item.contentType.displayName)
                        .font(DesignTokens.Header.titleFont)
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text(RelativeTimeFormatter.string(for: item.copiedAt))
                        .font(DesignTokens.Header.subtitleFont)
                        .foregroundStyle(.white.opacity(DesignTokens.Header.subtitleOpacity))
                        .lineLimit(1)
                }

                Spacer()

                if let bundleId = item.sourceAppBundleId {
                    Image(nsImage: AppIconProvider.icon(for: bundleId, size: 48))
                        .resizable()
                        .frame(
                            width: DesignTokens.Header.appIconSize,
                            height: DesignTokens.Header.appIconSize
                        )
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Header.appIconCornerRadius, style: .continuous))
                        .background(
                            RoundedRectangle(cornerRadius: DesignTokens.Header.appIconCornerRadius, style: .continuous)
                                .fill(.white)
                                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                        )
                }
            }
            .padding(.top, DesignTokens.Header.paddingTop)
            .padding(.leading, DesignTokens.Header.paddingLeading)
            .padding(.bottom, DesignTokens.Header.paddingBottom)
            .padding(.trailing, DesignTokens.Header.paddingTrailing)
        }
        .frame(height: headerHeight)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Footer View (Badge Style)

    @ViewBuilder
    private var footerView: some View {
        HStack(spacing: 6) {
            Spacer()

            Text(footerInfo)
                .font(DesignTokens.Badge.font)
                .foregroundStyle(DesignTokens.Badge.textColor(for: colorScheme))
                .padding(.vertical, DesignTokens.Badge.verticalPadding)
                .padding(.horizontal, DesignTokens.Badge.horizontalPadding)
                .background(DesignTokens.Badge.backgroundColor(for: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Badge.cornerRadius, style: .continuous))

            Image(systemName: "line.3.horizontal")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(DesignTokens.Badge.textColor(for: colorScheme))
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

    private var cardBackground: some ShapeStyle {
        colorScheme == .dark
            ? AnyShapeStyle(Color(white: 0.13))
            : AnyShapeStyle(Color(white: 0.99))
    }

    // MARK: - Content

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
    func optionalDrag(enabled: Bool, provider: @escaping () -> NSItemProvider) -> some View {
        if enabled {
            self.onDrag(provider)
        } else {
            self
        }
    }
}
