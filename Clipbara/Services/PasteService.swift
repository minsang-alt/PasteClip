import AppKit

@MainActor
struct PasteService {

    private static let tempDir = NSTemporaryDirectory() + "Clipbara/"

    /// 설정 > General의 "항상 일반 텍스트로 붙여넣기" 값
    nonisolated static let alwaysPlainTextDefaultsKey = "alwaysPastePlainText"

    /// 서식 제거가 의미 있는 항목인지 (RTF/HTML만 해당)
    static func supportsPlainText(_ item: ClipboardItem) -> Bool {
        switch item.contentType {
        case .richText, .html:
            return !(item.textContent?.isEmpty ?? true)
        default:
            return false
        }
    }

    /// 기본값(설정)과 Shift 수정자를 XOR로 합친다.
    /// 설정이 꺼져 있으면 Shift = 서식 제거, 켜져 있으면 Shift = 서식 유지.
    static func resolvePlainText() -> Bool {
        let always = UserDefaults.standard.bool(forKey: alwaysPlainTextDefaultsKey)
        let shiftHeld = NSEvent.modifierFlags.contains(.shift)
        return always != shiftHeld
    }

    /// - Parameter asPlainText: nil이면 설정 + Shift 조합으로 자동 판단
    func paste(item: ClipboardItem, asPlainText: Bool? = nil) {
        if asPlainText ?? Self.resolvePlainText(), Self.supportsPlainText(item) {
            pastePlainText(item: item)
            return
        }

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

            // NSURL writeObjects로 파일 URL을 먼저 쓴 뒤 PNG/TIFF 추가
            // — Ghostty가 이미지 파일로 인식하려면 이 순서가 필요
            if let tempURL {
                pasteboard.writeObjects([tempURL as NSURL])
            }
            pasteboard.setData(pngData, forType: .png)
            pasteboard.setData(tiffData, forType: .tiff)

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
        let asciiOnly = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -_")
        let safeName = sourceApp?
            .unicodeScalars.filter { asciiOnly.contains($0) }
            .reduce(into: "") { $0.append(String($1)) }
            .trimmingCharacters(in: .whitespaces)
        let appName = (safeName?.isEmpty ?? true) ? "Clipbara" : safeName!
        let timestamp = filenameDateFormatter.string(from: Date())
        let filename = "\(appName) \(timestamp).png" as String
        let url = URL(fileURLWithPath: tempDir + filename)
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}
