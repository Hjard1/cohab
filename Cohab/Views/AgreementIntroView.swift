import SwiftUI

// MARK: - First-time agreement intro wizard
// Shown once when agreementStatus == "none" before the user has ever generated an agreement.

struct AgreementIntroView: View {
    let household: Household
    let onComplete: () -> Void   // called when user taps "Set up agreement"

    @ObservedObject private var strings = AppStrings.shared
    @State private var step = 1
    @State private var direction: Int = 1
    private let totalSteps = 3
    var body: some View {
        VStack(spacing: 0) {
            // Header — stays fixed
            VStack(alignment: .leading, spacing: 4) {
                Text(strings.agreementTitle)
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundStyle(Color.cohInk)
                Text("\(household.partnerAName) & \(household.partnerBName)")
                    .font(.caption).foregroundStyle(Color.cohSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)

            // Progress dots
            HStack(spacing: 8) {
                ForEach(1...totalSteps, id: \.self) { s in
                    Capsule()
                        .fill(s <= step ? Color.cohGreen : Color(.systemGray5))
                        .frame(height: 3)
                        .animation(.spring(duration: 0.3), value: step)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)

            // Step content
            Group {
                switch step {
                case 1: stepWhat
                case 2: stepClauses
                default: stepProtection
                }
            }
            .id(step)
            .transition(direction > 0
                ? .asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                              removal:   .move(edge: .leading).combined(with: .opacity))
                : .asymmetric(insertion: .move(edge: .leading).combined(with: .opacity),
                              removal:   .move(edge: .trailing).combined(with: .opacity))
            )
            .animation(.spring(duration: 0.32), value: step)

            Spacer(minLength: 0)

            // Bottom bar
            VStack(spacing: 10) {
                if step < totalSteps {
                    Button {
                        direction = 1
                        withAnimation(.spring(duration: 0.32)) { step += 1 }
                    } label: {
                        Text(strings.continueButton)
                            .font(.headline).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(Color.cohGreen, in: RoundedRectangle(cornerRadius: 14))
                    }
                } else {
                    Button(action: onComplete) {
                        Text(strings.agreementSetUp)
                            .font(.headline).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(Color.cohGreen, in: RoundedRectangle(cornerRadius: 14))
                    }
                }
                if step > 1 {
                    Button {
                        direction = -1
                        withAnimation(.spring(duration: 0.32)) { step -= 1 }
                    } label: {
                        Text(strings.back)
                            .font(.subheadline)
                            .foregroundStyle(Color.cohSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(Color.cohBg)
        }
        .background(Color.cohBg.ignoresSafeArea())
    }

    // MARK: - Step 1: What is it?

    private var stepWhat: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Hero icon
                HStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color.cohGreen.opacity(0.10))
                            .frame(width: 96, height: 96)
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.cohGreen)
                    }
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text(strings.introWhatTitle)
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundStyle(Color.cohInk)
                    Text(strings.introWhatBody)
                        .font(.subheadline)
                        .foregroundStyle(Color.cohSecondary)
                        .lineSpacing(3)
                }

                VStack(spacing: 12) {
                    introRow(icon: "checkmark.seal.fill", color: Color.cohGreen,
                             title: strings.introLegalClarity,
                             body: strings.introLegalClarityBody)
                    introRow(icon: "lock.shield.fill", color: Color.cohBlue,
                             title: strings.introProtectionRow,
                             body: strings.introProtectionBody)
                    introRow(icon: "pencil.and.list.clipboard", color: Color(red: 0.54, green: 0.31, blue: 0.96),
                             title: strings.introAlwaysCurrent,
                             body: strings.introAlwaysCurrentBody)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Step 2: What's included?

    private var stepClauses: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(strings.introWhatsIncluded)
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundStyle(Color.cohInk)
                    Text(strings.introWhatsIncludedSub)
                        .font(.subheadline)
                        .foregroundStyle(Color.cohSecondary)
                }

                VStack(spacing: 14) {
                    clauseCard(
                        number: "1",
                        icon: "house.fill",
                        color: Color.cohGreen,
                        title: strings.introSharedAssets,
                        body: strings.introSharedAssetsBody
                    )
                    clauseCard(
                        number: "2",
                        icon: "banknote.fill",
                        color: Color(red: 0.20, green: 0.49, blue: 0.96),
                        title: strings.introFinancialContribs,
                        body: strings.introFinancialContribsBody
                    )
                    if household.includeDissolutionClause {
                        clauseCard(
                            number: "3",
                            icon: "scale.3d",
                            color: Color(red: 0.54, green: 0.31, blue: 0.96),
                            title: strings.introDissolutionTerms,
                            body: strings.introDissolutionTermsBody
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Step 3: How it protects you

    private var stepProtection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(strings.introHowSettlementWorks)
                        .font(.system(size: 22, weight: .bold, design: .serif))
                        .foregroundStyle(Color.cohInk)
                    Text(strings.introHowSettlementSub)
                        .font(.subheadline)
                        .foregroundStyle(Color.cohSecondary)
                }

                VStack(spacing: 0) {
                    waterfallStep(
                        number: "①",
                        color: Color.cohGreen,
                        title: strings.agreementWaterfallStep1Title,
                        body: strings.agreementWaterfallStep1Body,
                        isLast: false
                    )
                    waterfallStep(
                        number: "②",
                        color: Color(red: 0.20, green: 0.49, blue: 0.96),
                        title: strings.agreementWaterfallStep2Title,
                        body: strings.agreementWaterfallStep2Body,
                        isLast: false
                    )
                    waterfallStep(
                        number: "③",
                        color: Color(red: 0.93, green: 0.50, blue: 0.18),
                        title: strings.agreementWaterfallStep3Title,
                        body: strings.agreementWaterfallStep3Body,
                        isLast: true
                    )
                }
                .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)

                // Signing note
                HStack(spacing: 10) {
                    Image(systemName: "signature").foregroundStyle(Color.cohGreen).font(.title3)
                    Text(strings.introSigningNote)
                        .font(.caption)
                        .foregroundStyle(Color.cohSecondary)
                }
                .padding(14)
                .background(Color.cohGreen.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Sub-views

    private func introRow(icon: String, color: Color, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.10))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.subheadline).foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(Color.cohInk)
                Text(body).font(.caption).foregroundStyle(Color.cohSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
    }

    private func clauseCard(number: String, icon: String, color: Color,
                             title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle().fill(color.opacity(0.12)).frame(width: 44, height: 44)
                Image(systemName: icon).font(.subheadline).foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(number).font(.caption2.bold()).foregroundStyle(color)
                    Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(Color.cohInk)
                }
                Text(body).font(.caption).foregroundStyle(Color.cohSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
    }

    private func waterfallStep(number: String, color: Color, title: String,
                                body: String, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Text(number)
                    .font(.title3.bold())
                    .foregroundStyle(color)
                    .frame(width: 36, height: 36)
                    .background(color.opacity(0.10), in: Circle())
                if !isLast {
                    Rectangle()
                        .fill(color.opacity(0.2))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 4)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(Color.cohInk)
                Text(body).font(.caption).foregroundStyle(Color.cohSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, isLast ? 0 : 16)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, isLast ? 16 : 0)
    }
}
