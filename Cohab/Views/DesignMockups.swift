import SwiftUI

// MARK: - Preview host (not linked into app target, preview only)

struct DesignPreviewHost: View {
    @State private var selected = 0
    var body: some View {
        TabView(selection: $selected) {
            DirectionA_PremiumDark().tag(0)
            DirectionB_BoldSplit().tag(1)
            DirectionC_WarmEditorial().tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
    }
}

// ─────────────────────────────────────────────────────────────
// DIRECTION A  ·  Premium Dark
// Deep near-black, luminous payout numbers, glow accents
// ─────────────────────────────────────────────────────────────

struct DirectionA_PremiumDark: View {
    private let bg      = Color(red: 0.053, green: 0.063, blue: 0.082)
    private let card    = Color(red: 0.078, green: 0.094, blue: 0.122)
    private let green   = Color(red: 0.10,  green: 0.68,  blue: 0.45)
    private let blue    = Color(red: 0.20,  green: 0.49,  blue: 0.96)

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // ── Header ──────────────────────────────────
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("COHAB")
                                .font(.system(.caption2, design: .rounded).weight(.black))
                                .tracking(5)
                                .foregroundStyle(green)
                            Text("Alex & Sophie")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("NET EQUITY")
                                .font(.system(.caption2, design: .rounded).weight(.semibold))
                                .tracking(1.5)
                                .foregroundStyle(.white.opacity(0.35))
                            Text("£141,000")
                                .font(.system(size: 20, weight: .bold, design: .rounded).monospacedDigit())
                                .foregroundStyle(.white)
                        }
                    }

                    // ── Asset card ───────────────────────────────
                    VStack(spacing: 0) {
                        // Card top bar
                        HStack {
                            HStack(spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(green.opacity(0.15))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "house.fill")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(green)
                                }
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Our home")
                                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                        .foregroundStyle(.white)
                                    Text("£450,000 current value")
                                        .font(.system(.caption2))
                                        .foregroundStyle(.white.opacity(0.35))
                                }
                            }
                            Spacer()
                            Text("IF SOLD TODAY")
                                .font(.system(.caption2, design: .rounded).weight(.semibold))
                                .tracking(1)
                                .foregroundStyle(.white.opacity(0.25))
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 16)

                        // Ownership bar
                        GeometryReader { g in
                            HStack(spacing: 0) {
                                LinearGradient(
                                    colors: [green, green.opacity(0.65)],
                                    startPoint: .leading, endPoint: .trailing
                                )
                                .frame(width: g.size.width * 0.618)
                                LinearGradient(
                                    colors: [blue.opacity(0.65), blue],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            }
                        }
                        .frame(height: 2)

                        // Payout numbers
                        HStack(alignment: .bottom, spacing: 0) {
                            // Alex
                            VStack(alignment: .leading, spacing: 6) {
                                Text("ALEX")
                                    .font(.system(.caption2, design: .rounded).weight(.black))
                                    .tracking(3)
                                    .foregroundStyle(green.opacity(0.7))
                                Text("£87,057")
                                    .font(.system(size: 46, weight: .black, design: .rounded).monospacedDigit())
                                    .foregroundStyle(.white)
                                    .shadow(color: green.opacity(0.55), radius: 22, x: 0, y: 0)
                                Text("62%")
                                    .font(.system(.caption, design: .rounded).weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.25))
                            }
                            Spacer()
                            // Sophie
                            VStack(alignment: .trailing, spacing: 6) {
                                Text("SOPHIE")
                                    .font(.system(.caption2, design: .rounded).weight(.black))
                                    .tracking(3)
                                    .foregroundStyle(blue.opacity(0.7))
                                Text("£53,942")
                                    .font(.system(size: 46, weight: .black, design: .rounded).monospacedDigit())
                                    .foregroundStyle(.white)
                                    .shadow(color: blue.opacity(0.55), radius: 22, x: 0, y: 0)
                                Text("38%")
                                    .font(.system(.caption, design: .rounded).weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.25))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 24)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [.white.opacity(0.09), .clear, .white.opacity(0.04)],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 0.8
                                    )
                            )
                    )
                    .shadow(color: .black.opacity(0.45), radius: 28, y: 12)

                    // Direction label
                    directionLabel("A", "Premium Dark")
                }
                .padding(24)
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────
// DIRECTION B  ·  Bold Split
// Two-column card, bold identity, maximum contrast
// ─────────────────────────────────────────────────────────────

