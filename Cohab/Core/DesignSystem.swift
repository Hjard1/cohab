import SwiftUI

// MARK: - Design System
// Single source of truth for all visual tokens.
// Rules:
//   - 60% neutral canvas  (DS.Color.background / surface)
//   - 30% structure/chrome (DS.Color.iconSurface, borders, cards)
//   - 10% accent           (DS.Color.accent — terracotta, NOT partner green/blue)
//   - Partner A = cohGreen, Partner B = cohBlue — RESERVED for identity only

enum DS {

    // MARK: - Colors

    enum Color {

        // Accent (10%) — CTA buttons, FAB, active tab indicator.
        // Deep terracotta: warm, trust-signaling, distinct from both partner colors.
        // Contrast on white: 6.3:1 ✓ AA+   |   white on accent: 6.3:1 ✓ AA+
        static let accent       = SwiftUI.Color(red: 0.608, green: 0.243, blue: 0.125) // #9B3E20

        // Partner identity — reserved, never use on buttons or chrome.
        static let partnerA     = SwiftUI.Color(red: 0.10, green: 0.60, blue: 0.38)   // John / A (green)
        static let partnerB     = SwiftUI.Color(red: 0.20, green: 0.49, blue: 0.96)   // Sara / B (blue)

        // Canvas (60%) — backgrounds, page fills.
        static let background   = SwiftUI.Color(red: 0.980, green: 0.976, blue: 0.965)// #FAF9F6 cream
        static let surface      = SwiftUI.Color.white                                  // card surfaces

        // Structure (30%) — icon containers, borders, dividers.
        static let iconSurface  = SwiftUI.Color(red: 0.929, green: 0.910, blue: 0.882)// #EDE8E1
        static let iconContent  = SwiftUI.Color(red: 0.350, green: 0.318, blue: 0.282)// ~5.1:1 on iconSurface
        static let border       = SwiftUI.Color(red: 0.910, green: 0.898, blue: 0.882)// hairline separators

        // Text scale (all on #FAF9F6 background):
        static let text1        = SwiftUI.Color(red: 0.130, green: 0.118, blue: 0.110)// #211E1C  ~16:1 primary
        static let text2        = SwiftUI.Color(red: 0.400, green: 0.380, blue: 0.360)// #665F5B  ~5.5:1 secondary
        static let text3        = SwiftUI.Color(red: 0.580, green: 0.550, blue: 0.520)// #948C85  ~3.8:1 captions/tertiary

        // Semantic (meaning-only, never decoration).
        static let success      = SwiftUI.Color(red: 0.09, green: 0.54, blue: 0.34)   // distinct from partnerA
        static let warning      = SwiftUI.Color(red: 0.89, green: 0.54, blue: 0.08)
        static let danger       = SwiftUI.Color(red: 0.82, green: 0.22, blue: 0.18)
    }

    // MARK: - Spacing  (8-point grid: 4, 8, 12, 16, 24, 32, 48)

    enum Space {
        static let s4:  CGFloat = 4
        static let s8:  CGFloat = 8
        static let s12: CGFloat = 12
        static let s16: CGFloat = 16
        static let s24: CGFloat = 24
        static let s32: CGFloat = 32
        static let s48: CGFloat = 48
    }

    // MARK: - Corner radii

    enum Radius {
        static let sm:   CGFloat = 8
        static let md:   CGFloat = 12
        static let lg:   CGFloat = 16
        static let xl:   CGFloat = 20
        static let full: CGFloat = 9999
    }

    // MARK: - Type scale
    // Display (serif, large) → Headline → Body → BodyEmphasis → Caption.
    // All system fonts except Display. Minimum: body ≥ 17pt, caption ≥ 13pt.

    enum Text {
        /// Screen titles, hero numbers — serif only here.
        static let display         = Font.system(size: 30, weight: .bold, design: .serif)
        /// Hero number (large monospaced serif).
        static let displayMono     = Font.system(size: 32, weight: .bold, design: .serif).monospacedDigit()
        /// Section headers, card titles.
        static let headline        = Font.system(size: 17, weight: .semibold)
        /// Primary content.
        static let body            = Font.system(size: 17, weight: .regular)
        /// Inline emphasis, row labels.
        static let bodyEmphasis    = Font.system(size: 17, weight: .semibold)
        /// Secondary labels, metadata.
        static let caption         = Font.system(size: 13, weight: .regular)
        /// Weighted captions.
        static let captionEmphasis = Font.system(size: 13, weight: .semibold)
        /// Currency and percentages — monospaced.
        static let mono            = Font.system(size: 17, weight: .semibold).monospacedDigit()
        static let monoCaption     = Font.system(size: 13, weight: .medium).monospacedDigit()
        static let monoSm          = Font.system(size: 11, weight: .regular).monospacedDigit()
    }

    // MARK: - Shadows

