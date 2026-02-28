import Foundation
import AppKit
import SwiftData

@Model
final class ClipboardItem {
    #Unique<ClipboardItem>([\.contentHash])
    #Index<ClipboardItem>([\.copiedAt], [\.contentHash], [\.sourceAppBundleId])

    var id: UUID
    var contentTypeRaw: String
    @Attribute(.externalStorage) var rawData: Data
    var textContent: String?
    @Attribute(.externalStorage) var thumbnailData: Data?
    var sourceAppName: String?
    var sourceAppBundleId: String?
    var contentHash: String
    var copiedAt: Date
    var userTitle: String?
    var isPinned: Bool

    var contentType: ContentType {
        get { ContentType(rawValue: contentTypeRaw) ?? .unknown }
        set { contentTypeRaw = newValue.rawValue }
    }

    init(
        contentType: ContentType,
        rawData: Data,
        textContent: String? = nil,
        thumbnailData: Data? = nil,
        sourceAppName: String? = nil,
        sourceAppBundleId: String? = nil,
        contentHash: String
    ) {
        self.id = UUID()
        self.contentTypeRaw = contentType.rawValue
        self.rawData = rawData
        self.textContent = textContent
        self.thumbnailData = thumbnailData
        self.sourceAppName = sourceAppName
        self.sourceAppBundleId = sourceAppBundleId
        self.contentHash = contentHash
        self.copiedAt = Date()
        self.isPinned = false
    }

    func dragProvider() -> NSItemProvider {
        switch contentType {
        case .plainText, .richText, .html, .unknown:
            return NSItemProvider(object: (textContent ?? "") as NSString)

        case .image:
            if let image = NSImage(data: rawData),
               let tiff = image.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiff),
               let pngData = bitmap.representation(using: .png, properties: [:]) {
                let dir = FileManager.default.temporaryDirectory.appendingPathComponent("PasteClip", isDirectory: true)
                try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
                let appName = sourceAppName ?? "PasteClip"
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
                let filename = "\(appName) \(formatter.string(from: copiedAt)).png"
                let fileURL = dir.appendingPathComponent(filename)
                try? pngData.write(to: fileURL)
                return NSItemProvider(contentsOf: fileURL) ?? NSItemProvider(object: image)
            }
            return NSItemProvider()

        case .url:
            if let text = textContent, let url = URL(string: text) {
                return NSItemProvider(object: url as NSURL)
            }
            return NSItemProvider(object: (textContent ?? "") as NSString)

        case .fileURL:
            if let text = textContent, let url = URL(string: text) {
                return NSItemProvider(object: url as NSURL)
            }
            return NSItemProvider()

        case .color:
            return NSItemProvider(object: (textContent ?? "") as NSString)
        }
    }
}