struct DirectionB_BoldSplit: View {
    private let green = Color(red: 0.06, green: 0.62, blue: 0.40)
    private let blue  = Color(red: 0.18, green: 0.44, blue: 0.94)
    private let ink   = Color(red: 0.08, green: 0.08, blue: 0.10)

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // ── Header ──────────────────────────────────
                    VStack(alignment: .leading, spacing: 10) {
                        Text("cohab")
                            .font(.system(.subheadline, design: .rounded).weight(.black))
                            .tracking(3)
                            .foregroundStyle(green)
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            Text("Alex")
                                .font(.system(size: 38, weight: .black))
                                .foregroundStyle(green)
                            Text(" / ")
                                .font(.system(size: 38, weight: .thin))
                                .foregroundStyle(ink.opacity(0.2))
                            Text("Sophie")
                                .font(.system(size: 38, weight: .black))
                                .foregroundStyle(blue)
                        }
                    }

                    // ── Asset card ───────────────────────────────
                    VStack(spacing: 0) {
                        // Neutral header
                        HStack {
                            Label("Our home", systemImage: "house.fill")
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .foregroundStyle(ink)
                            Spacer()
                            VStack(alignment: .trailing, spacing: 1) {
                                Text("£450,000")
                                    .font(.system(.subheadline, design: .rounded).weight(.bold).monospacedDigit())
                                    .foregroundStyle(ink)
                                Text("IF SOLD TODAY")
                                    .font(.system(.caption2).weight(.semibold))
                                    .tracking(1)
                                    .foregroundStyle(ink.opacity(0.35))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)

                        // THE SPLIT
                        HStack(spacing: 0) {
                            // Alex side
                            VStack(spacing: 10) {
                                Text("ALEX")
                                    .font(.system(.caption, design: .rounded).weight(.black))
                                    .tracking(4)
                                    .foregroundStyle(green)
                                Text("£87,057")
                                    .font(.system(size: 36, weight: .black, design: .rounded).monospacedDigit())
                                    .foregroundStyle(ink)
                                    .minimumScaleFactor(0.65)
                                Text("62%")
                                    .font(.system(size: 52, weight: .black, design: .rounded))
                                    .foregroundStyle(green.opacity(0.12))
                                    .overlay(
                                        Text("62%")
                                            .font(.system(size: 52, weight: .black, design: .rounded))
                                            .foregroundStyle(green)
                                    )
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 28)
                            .background(green.opacity(0.05))

                            // Divider — the bold split line
                            Rectangle()
                                .fill(ink)
                                .frame(width: 2)

                            // Sophie side
                            VStack(spacing: 10) {
                                Text("SOPHIE")
                                    .font(.system(.caption, design: .rounded).weight(.black))
                                    .tracking(4)
                                    .foregroundStyle(blue)
                                Text("£53,942")
                                    .font(.system(size: 36, weight: .black, design: .rounded).monospacedDigit())
                                    .foregroundStyle(ink)
                                    .minimumScaleFactor(0.65)
                                Text("38%")
                                    .font(.system(size: 52, weight: .black, design: .rounded))
                                    .foregroundStyle(blue.opacity(0.12))
                                    .overlay(
                                        Text("38%")
                                            .font(.system(size: 52, weight: .black, design: .rounded))
                                            .foregroundStyle(blue)
                                    )
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 28)
                            .background(blue.opacity(0.05))
                        }

                        // Proportional split bar — thick
                        GeometryReader { g in
                            HStack(spacing: 0) {
                                Rectangle().fill(green).frame(width: g.size.width * 0.618)
                                Rectangle().fill(blue)
                            }
                        }
                        .frame(height: 5)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(ink.opacity(0.10), lineWidth: 1)
                    )
                    .shadow(color: ink.opacity(0.10), radius: 22, y: 8)

                    directionLabel("B", "Bold Split")
                }
                .padding(24)
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────
// DIRECTION C  ·  Warm Editorial
// Cream background, generous space, typography as art
// ─────────────────────────────────────────────────────────────

