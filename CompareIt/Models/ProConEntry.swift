import Foundation
import SwiftData

@Model
final class ProConEntry {
    var id: UUID
    var text: String
    var isPro: Bool
    /// Order within its item only. Unrelated to the item's `side`.
    var sortOrder: Int
    @Relationship(inverse: \ComparedItem.entries)
    var item: ComparedItem?

    init(text: String, isPro: Bool, sortOrder: Int, item: ComparedItem? = nil) {
        self.id = UUID()
        self.text = text
        self.isPro = isPro
        self.sortOrder = sortOrder
        self.item = item
    }
}
