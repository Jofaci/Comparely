import SwiftUI
import SwiftData

/// First step: name the comparison and its two items.
/// Pros and cons are added afterwards in the editor, so this screen
/// never blocks on a long list.
struct CreateComparisonView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var itemAName = ""
    @State private var itemBName = ""
    @State private var showingEditor = false
    @State private var createdComparison: Comparison?

    private var canSave: Bool {
        !itemAName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !itemBName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Comparison") {
                    TextField("Title (optional)", text: $title)
                        .textInputAutocapitalization(.words)
                    Text("Leave this blank to use \"A vs B\" from the item names.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.muted)
                }

                Section("Item A") {
                    TextField("First object or idea", text: $itemAName)
                        .textInputAutocapitalization(.words)
                }

                Section("Item B") {
                    TextField("Second object or idea", text: $itemBName)
                        .textInputAutocapitalization(.words)
                }

                Section {
                    Text("Next you will add pros and cons for each item, then review them side by side.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.muted)
                }
            }
            .navigationTitle("New comparison")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { createComparison() }
                        .disabled(!canSave)
                }
            }
            .navigationDestination(isPresented: $showingEditor) {
                if let createdComparison {
                    ComparisonEditorView(comparison: createdComparison)
                }
            }
        }
    }

    private func createComparison() {
        let comparison = Comparison(title: title.trimmingCharacters(in: .whitespacesAndNewlines))
        // Side is assigned once here, at creation, and never changed
        // afterwards. Blank / whitespace-only names are already blocked
        // by `canSave` disabling Create, and names are trimmed here, so
        // a saved item can never carry a blank name from this screen.
        let itemA = ComparedItem(
            name: itemAName.trimmingCharacters(in: .whitespacesAndNewlines),
            side: 0,
            comparison: comparison
        )
        let itemB = ComparedItem(
            name: itemBName.trimmingCharacters(in: .whitespacesAndNewlines),
            side: 1,
            comparison: comparison
        )
        comparison.items = [itemA, itemB]
        modelContext.insert(comparison)
        modelContext.insert(itemA)
        modelContext.insert(itemB)
        createdComparison = comparison
        showingEditor = true
    }
}

#Preview {
    CreateComparisonView()
        .modelContainer(PreviewData.inMemoryContainer)
}