struct DirectionC_WarmEditorial: View {
    private let cream = Color(red: 0.982, green: 0.976, blue: 0.966)
    private let ink   = Color(red: 0.13,  green: 0.12,  blue: 0.11)
    private let green = Color(red: 0.08,  green: 0.56,  blue: 0.36)
    private let blue  = Color(red: 0.16,  green: 0.40,  blue: 0.86)

    var body: some View {
        ZStack {
            cream.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 36) {
                    // ── Header ──────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Text("cohab")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .tracking(6)
                            .foregroundStyle(green)
                        Text("Shared\nassets")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(ink)
                            .lineSpacing(-2)
                        Text("Alex & Sophie · GBP")
                            .font(.subheadline)
                            .foregroundStyle(ink.opacity(0.38))
                    }

                    // ── Asset card ───────────────────────────────
                    VStack(alignment: .leading, spacing: 0) {
                        // Asset line
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "house.fill")
                                    .font(.caption)
                                    .foregroundStyle(green.opacity(0.6))
                                Text("Our home")
                                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                                    .foregroundStyle(ink.opacity(0.55))
                            }
                            Spacer()
                            Text("£450,000")
                                .font(.system(.callout, design: .rounded).weight(.semibold).monospacedDigit())
                                .foregroundStyle(ink)
                        }
                        .padding(.horizontal, 28)
                        .padding(.top, 28)
                        .padding(.bottom, 20)

                        // Rule
                        Rectangle()
                            .fill(ink.opacity(0.07))
                            .frame(height: 1)

                        // Big editorial payout numbers
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Alex")
                                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                                    .tracking(1)
                                    .foregroundStyle(green)
                                Text("£87,057")
                                    .font(.system(size: 48, weight: .bold, design: .rounded).monospacedDigit())
                                    .foregroundStyle(ink)
                                    .minimumScaleFactor(0.6)
                                Text("62% registered ownership")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(ink.opacity(0.30))
                            }
                            .padding(.leading, 28)
                            .padding(.vertical, 28)
                            .frame(maxWidth: .infinity, alignment: .leading)

                            VStack(alignment: .trailing, spacing: 10) {
                                Text("Sophie")
                                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                                    .tracking(1)
                                    .foregroundStyle(blue)
                                Text("£53,942")
                                    .font(.system(size: 48, weight: .bold, design: .rounded).monospacedDigit())
                                    .foregroundStyle(ink)
                                    .minimumScaleFactor(0.6)
                                Text("38% registered ownership")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(ink.opacity(0.30))
                            }
                            .padding(.trailing, 28)
                            .padding(.vertical, 28)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }

                        // Refined thin bar
                        GeometryReader { g in
                            HStack(spacing: 3) {
                                Capsule().fill(green.opacity(0.55))
                                    .frame(width: g.size.width * 0.618 - 1.5)
                                Capsule().fill(blue.opacity(0.45))
                            }
                        }
                        .frame(height: 3)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 20)

                        // Footer note
                        HStack(spacing: 5) {
                            Rectangle().fill(ink.opacity(0.12)).frame(width: 20, height: 1)
                            Text("If settled today")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(ink.opacity(0.30))
                        }
                        .padding(.horizontal, 28)
                        .padding(.bottom, 24)
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: ink.opacity(0.055), radius: 28, y: 10)

                    directionLabel("C", "Warm Editorial")
                }
                .padding(24)
            }
        }
    }
}

// ─────────────────────────────────────────────────────────────
// Shared helper
// ─────────────────────────────────────────────────────────────

private func directionLabel(_ letter: String, _ name: String) -> some View {
    HStack(spacing: 6) {
        Text(letter)
            .font(.system(.caption2, design: .rounded).weight(.black))
            .foregroundStyle(.white)
            .frame(width: 18, height: 18)
            .background(Color.black.opacity(0.4), in: Circle())
        Text("Direction \(letter) · \(name)")
            .font(.caption2)
            .foregroundStyle(.secondary)
    }
}

#Preview("A – Dark")    { DirectionA_PremiumDark() }
#Preview("B – Split")   { DirectionB_BoldSplit() }
#Preview("C – Warm")    { DirectionC_WarmEditorial() }
