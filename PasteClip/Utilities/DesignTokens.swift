import SwiftUI

enum DesignTokens {
    // MARK: - Card Header Colors (by content type)

    static func headerColor(for contentType: ContentType, itemColor: String? = nil) -> Color {
        switch contentType {
        case .plainText, .richText, .html:
            return Color(red: 0.247, green: 0.388, blue: 0.886) // #3F63E2
        case .image:
            return Color(red: 0.169, green: 0.231, blue: 0.584) // #2B3B95
        case .url:
            return Color(red: 0.0, green: 0.588, blue: 0.533)   // #009688 teal
        case .fileURL:
            return Color(red: 0.898, green: 0.494, blue: 0.129) // #E57E21 orange
        case .color:
            if let hex = itemColor {
                return Color(hex: hex) ?? Color.gray
            }
            return Color.gray
        case .unknown:
            return Color(red: 0.247, green: 0.388, blue: 0.886)
        }
    }

    // MARK: - Card Header

    enum Header {
        static let titleFont: Font = .system(size: 16, weight: .bold)
        static let subtitleFont: Font = .system(size: 12, weight: .regular)
        static let subtitleOpacity: Double = 0.8
        static let appIconSize: CGFloat = 44
        static let appIconCornerRadius: CGFloat = 11
        static let heightRatio: CGFloat = 0.30
        static let minHeight: CGFloat = 72
        static let paddingTop: CGFloat = 16
        static let paddingLeading: CGFloat = 16
        static let paddingBottom: CGFloat = 12
        static let paddingTrailing: CGFloat = 12
    }

    // MARK: - Card Body

    enum Body {
        static let padding: CGFloat = 16
        static let fontSize: CGFloat = 13
        static let lineSpacing: CGFloat = 6.5
        static let maxLines: Int = 6

        static func textColor(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color(white: 0.88)
                : Color(red: 0.2, green: 0.2, blue: 0.2) // #333333
        }
    }

    // MARK: - Card Footer Badge

    enum Badge {
        static let font: Font = .system(size: 11, weight: .medium)
        static let verticalPadding: CGFloat = 4
        static let horizontalPadding: CGFloat = 8
        static let cornerRadius: CGFloat = 8

        static func backgroundColor(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color(white: 0.2)
                : Color(red: 0.949, green: 0.949, blue: 0.969) // #F2F2F7
        }

        static func textColor(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color(white: 0.6)
                : Color(red: 0.4, green: 0.4, blue: 0.4) // #666666
        }
    }

    // MARK: - Card Selection

    enum Selection {
        static let borderColor = Color(red: 0.231, green: 0.443, blue: 0.953) // #3B71F3
        static let borderWidth: CGFloat = 3.5
        static let defaultBorderWidth: CGFloat = 0.5
        static let selectedShadowOpacity: Double = 0.18
        static let selectedShadowRadius: CGFloat = 12
        static let defaultShadowOpacity: Double = 0.09
        static let defaultShadowRadius: CGFloat = 4
        static let hoverShadowOpacity: Double = 0.12
        static let hoverShadowRadius: CGFloat = 8
    }

    // MARK: - Navigation Bar

    enum Nav {
        static let height: CGFloat = 46
        static let horizontalPadding: CGFloat = 16
        static let tabHeight: CGFloat = 28
        static let tabCornerRadius: CGFloat = 14
        static let activeFont: Font = .system(size: 13, weight: .medium)
        static let inactiveFont: Font = .system(size: 13, weight: .regular)
        static let dotSize: CGFloat = 8
        static let searchIconSize: CGFloat = 16

        static func activeBackground(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color(white: 0.25)
                : Color(red: 0.898, green: 0.898, blue: 0.918) // #E5E5EA
        }

        static func activeTextColor(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color(white: 0.95)
                : Color(red: 0.2, green: 0.2, blue: 0.2) // #333333
        }

        static func inactiveTextColor(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark
                ? Color(white: 0.5)
                : Color(red: 0.4, green: 0.4, blue: 0.4) // #666666
        }
    }

    // MARK: - Checkerboard

    enum Checkerboard {
        static let cellSize: CGFloat = 8
        static let lightColor = Color.white
        static let darkColor = Color(white: 0.96) // #F5F5F5
    }
}

// MARK: - Color hex init helper

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        guard hexSanitized.count == 6,
              let hexNumber = UInt64(hexSanitized, radix: 16) else {
            return nil
        }

        let r = Double((hexNumber & 0xFF0000) >> 16) / 255.0
        let g = Double((hexNumber & 0x00FF00) >> 8) / 255.0
        let b = Double(hexNumber & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}
