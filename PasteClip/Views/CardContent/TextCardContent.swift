import SwiftUI

struct TextCardContent: View {
    let item: ClipboardItem
    var searchText: String = ""
    @Environment(\.colorScheme) private var colorScheme
    @State private var isCode: Bool = false

    var body: some View {
        Group {
            if searchText.isEmpty {
                Text(item.textContent ?? "...")
            } else {
                Text(TextHighlighter.highlight(item.textContent ?? "...", query: searchText))
            }
        }
        .font(.system(size: DesignTokens.Body.fontSize, design: isCode ? .monospaced : .default))
        .lineSpacing(DesignTokens.Body.lineSpacing)
        .lineLimit(DesignTokens.Body.maxLines)
        .multilineTextAlignment(.leading)
        .foregroundStyle(DesignTokens.Body.textColor(for: colorScheme))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task(id: item.id) {
            guard let text = item.textContent else { return }
            let codeIndicators = ["func ", "var ", "let ", "class ", "import ", "def ", "return ", "{", "}", "=>", "->", "();", "//", "/*"]
            isCode = codeIndicators.contains { text.contains($0) }
        }
    }
}
