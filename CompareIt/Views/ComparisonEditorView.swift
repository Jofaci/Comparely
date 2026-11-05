import SwiftUI
import SwiftData

/// Edit flow container: switch between Item A and Item B,
/// edit each side with the same pros and cons editor,
/// then jump to the side-by-side review.
///
/// The A/B control is custom, not a standard segmented Picker:
/// SwiftUI's segmented control cannot tint each segment with its
/// item colour, so each half is a sharp-cornered button filled with
/// its item's colour (teal for A, burnt orange for B) when selected
/// and flat panel grey when not. Each half is also labelled "A" /
/// "B" in text, so the side is never signalled by colour alone.
struct ComparisonEditorView: View {
    @Bindable var comparison: Comparison
    @State private var selectedItemIndex = 0
    @State private var showingDetail = false

    private var selectedItem: ComparedItem? {
        let items = comparison.sortedItems
        guard selectedItemIndex < items.count else { return nil }
        return items[selectedItemIndex]
    }

    var body: some View {
        VStack(spacing: 0) {
            if comparison.sortedItems.count >= 2 {
                HStack(spacing: 0) {
                    ForEach(Array(comparison.sortedItems.enumerated()), id: \.element.id) { index, item in
                        let isSelected = index == selectedItemIndex
                        Button {
                            selectedItemIndex = index
                        } label: {
                            HStack(spacing: 6) {
                                Text(item.sideLabel)
                                    .font(AppTheme.display)
                                Text(item.name.isEmpty ? "Item \(index + 1)" : item.name)
                                    .font(.subheadline)
                                    .fontWeight(isSelected ? .bold : .regular)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(isSelected ? AppTheme.itemColor(for: item) : AppTheme.panel)
                            .foregroundStyle(isSelected ? Color.white : AppTheme.ink)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Item \(item.sideLabel): \(item.name.isEmpty ? "Item \(index + 1)" : item.name)")
                        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                    }
                }
                .overlay(
                    Rectangle()
                        .stroke(AppTheme.ink, lineWidth: 1)
                )
                .padding()
            }

            if let selectedItem {
                ItemProConEditorView(item: selectedItem)
            } else {
                ContentUnavailableView("No items", systemImage: "exclamationmark.triangle")
            }
        }
        .navigationTitle(comparison.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Review") { showingDetail = true }
            }
        }
        .navigationDestination(isPresented: $showingDetail) {
            ComparisonDetailView(comparison: comparison)
        }
        .background(AppTheme.paper)
    }
}
