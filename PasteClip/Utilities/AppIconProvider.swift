import AppKit

struct AppIconProvider {
    private nonisolated(unsafe) static let cache = NSCache<NSString, NSImage>()

    static func icon(for bundleId: String?, size: CGFloat = 16) -> NSImage {
        guard let bundleId else {
            let icon = NSImage(systemSymbolName: "app", accessibilityDescription: nil) ?? NSImage()
            icon.size = NSSize(width: size, height: size)
            return icon
        }

        let cacheKey = "\(bundleId):\(Int(size))" as NSString
        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }

        let icon: NSImage
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            icon = NSWorkspace.shared.icon(forFile: url.path)
        } else {
            icon = NSImage(systemSymbolName: "app", accessibilityDescription: nil) ?? NSImage()
        }
        icon.size = NSSize(width: size, height: size)
        cache.setObject(icon, forKey: cacheKey)
        return icon
    }
}
