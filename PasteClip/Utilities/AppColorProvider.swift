import AppKit
import SwiftUI

@MainActor
struct AppColorProvider {
    private static var cache: [String: NSColor] = [:]

    static func dominantColor(for bundleId: String?) -> Color {
        guard let bundleId else { return Color.gray }

        if let cached = cache[bundleId] {
            return Color(nsColor: cached)
        }

        let icon = AppIconProvider.icon(for: bundleId, size: 32)
        let color = averageColor(from: icon)
        cache[bundleId] = color
        return Color(nsColor: color)
    }

    private static func averageColor(from image: NSImage) -> NSColor {
        let size = 8
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return .systemGray
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * size
        var pixelData = [UInt8](repeating: 0, count: size * size * bytesPerPixel)

        guard let context = CGContext(
            data: &pixelData,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return .systemGray
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size, height: size))

        var totalR: Double = 0
        var totalG: Double = 0
        var totalB: Double = 0
        var count: Double = 0

        for y in 0..<size {
            for x in 0..<size {
                let offset = (y * size + x) * bytesPerPixel
                let a = Double(pixelData[offset + 3]) / 255.0
                guard a > 0.5 else { continue }

                totalR += Double(pixelData[offset])
                totalG += Double(pixelData[offset + 1])
                totalB += Double(pixelData[offset + 2])
                count += 1
            }
        }

        guard count > 0 else { return .systemGray }

        let r = totalR / count / 255.0
        let g = totalG / count / 255.0
        let b = totalB / count / 255.0

        // Ensure the color isn't too light for white text readability
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        if luminance > 0.75 {
            return NSColor(red: r * 0.7, green: g * 0.7, blue: b * 0.7, alpha: 1.0)
        }

        return NSColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}
