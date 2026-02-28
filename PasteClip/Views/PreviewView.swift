import SwiftUI
import AppKit

struct PreviewView: View {
    let item: ClipboardItem
    let onClose: () -> Void
    let onPaste: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var cachedNSImage: NSImage?
    @State private var imageMetadata: (width: Int, height: Int)?

    var body: some View {
        VStack(spacing: 0) {
            previewHeader
            Divider().opacity(0.3)
            previewContent
            Divider().opacity(0.3)
            previewFooter
        }
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06),
                    lineWidth: 0.5
                )
        )
        .shadow(color: .black.opacity(0.15), radius: 20, y: 6)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.96, anchor: .bottom)),
            removal: .opacity.combined(with: .scale(scale: 0.98, anchor: .bottom))
        ))
        .task(id: item.id) {
            if item.contentType == .image {
                let img = NSImage(data: item.rawData)
                cachedNSImage = img
                if let rep = img?.representations.first {
                    imageMetadata = (rep.pixelsWide, rep.pixelsHigh)
                }
            }
        }
    }

    // MARK: - Background

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(white: 0.12)
            : Color(white: 0.99)
    }

    // MARK: - Header

    private var previewHeader: some View {
        HStack(spacing: 10) {
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary.opacity(0.7))
            }
            .buttonStyle(.plain)

            Image(systemName: item.contentType.systemImage)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(headerAccentColor)

            Text(item.userTitle ?? item.contentType.displayName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)

            if let appName = item.sourceAppName {
                Text("·")
                    .foregroundStyle(.quaternary)
                Text(appName)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let bundleId = item.sourceAppBundleId {
                Image(nsImage: AppIconProvider.icon(for: bundleId, size: 24))
                    .resizable()
                    .frame(width: 24, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            }

            Button(action: onPaste) {
                HStack(spacing: 4) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 11, weight: .medium))
                    Text("Paste")
                        .font(.system(size: 12, weight: .medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Color.accentColor.opacity(0.12))
                .foregroundStyle(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var headerAccentColor: Color {
        switch item.contentType {
        case .plainText, .richText, .html, .unknown: return .blue
        case .image: return .purple
        case .url: return .teal
        case .fileURL: return .orange
        case .color: return .pink
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var previewContent: some View {
        Group {
            switch item.contentType {
            case .plainText, .richText, .html, .unknown:
                textPreview
            case .image:
                imagePreview
            case .url:
                urlPreview
            case .fileURL:
                filePreview
            case .color:
                colorPreview
            }
        }
        .frame(height: 200)
        .clipped()
    }

    // MARK: - Text Preview

    private var textPreview: some View {
        ScrollView {
            Text(item.textContent ?? "...")
                .font(.system(size: 13.5, design: isCodeLike ? .monospaced : .default))
                .lineSpacing(5)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(16)
        }
        .frame(maxHeight: .infinity)
    }

    private var isCodeLike: Bool {
        guard let text = item.textContent else { return false }
        let codeKeywords = ["func ", "var ", "let ", "class ", "struct ", "import ", "def ", "return ", "if ", "for "]
        return codeKeywords.contains { text.contains($0) }
    }

    // MARK: - Image Preview

    private var imagePreview: some View {
        Group {
            if let nsImage = cachedNSImage {
                ZStack {
                    checkerboardBackground
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
                .drawingGroup()
                .frame(maxHeight: .infinity)
                .frame(maxWidth: .infinity)
                .padding(16)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    Text("Unable to load image")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
            }
        }
    }

    private var checkerboardBackground: some View {
        Canvas { context, size in
            let cellSize: CGFloat = 8
            let rows = Int(ceil(size.height / cellSize))
            let cols = Int(ceil(size.width / cellSize))
            for row in 0..<rows {
                for col in 0..<cols {
                    let isLight = (row + col) % 2 == 0
                    let rect = CGRect(
                        x: CGFloat(col) * cellSize,
                        y: CGFloat(row) * cellSize,
                        width: cellSize,
                        height: cellSize
                    )
                    context.fill(
                        Path(rect),
                        with: .color(isLight
                            ? Color(white: colorScheme == .dark ? 0.2 : 0.95)
                            : Color(white: colorScheme == .dark ? 0.15 : 0.88))
                    )
                }
            }
        }
    }

    // MARK: - URL Preview

    private var urlPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            let urlString = item.textContent ?? ""
            let url = URL(string: urlString)
            let domain = url?.host ?? urlString

            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.teal.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: "globe")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.teal)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(domain)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(urlString)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .textSelection(.enabled)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(16)
    }

    // MARK: - File Preview

    private var filePreview: some View {
        HStack(spacing: 14) {
            let fileIcon: NSImage = {
                if let urlString = String(data: item.rawData, encoding: .utf8),
                   let url = URL(string: urlString) {
                    return NSWorkspace.shared.icon(forFile: url.path)
                }
                return NSWorkspace.shared.icon(for: .data)
            }()

            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.orange.opacity(0.08))
                    .frame(width: 56, height: 56)
                Image(nsImage: fileIcon)
                    .resizable()
                    .frame(width: 40, height: 40)
            }

            VStack(alignment: .leading, spacing: 4) {
                let fileName = item.textContent?.components(separatedBy: "/").last ?? "File"
                Text(fileName)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(2)

                Text(item.textContent ?? "")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .textSelection(.enabled)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }

    // MARK: - Color Preview

    private var colorPreview: some View {
        HStack(spacing: 20) {
            let hexString = item.textContent ?? "#000000"
            let nsColor = NSColor.fromHex(hexString) ?? .black

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(nsColor: nsColor))
                .frame(width: 96, height: 96)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(.quaternary, lineWidth: 1)
                )
                .shadow(color: Color(nsColor: nsColor).opacity(0.3), radius: 12, y: 4)

            VStack(alignment: .leading, spacing: 8) {
                Text(hexString)
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .textSelection(.enabled)

                let (r, g, b) = rgbComponents(from: nsColor)
                Text("RGB(\(r), \(g), \(b))")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
    }

    private func rgbComponents(from color: NSColor) -> (Int, Int, Int) {
        let c = color.usingColorSpace(.sRGB) ?? color
        return (
            Int(c.redComponent * 255),
            Int(c.greenComponent * 255),
            Int(c.blueComponent * 255)
        )
    }

    // MARK: - Footer

    private var previewFooter: some View {
        HStack {
            Text(metadataText)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)

            Spacer()

            Text(RelativeTimeFormatter.string(for: item.copiedAt))
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var metadataText: String {
        switch item.contentType {
        case .plainText, .richText, .html, .unknown:
            let text = item.textContent ?? ""
            let charCount = text.count
            let wordCount = text.split { $0.isWhitespace || $0.isNewline }.count
            let lineCount = text.components(separatedBy: .newlines).count
            return "\(charCount.formatted())자 · \(wordCount.formatted())단어 · \(lineCount.formatted())줄"
        case .image:
            let kb = item.rawData.count / 1024
            var sizeText: String
            if kb > 1024 {
                sizeText = String(format: "%.1fMB", Double(kb) / 1024.0)
            } else {
                sizeText = "\(kb)KB"
            }
            if let meta = imageMetadata {
                return "\(meta.width) × \(meta.height) · \(sizeText)"
            }
            return sizeText
        case .url:
            return item.textContent ?? "Link"
        case .fileURL:
            return item.textContent ?? "File"
        case .color:
            return item.textContent ?? ""
        }
    }
}
