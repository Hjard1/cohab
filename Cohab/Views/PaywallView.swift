import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var pm: PurchaseManager
    @ObservedObject private var strings = AppStrings.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cohBg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 32) {
                        heroSection
                        featuresCard
                        ctaSection
                        Spacer(minLength: 40)
                    }
                    .padding(24)
                }
            }
            .navigationTitle(strings.paywallTitle)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.cohGreen.opacity(0.10))
                    .frame(width: 90, height: 90)
                Image(systemName: "doc.badge.checkmark")
                    .font(.system(size: 38))
                    .foregroundStyle(Color.cohGreen)
            }
            .padding(.top, 8)

            VStack(spacing: 8) {
                Text(strings.paywallTitle)
                    .font(.title2.bold())
                    .foregroundStyle(Color.cohInk)
                Text(strings.paywallSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Features

    private var featuresCard: some View {
        VStack(spacing: 0) {
            featureRow(icon: "doc.text.fill",
                       color: Color.cohGreen,
                       text: strings.paywallFeature1)
            Divider().padding(.leading, 54)
            featureRow(icon: "envelope.badge.fill",
                       color: Color.cohBlue,
                       text: strings.paywallFeature2)
            Divider().padding(.leading, 54)
            featureRow(icon: "arrow.triangle.2.circlepath",
                       color: Color(red: 0.54, green: 0.31, blue: 0.96),
                       text: strings.paywallFeature3)
        }
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func featureRow(icon: String, color: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.10))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(color)
            }
            .padding(.leading, 18)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.cohInk)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.trailing, 18)
        }
        .padding(.vertical, 16)
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: 14) {
            Button {
                Task { try? await pm.purchase() }
            } label: {
                HStack(spacing: 8) {
                    if pm.isLoading {
                        ProgressView().scaleEffect(0.85).tint(.white)
                    } else {
                        Text(strings.paywallCTA)
                            .font(.headline)
                        Text("— \(pm.priceDisplay)")
                            .font(.subheadline.weight(.semibold))
                            .opacity(0.85)
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(Color.cohGreen, in: RoundedRectangle(cornerRadius: 14))
            }
            .disabled(pm.isLoading)

            Button {
                Task { await pm.restore() }
            } label: {
                Text(strings.paywallRestore)
                    .font(.subheadline)
                    .foregroundStyle(Color.cohGreen)
            }
            .disabled(pm.isLoading)

            Text(strings.paywallOneTime)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(strings.paywallNote)
                .font(.caption2)
                .foregroundStyle(Color(.tertiaryLabel))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
    }
}

#Preview {
    PaywallView()
        .environmentObject(PurchaseManager())
}
