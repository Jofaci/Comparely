import SwiftUI

struct ProConRowView: View {
    let entry: ProConEntry

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: entry.isPro ? "plus.circle.fill" : "minus.circle.fill")
                .foregroundStyle(entry.isPro ? AppTheme.pro : AppTheme.con)
                .font(.subheadline)
            Text(entry.text)
                .font(.subheadline)
                .foregroundStyle(AppTheme.ink)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(entry.isPro ? "Pro: \(entry.text)" : "Con: \(entry.text)")
    }
}

struct ProConSectionHeaderView: View {
    let title: String
    let isPro: Bool
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isPro ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
            Text(title)
            Text("(\(count))")
                .foregroundStyle(AppTheme.muted)
            Spacer()
        }
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(isPro ? AppTheme.pro : AppTheme.con)
        .textCase(.uppercase)
    }
}
