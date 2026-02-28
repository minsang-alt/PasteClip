import SwiftUI

struct LinkCardContent: View {
    let item: ClipboardItem
    var searchText: String = ""

    private var urlString: String {
        item.textContent ?? ""
    }

    private var domain: String {
        guard let url = URL(string: urlString) else { return urlString }
        return url.host ?? urlString
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "globe")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.blue.opacity(0.8))

                Text(TextHighlighter.highlight(domain, query: searchText))
                    .font(.system(size: 12, weight: .semibold))
                    .lineLimit(1)
                    .foregroundStyle(.primary.opacity(0.9))
            }

            Text(TextHighlighter.highlight(urlString, query: searchText))
                .font(.system(size: 10))
                .lineLimit(3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
