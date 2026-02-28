import Foundation
import SwiftData

@Model
final class Pinboard {
    var id: UUID
    var name: String
    var displayOrder: Int
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \PinboardEntry.pinboard)
    var entries: [PinboardEntry]

    init(name: String, displayOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.displayOrder = displayOrder
        self.createdAt = Date()
        self.entries = []
    }
}