    struct ShadowStyle {
        let color: SwiftUI.Color; let opacity: Double; let radius: CGFloat; let y: CGFloat
    }
    enum Shadow {
        /// Default card elevation — very soft, diffuse.
        static let card  = ShadowStyle(color: .black, opacity: 0.05, radius: 16, y: 3)
        /// Floating element (FAB, modal).
        static let float = ShadowStyle(color: .black, opacity: 0.14, radius: 24, y: 8)
    }
}

// MARK: - View modifiers

// Card surface — continuous rounded rect + soft shadow.
struct DSCardStyle: ViewModifier {
    var radius: CGFloat = DS.Radius.xl
    func body(content: Content) -> some View {
        let s = DS.Shadow.card
        return content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(DS.Color.surface)
                    .shadow(color: s.color.opacity(s.opacity), radius: s.radius, x: 0, y: s.y)
            )
    }
}

// Icon container — neutral square, one shape everywhere.
struct DSIconContainer: ViewModifier {
    var size: CGFloat
    var radius: CGFloat
    func body(content: Content) -> some View {
        content
            .frame(width: size, height: size)
            .background(DS.Color.iconSurface,
                        in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }
}

// Subtle press-scale on any tappable card.
struct DSPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.975 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

extension View {
    func dsCard(radius: CGFloat = DS.Radius.xl) -> some View {
        modifier(DSCardStyle(radius: radius))
    }
    func dsIcon(size: CGFloat = 44, radius: CGFloat = DS.Radius.md) -> some View {
        modifier(DSIconContainer(size: size, radius: radius))
    }
}

// MARK: - Shared components

// MARK: PartnerChip
struct PartnerChip: View {
    let name: String
    let color: SwiftUI.Color
    var showDot: Bool = true

    var body: some View {
        HStack(spacing: DS.Space.s8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(name)
                .font(DS.Text.captionEmphasis)
                .foregroundStyle(DS.Color.text1)
                .lineLimit(1)
        }
    }
}

// MARK: SplitBar
struct SplitBar: View {
    let shareA: Double          // 0–1, partner A's share
    var height: CGFloat = 6
    var showLabels: Bool = true
    var animated: Bool = true

    private var clampedA: Double { max(0, min(1, shareA)) }
    private var pctA: Int { Int((clampedA * 100).rounded()) }
    private var pctB: Int { 100 - pctA }

    var body: some View {
        HStack(spacing: DS.Space.s8) {
            if showLabels {
                Text("\(pctA)%")
                    .font(DS.Text.monoCaption)
                    .foregroundStyle(clampedA > 0.005 ? DS.Color.partnerA : DS.Color.text3)
                    .frame(width: 32, alignment: .trailing)
            }

            // Bar — outer capsule sizes itself from parent, inner uses overlay.
            // Avoids GeometryReader-in-HStack layout instability.
            Capsule()
                .fill(DS.Color.partnerB.opacity(0.20))
                .overlay(alignment: .leading) {
                    GeometryReader { geo in
                        Capsule()
                            .fill(DS.Color.partnerA)
                            .frame(width: geo.size.width * CGFloat(clampedA),
                                   height: geo.size.height)
                    }
                }
                .frame(height: height)
                .animation(animated ? .spring(response: 0.45, dampingFraction: 0.8) : nil,
                           value: clampedA)

            if showLabels {
                Text("\(pctB)%")
                    .font(DS.Text.monoCaption)
                    .foregroundStyle(clampedA < 0.995 ? DS.Color.partnerB : DS.Color.text3)
                    .frame(width: 32, alignment: .leading)
            }
        }
    }
}

// MARK: SectionHeader
struct SectionHeader: View {
    let title: String
    var detail: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(DS.Text.headline)
                .foregroundStyle(DS.Color.text1)
            Spacer()
            if let d = detail {
                Text(d)
                    .font(DS.Text.caption)
                    .foregroundStyle(DS.Color.text3)
            }
        }
    }
}

// MARK: DSFABButton
struct DSFABButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle().fill(DS.Color.accent)
                        .shadow(color: DS.Color.accent.opacity(0.40), radius: 16, y: 6)
                )
        }
        .buttonStyle(DSPressButtonStyle())
        .accessibilityLabel("Add asset")
    }
}

// MARK: DSPrimaryButton
struct DSPrimaryButton: View {
    let label: String
    var icon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Space.s8) {
                if let ic = icon { Image(systemName: ic) }
                Text(label).font(DS.Text.bodyEmphasis)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Space.s16)
            .background(DS.Color.accent,
                        in: RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous))
        }
        .buttonStyle(DSPressButtonStyle())
    }
}

// MARK: - Skeleton shimmer (loading state placeholder)
struct SkeletonView: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16
    var radius: CGFloat = DS.Radius.sm
    @State private var phase: CGFloat = 0

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(
                LinearGradient(
                    stops: [
                        .init(color: DS.Color.iconSurface, location: 0),
                        .init(color: DS.Color.border, location: phase),
                        .init(color: DS.Color.iconSurface, location: 1),
                    ],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .onAppear {
                withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
    }
}
