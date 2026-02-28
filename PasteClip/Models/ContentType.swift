import Foundation

enum ContentType: String, Codable, CaseIterable, Sendable {
    case plainText
    case richText
    case html
    case image
    case url
    case fileURL
    case color
    case unknown

    var displayName: String {
        switch self {
        case .plainText: "Text"
        case .richText: "Rich Text"
        case .html: "HTML"
        case .image: "Image"
        case .url: "Link"
        case .fileURL: "File"
        case .color: "Color"
        case .unknown: "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .plainText: "doc.text"
        case .richText: "doc.richtext"
        case .html: "chevron.left.forwardslash.chevron.right"
        case .image: "photo"
        case .url: "link"
        case .fileURL: "doc"
        case .color: "paintpalette"
        case .unknown: "questionmark.square"
        }
    }
}
