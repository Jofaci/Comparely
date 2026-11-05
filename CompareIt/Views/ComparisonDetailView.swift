import SwiftUI
import SwiftData

/// Final read-only review: two items side by side, each with
/// its pros and cons, plus an optional verdict note.
/// On a narrow phone the two columns share the width; a Stacked
/// mode is offered for longer entries.
///
/// The verdict is a draft, not a direct binding to
/// `comparison.verdict`: every keystroke is committed through
/// `Comparison.saveVerdict`, which is the only place that writes
/// the verdict and touches `updatedAt`. No score here is a winner:
/// each column shows its tally explicitly as "Tally (unweighted)".
struct ComparisonDetailView: View {
    @Bindable var comparison: Comparison
    @State private var viewMode: ViewMode = .sideBySide
    @State private var showingEditor = false
    @State private var verdictDraft = ""

    enum ViewMode: String, CaseIterable {
        case sideBySide = "Side by side"
        case stacked = "Stacked"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Picker("Layout", selection: $viewMode) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if viewMode == .sideBySide {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(comparison.sortedItems) { item in
                            ItemColumnView(item: item)
                                .frame(maxWidth: .infinity, alignment: .top)
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        ForEach(comparison.sortedItems) { item in
                            ItemColumnView(item: item)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }

                GroovedDivider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Verdict")
                        .font(AppTheme.display)
                        .tracking(AppTheme.displayTracking)
                        .textCase(.uppercase)
                    TextEditor(text: $verdictDraft)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(AppTheme.surface)
                        .overlay(
                            Rectangle()
                                .stroke(AppTheme.ink, lineWidth: 1)
                        )
                    Text("Tally (unweighted): counts only. Your verdict is what you decide, not an automatic winner.")
                        .font(.caption)
                        .foregroundStyle(AppTheme.muted)
                }
            }
            .padding()
        }
        .background(AppTheme.paper)
        .navigationTitle(comparison.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { verdictDraft = comparison.verdict }
        .onChange(of: verdictDraft) { _, newValue in
            // Guard against the onAppear sync itself counting as an edit:
            // opening Review must not bump `updatedAt`.
            guard newValue != comparison.verdict else { return }
            comparison.saveVerdict(newValue)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showingEditor = true }
            }
        }
        .navigationDestination(isPresented: $showingEditor) {
            ComparisonEditorView(comparison: comparison)
        }
    }
}

/// One Review column. The header is a hard colour block in the
/// item's colour (teal for A, burnt orange for B), with the side
/// letter and name in text, so the side is never colour alone.
/// Corners are sharp throughout; sections are split by a grooved
/// divider rather than a plain rule.
private struct ItemColumnView: View {
    let item: ComparedItem

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Colour-blocked header: side letter + name + counts + tally.
            VStack(alignment: .leading, spacing: 4) {
                Text("Item \(item.sideLabel): \(item.name)")
                    .font(AppTheme.display)
                    .tracking(AppTheme.displayTracking)
                    .textCase(.uppercase)
                    .lineLimit(2)
                Text("\(item.pros.count) pros · \(item.cons.count) cons")
                    .font(.caption)
                // Explicit unweighted tally label (never "Score" alone,
                // never an automatic winner).
                Text("Tally (unweighted): \(item.signedScore)")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(AppTheme.itemColor(for: item))

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    ProConSectionHeaderView(title: "Pros", isPro: true, count: item.pros.count)
                    if item.pros.isEmpty {
                        Text("No pros yet.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.muted)
                    } else {
                        ForEach(item.pros) { entry in
                            ProConRowView(entry: entry)
                        }
                    }
                }

                GroovedDivider()

                VStack(alignment: .leading, spacing: 8) {
                    ProConSectionHeaderView(title: "Cons", isPro: false, count: item.cons.count)
                    if item.cons.isEmpty {
                        Text("No cons yet.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.muted)
                    } else {
                        ForEach(item.cons) { entry in
                            ProConRowView(entry: entry)
                        }
                    }
                }
            }
            .padding(12)
        }
        .background(AppTheme.surface)
        .overlay(
            Rectangle()
                .stroke(AppTheme.ink, lineWidth: 1)
        )
    }
}

#Preview {
    ComparisonDetailView(comparison: PreviewData.sampleComparison)
        .modelContainer(PreviewData.inMemoryContainer)
}
