import Foundation
import SwiftData

@Model
final class PinboardEntry {
    var id: UUID
    var displayOrder: Int
    var addedAt: Date

    var clipboardItem: ClipboardItem?
    var pinboard: Pinboard?

    init(clipboardItem: ClipboardItem, pinboard: Pinboard, displayOrder: Int = 0) {
        self.id = UUID()
        self.displayOrder = displayOrder
        self.addedAt = Date()
        self.clipboardItem = clipboardItem
        self.pinboard = pinboard
    }
}
