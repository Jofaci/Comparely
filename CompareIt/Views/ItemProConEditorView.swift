import SwiftUI
import SwiftData

/// Pros and cons editor for ONE item.
/// ComparisonEditorView shows this for Item A and Item B,
/// so the same editing rules apply to both sides.
///
/// All mutations go through the parent Comparison's store methods
/// (`addEntry`, `toggleProCon`, `deleteEntry`, `renameItem`,
/// `saveEntry`), which are the only places that touch `updatedAt`.
/// Views never mutate `item.name`, `entry.text`, `entry.isPro`,
/// `item.entries`, or the comparison's verdict directly.
struct ItemProConEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var item: ComparedItem

    @State private var newText = ""
    @State private var newIsPro = true
    @State private var editingEntry: ProConEntry?
    // Rename is a draft, not a direct binding to `item.name`: it is
    // committed through `renameItem`, which trims and rejects blank
    // or whitespace-only names, reverting the draft on rejection.
    @State private var renameDraft = ""

    var body: some View {
        List {
            Section {
                TextField("Rename item", text: $renameDraft)
                    .textInputAutocapitalization(.words)
                    .onSubmit { commitRename() }
            }

            Section {
                HStack(spacing: 8) {
                    TextField("Add a pro or con", text: $newText, axis: .vertical)
                        .lineLimit(1...3)
                    Picker("Type", selection: $newIsPro) {
                        Text("Pro").tag(true)
                        Text("Con").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                    Button("Add") { addEntry() }
                        .disabled(newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            Section {
                if item.pros.isEmpty {
                    Text("No pros yet.")
                        .foregroundStyle(AppTheme.muted)
                } else {
                    ForEach(item.pros) { entry in
                        ProConRowView(entry: entry)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { deleteEntry(entry) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button { toggleEntry(entry) } label: {
                                    Label("Make con", systemImage: "arrow.left.arrow.right")
                                }
                                .tint(AppTheme.con)
                            }
                            .onTapGesture { editingEntry = entry }
                    }
                }
            } header: {
                ProConSectionHeaderView(title: "Pros", isPro: true, count: item.pros.count)
            }

            Section {
                if item.cons.isEmpty {
                    Text("No cons yet.")
                        .foregroundStyle(AppTheme.muted)
                } else {
                    ForEach(item.cons) { entry in
                        ProConRowView(entry: entry)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { deleteEntry(entry) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button { toggleEntry(entry) } label: {
                                    Label("Make pro", systemImage: "arrow.left.arrow.right")
                                }
                                .tint(AppTheme.pro)
                            }
                            .onTapGesture { editingEntry = entry }
                    }
                }
            } header: {
                ProConSectionHeaderView(title: "Cons", isPro: false, count: item.cons.count)
            }
        }
        .listStyle(.insetGrouped)
        .onAppear { renameDraft = item.name }
        .onChange(of: item.id) { _, _ in renameDraft = item.name }
        .onDisappear { commitRename() }
        .sheet(item: $editingEntry) { entry in
            EditProConEntryView(entry: entry)
        }
    }

    private func commitRename() {
        guard let comparison = item.comparison else { return }
        // No-op when nothing changed, so merely opening and leaving the
        // editor does not bump `updatedAt`. Blank / whitespace-only
        // renames are rejected by renameItem; revert the draft so the
        // field never shows an unsaved blank name. On success, re-sync
        // the draft to the stored (trimmed) name.
        guard renameDraft.trimmingCharacters(in: .whitespacesAndNewlines) != item.name else { return }
        _ = comparison.renameItem(item, to: renameDraft)
        renameDraft = item.name
    }

    private func addEntry() {
        guard let comparison = item.comparison else { return }
        guard let entry = comparison.addEntry(to: item, text: newText, isPro: newIsPro) else { return }
        modelContext.insert(entry)
        newText = ""
    }

    private func toggleEntry(_ entry: ProConEntry) {
        item.comparison?.toggleProCon(entry)
    }

    private func deleteEntry(_ entry: ProConEntry) {
        item.comparison?.deleteEntry(entry)
        modelContext.delete(entry)
    }
}

/// Small edit sheet for one existing pro or con entry.
/// Edits are drafts committed through `Comparison.saveEntry`, which
/// trims, rejects blank text, and touches `updatedAt` once. The
/// entry itself is never bound directly to the form fields.
private struct EditProConEntryView: View {
    @Environment(\.dismiss) private var dismiss
    let entry: ProConEntry

    @State private var draftText = ""
    @State private var draftIsPro = true

    var body: some View {
        NavigationStack {
            Form {
                TextField("Text", text: $draftText, axis: .vertical)
                    .lineLimit(1...5)
                Picker("Type", selection: $draftIsPro) {
                    Text("Pro").tag(true)
                    Text("Con").tag(false)
                }
                .pickerStyle(.segmented)
            }
            .navigationTitle("Edit entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { save() }
                        .disabled(draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear {
            draftText = entry.text
            draftIsPro = entry.isPro
        }
    }

    private func save() {
        guard let comparison = entry.item?.comparison else { return }
        guard comparison.saveEntry(entry, text: draftText, isPro: draftIsPro) else { return }
        dismiss()
    }
}
