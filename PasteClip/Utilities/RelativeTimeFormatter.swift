import Foundation

@MainActor
struct RelativeTimeFormatter {
    private static let formatter: Foundation.RelativeDateTimeFormatter = {
        let f = Foundation.RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    static func string(for date: Date) -> String {
        formatter.localizedString(for: date, relativeTo: Date())
    }
}
