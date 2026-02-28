import SwiftUI

enum TextHighlighter {
    static func highlight(
        _ text: String,
        query: String,
        backgroundColor: Color = .accentColor.opacity(0.3)
    ) -> AttributedString {
        var attributed = AttributedString(text)
        guard !query.isEmpty else { return attributed }

        let lowercasedText = text.lowercased()
        let lowercasedQuery = query.lowercased()
        var searchStart = lowercasedText.startIndex

        while let range = lowercasedText.range(of: lowercasedQuery, range: searchStart..<lowercasedText.endIndex) {
            if let attrStart = AttributedString.Index(range.lowerBound, within: attributed),
               let attrEnd = AttributedString.Index(range.upperBound, within: attributed) {
                attributed[attrStart..<attrEnd].backgroundColor = backgroundColor
            }
            searchStart = range.upperBound
        }

        return attributed
    }
}
