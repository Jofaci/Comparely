import Foundation
import SwiftData

@Model
final class ComparedItem {
    var id: UUID
    var name: String
    /// Side identity, assigned once at creation and never changed:
    /// 0 = A, 1 = B. This is identity, not a sortable position, so no
    /// view or store method reassigns it after creation. Entry order
    /// inside an item is still `ProConEntry.sortOrder`, which is separate.
    var side: Int
    @Relationship(inverse: \Comparison.items)
    var comparison: Comparison?

    @Relationship(deleteRule: .cascade, inverse: \ProConEntry.item)
    var entries: [ProConEntry] = []

    init(name: String, side: Int, comparison: Comparison? = nil) {
        self.id = UUID()
        self.name = name
        self.side = side
        self.comparison = comparison
    }

    /// "A" for side 0, "B" for any other side value. Always shown next
    /// to the colour block, so side is never signalled by colour alone.
    var sideLabel: String { side == 0 ? "A" : "B" }

    var pros: [ProConEntry] {
        entries.filter { $0.isPro }.sorted { $0.sortOrder < $1.sortOrder }
    }

    var cons: [ProConEntry] {
        entries.filter { !$0.isPro }.sorted { $0.sortOrder < $1.sortOrder }
    }

    /// Pros minus cons. Shown only as a rough tally, never as a decision.
    /// The Review screen labels this "Tally (unweighted)".
    var score: Int { pros.count - cons.count }

    /// Signed tally text, e.g. "+2", "-1", "0".
    var signedScore: String {
        score > 0 ? "+\(score)" : "\(score)"
    }
}
