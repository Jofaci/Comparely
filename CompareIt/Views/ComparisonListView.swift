import SwiftUI
import SwiftData

/// Home screen: saved comparisons, most recently updated first.
struct ComparisonListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Comparison.updatedAt, order: .reverse) private var comparisons: [Comparison]
    @State private var showingCreate = false
    @State private var searchText = ""

    // In-memory, normalized (case- and diacritic-insensitive) filtering
    // over displayTitle plus item names. The @Query above carries only
    // a static sort (updatedAt, descending); no predicate `contains`
    // is run across the items relationship. See Comparison.matchesSearch.
    private var filteredComparisons: [Comparison] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return comparisons }
        return comparisons.filter { $0.matchesSearch(query) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredComparisons.isEmpty {
                    ContentUnavailableView {
                        Label("No comparisons yet", systemImage: "rectangle.split.2x1")
                    } description: {
                        Text("Compare two objects or ideas, add pros and cons for each, then review them side by side.")
                    } actions: {
                        Button("Create a comparison") { showingCreate = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(filteredComparisons) { comparison in
                            NavigationLink(destination: ComparisonDetailView(comparison: comparison)) {
                                ComparisonRowView(comparison: comparison)
                            }
                        }
                        .onDelete(perform: deleteComparisons)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Compare It")
            .searchable(text: $searchText, prompt: "Search comparisons")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingCreate = true }) {
                        Label("New comparison", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreate) {
                CreateComparisonView()
            }
        }
    }

    private func deleteComparisons(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredComparisons[index])
        }
    }
}

private struct ComparisonRowView: View {
    let comparison: Comparison

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(comparison.displayTitle)
                .font(.headline)
                .foregroundStyle(AppTheme.ink)
            HStack(spacing: 12) {
                if let itemA = comparison.itemA {
                    Label("\(itemA.pros.count) pros, \(itemA.cons.count) cons", systemImage: "square.split.2x1")
                        .foregroundStyle(AppTheme.itemA)
                }
                if let itemB = comparison.itemB {
                    Label("\(itemB.pros.count) pros, \(itemB.cons.count) cons", systemImage: "square.split.2x1")
                        .foregroundStyle(AppTheme.itemB)
                }
                Spacer()
                Text(comparison.updatedAt, style: .date)
                    .foregroundStyle(AppTheme.muted)
            }
            .font(.caption)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ComparisonListView()
        .modelContainer(PreviewData.inMemoryContainer)
}
