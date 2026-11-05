import Foundation
import SwiftData

@Model
final class Comparison {
    var id: UUID
    var title: String
    var verdict: String
    var createdAt: Date
    var updatedAt: Date

    // Cascade delete, with the inverse on ComparedItem.comparison:
    // deleting a Comparison deletes its items, and deleting an item
    // deletes its entries (see ComparedItem.entries, also cascade).
    // The child sides declare the matching inverse explicitly.
    @Relationship(deleteRule: .cascade, inverse: \ComparedItem.comparison)
    var items: [ComparedItem] = []

    init(title: String, verdict: String = "", createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = UUID()
        self.title = title
        self.verdict = verdict
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Items in display order (A first, then B), by side identity.
    var sortedItems: [ComparedItem] {
        items.sorted { $0.side < $1.side }
    }

    /// Side A: the item whose side is 0. Falls back safely, without
    /// crashing or duplicating an item, to the first item in side
    /// order when no item carries side 0 (for example, legacy or
    /// corrupted data). Never returns the same item as `itemB`.
    var itemA: ComparedItem? {
        if let a = items.first(where: { $0.side == 0 }) { return a }
        return sortedItems.first
    }

    /// Side B: the item whose side is 1, if it is not already itemA.
    /// Otherwise the first item in side order that is not itemA.
    /// Returns nil when fewer than two distinct items exist.
    var itemB: ComparedItem? {
        if let b = items.first(where: { $0.side == 1 }), b.id != itemA?.id { return b }
        return sortedItems.first(where: { $0.id != itemA?.id })
    }

    var totalPros: Int {
        items.flatMap { $0.entries }.filter { $0.isPro }.count
    }

    var totalCons: Int {
        items.flatMap { $0.entries }.filter { !$0.isPro }.count
    }

    var displayTitle: String {
        if !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return title
        }
        let names = sortedItems.map { $0.name }.filter { !$0.isEmpty }
        if names.isEmpty { return "Untitled comparison" }
        return names.joined(separator: " vs ")
    }

    func touch() {
        updatedAt = Date()
    }

    // MARK: - Store methods (the only way views mutate a comparison)

    /// Every mutation below goes through one of these methods so that
    /// `updatedAt` is touched on every change. Views must never mutate
    /// `items`, `entries`, `name`, `verdict`, `text`, or `isPro`
    /// directly. Methods that take text trim it and reject blank or
    /// whitespace-only values, returning false (or nil) without touching.

    private func owns(_ item: ComparedItem) -> Bool {
        items.contains(where: { $0.id == item.id })
    }

    private func owns(_ entry: ProConEntry) -> Bool {
        guard let item = entry.item else { return false }
        return owns(item) && item.entries.contains(where: { $0.id == entry.id })
    }

    private static func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Rename an item. Returns false and changes nothing when the new
    /// name is blank or whitespace-only, or the item is not part of
    /// this comparison. Callers should revert any draft text on false.
    @discardableResult
    func renameItem(_ item: ComparedItem, to newName: String) -> Bool {
        let trimmed = Self.trimmed(newName)
        guard !trimmed.isEmpty, owns(item) else { return false }
        item.name = trimmed
        touch()
        return true
    }

    /// Append a pro or con entry to an item. Returns nil and changes
    /// nothing when the text is blank or the item is not part of this
    /// comparison. The caller still inserts the returned entry into
    /// the model context; this method only owns the in-memory link
    /// and the timestamp.
    @discardableResult
    func addEntry(to item: ComparedItem, text: String, isPro: Bool) -> ProConEntry? {
        let trimmed = Self.trimmed(text)
        guard !trimmed.isEmpty, owns(item) else { return nil }
        let nextOrder = (item.entries.map { $0.sortOrder }.max() ?? -1) + 1
        let entry = ProConEntry(text: trimmed, isPro: isPro, sortOrder: nextOrder, item: item)
        item.entries.append(entry)
        touch()
        return entry
    }

    /// Flip a pro to a con or a con to a pro. No-op for foreign entries.
    func toggleProCon(_ entry: ProConEntry) {
        guard owns(entry) else { return }
        entry.isPro.toggle()
        touch()
    }

    /// Set an entry's pro/con side explicitly. No-op for foreign entries.
    func setEntryIsPro(_ entry: ProConEntry, isPro: Bool) {
        guard owns(entry) else { return }
        entry.isPro = isPro
        touch()
    }

    /// Save an entry's text and side together (used by the edit sheet),
    /// touching only once. Returns false and changes nothing when the
    /// text is blank or whitespace-only, or the entry is foreign.
    @discardableResult
    func saveEntry(_ entry: ProConEntry, text: String, isPro: Bool) -> Bool {
        let trimmed = Self.trimmed(text)
        guard !trimmed.isEmpty, owns(entry) else { return false }
        entry.text = trimmed
        entry.isPro = isPro
        touch()
        return true
    }

    /// Remove an entry from its item's list and touch. The caller still
    /// deletes the entry from the model context; this method only owns
    /// the in-memory unlink and the timestamp.
    func deleteEntry(_ entry: ProConEntry) {
        guard let item = entry.item, owns(entry) else { return }
        item.entries.removeAll { $0.id == entry.id }
        touch()
    }

    /// Save the free-text verdict. A blank verdict is allowed (it just
    /// clears the note); it still counts as a mutation, so it touches.
    func saveVerdict(_ text: String) {
        verdict = text
        touch()
    }

    // MARK: - Search (in-memory only, never a relationship predicate)

    /// Case- and diacritic-insensitive match over the display title
    /// plus both item names. ListView fetches with a static sort only
    /// (`updatedAt`, descending) and filters with this method in
    /// memory, because a SwiftData predicate `contains` across the
    /// `items` relationship is unreliable. Predicates are kept only
    /// for static filters, never for this search.
    func matchesSearch(_ query: String) -> Bool {
        let needle = Self.normalized(query)
        guard !needle.isEmpty else { return true }
        let haystacks = [displayTitle] + sortedItems.map { $0.name }
        return haystacks.contains { Self.normalized($0).contains(needle) }
    }

    private static func normalized(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
