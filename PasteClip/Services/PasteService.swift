import AppKit

@MainActor
struct PasteService {

    private static let tempDir = NSTemporaryDirectory() + "PasteClip/"

    func paste(item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.contentType {
        case .plainText, .html, .richText:
            if let text = item.textContent {
                pasteboard.setString(text, forType: .string)
            }
            // Also set original format for rich text / HTML
            if item.contentType == .richText {
                pasteboard.setData(item.rawData, forType: .rtf)
            } else if item.contentType == .html {
                pasteboard.setData(item.rawData, forType: .html)
            }

        case .image:
            guard let image = NSImage(data: item.rawData),
                  let tiffData = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let pngData = bitmap.representation(using: .png, properties: [:]) else {
                pasteboard.setData(item.rawData, forType: .tiff)
                break
            }

            // 임시 PNG 파일 저장 — 터미널 앱(Ghostty 등)이 파일 경로로 이미지를 전달
            let tempURL = Self.writeTempPNG(pngData, sourceApp: item.sourceAppName)

            // PNG + TIFF + 파일 URL 모두 클립보드에 쓰기
            pasteboard.setData(pngData, forType: .png)
            pasteboard.setData(tiffData, forType: .tiff)
            if let tempURL {
                pasteboard.setString(tempURL.absoluteString, forType: .fileURL)
            }

        case .url:
            if let text = item.textContent {
                pasteboard.setString(text, forType: .string)
                if let url = URL(string: text) {
                    pasteboard.setString(url.absoluteString, forType: .URL)
                }
            }

        case .fileURL:
            if let text = item.textContent,
               let urlString = String(data: item.rawData, encoding: .utf8) {
                pasteboard.setString(urlString, forType: .fileURL)
                pasteboard.setString(text, forType: .string)
            }

        case .color:
            if let text = item.textContent {
                pasteboard.setString(text, forType: .string)
            }

        case .unknown:
            pasteboard.setData(item.rawData, forType: .string)
        }
    }

    func pastePlainText(item: ClipboardItem) {
        guard let text = item.textContent else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    /// 오래된 임시 파일 정리 (1시간 이상)
    func cleanupTempFiles() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: Self.tempDir) else { return }
        let cutoff = Date().addingTimeInterval(-3600)
        for file in files {
            let path = Self.tempDir + file
            guard let attrs = try? fm.attributesOfItem(atPath: path),
                  let modified = attrs[.modificationDate] as? Date,
                  modified < cutoff else { continue }
            try? fm.removeItem(atPath: path)
        }
    }

    private static let filenameDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH.mm.ss"
        return f
    }()

    private static func writeTempPNG(_ data: Data, sourceApp: String?) -> URL? {
        try? FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        let appName = sourceApp ?? "PasteClip"
        let timestamp = filenameDateFormatter.string(from: Date())
        let filename = "\(appName) \(timestamp).png"
        let url = URL(fileURLWithPath: tempDir + filename)
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}
