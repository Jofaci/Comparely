import SwiftUI

/// Retro-industrial theme for Compare It, in Josh's strict minimalist
/// 1980s retro-industrial, colour-blocked utility taste.
/// Paper background keeps long lists readable; ink is the main text
/// colour. Item A (teal) and Item B (burnt orange) are colour-blocked
/// so the two sides stay distinct at a glance, and every colour block
/// is paired with a text label ("A" / "B", plus / minus, Pro / Con),
/// so colour is never the only signal. This is deliberately distinct
/// from Money Manager's calm deep teal plus warm paper: sharper,
/// harder colour blocking, square corners, and grooved dividers.
///
/// Type: Eurostile is not bundled with iOS, so there is no true
/// Eurostile font to call. Display text therefore uses the system
/// sans in bold, uppercased, with wide tracking, which is the closest
/// SwiftUI allows to a Eurostile-style extended utility face without
/// shipping a font file. Do not claim a custom Eurostile font is used.
enum AppTheme {
    static let paper = Color(red: 0.96, green: 0.96, blue: 0.95)
    static let surface = Color.white
    static let ink = Color(red: 0.09, green: 0.10, blue: 0.11)
    static let muted = Color(red: 0.42, green: 0.45, blue: 0.49)
    static let itemA = Color(red: 0.06, green: 0.46, blue: 0.43)
    static let itemB = Color(red: 0.76, green: 0.25, blue: 0.05)
    static let pro = Color(red: 0.08, green: 0.50, blue: 0.24)
    static let con = Color(red: 0.72, green: 0.11, blue: 0.11)
    static let divider = Color(red: 0.88, green: 0.88, blue: 0.87)
    /// Groove pair for `GroovedDivider`: a dark line over a light line,
    /// the machined-panel effect used between Review sections.
    static let grooveDark = Color(red: 0.62, green: 0.62, blue: 0.60)
    static let grooveLight = Color.white
    /// Unselected segment / panel fill for the A/B control.
    static let panel = Color(red: 0.90, green: 0.90, blue: 0.88)

    /// Sharp corners throughout: no rounding on cards, blocks, or fields.
    static let cornerRadius: CGFloat = 0
    static let borderWidth: CGFloat = 2

    /// Eurostile-style display face as far as SwiftUI allows: bold
    /// system sans, uppercased by callers, with wide tracking.
    static let display = Font.system(size: 17, weight: .heavy, design: .default)
    static let displayTracking: CGFloat = 1.5

    /// Colour for a side: 0 is A (teal), anything else is B (burnt orange).
    static func itemColor(forSide side: Int) -> Color {
        side == 0 ? itemA : itemB
    }

    /// Colour for an item, from its side identity (never its position).
    static func itemColor(for item: ComparedItem) -> Color {
        itemColor(forSide: item.side)
    }
}

/// A machined grooved divider: a 1pt dark rule directly over a 1pt
/// light rule, with no rounding. Use between Review sections instead
/// of a plain `Divider`.
struct GroovedDivider: View {
    var body: some View {
        VStack(spacing: 0) {
            AppTheme.grooveDark.frame(height: 1)
            AppTheme.grooveLight.frame(height: 1)
        }
        .accessibilityHidden(true)
    }
}

/// A square-cornered, hard-edged card: surface fill, ink border, no rounding.
struct IndustrialCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(AppTheme.surface)
            .overlay(
                Rectangle()
                    .stroke(AppTheme.ink, lineWidth: 1)
            )
    }
}
