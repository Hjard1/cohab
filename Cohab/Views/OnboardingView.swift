import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("onboardingComplete") private var onboardingComplete = false

    // 0=welcome, 1=country, 2=partners, 3=cohab-option, 4=add-asset, 5=ready
    @State private var step = 0
    @State private var setupMode = "formal"
    @State private var nameA = ""
    @State private var nameB = ""
    @State private var emailA = ""
    @State private var emailB = ""
    @State private var relationshipType = "couple"
    @State private var selectedCountry = CohabCountry.defaults.first(where: { $0.code == "GB" }) ?? CohabCountry.defaults[0]
    @State private var selectedAssetType: AssetType? = nil
    @State private var disclaimerAccepted = false
    @State private var showDisclaimerSheet = false
    @State private var showSignIn = false
    @State private var googleSignInError: String?

    private var s: AppStrings { AppStrings.shared }

    var body: some View {
        ZStack {
            Color.cohBg.ignoresSafeArea()

            VStack(spacing: 0) {
                if step > 0 && step < 5 {
                    progressBar
                        .padding(.horizontal, 28)
                        .padding(.top, 56)
                        .padding(.bottom, 4)
                }

                ZStack {
                    switch step {
                    case 0: welcomeStep
                    case 1: countryStep
                    case 2: partnersStep
                    case 3: cohabOptionStep
                    case 4: addAssetStep
                    default: readyStep
                    }
                }
                .id(step)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal:   .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.easeInOut(duration: 0.32), value: step)
            }
        }
        .ignoresSafeArea(.keyboard)
        .preferredColorScheme(.light)
        .onChange(of: selectedCountry) { _, country in
            AppStrings.shared.language = AppLanguage.from(country: country.code)
        }
        .sheet(isPresented: $showDisclaimerSheet) { disclaimerSheet }
        .sheet(isPresented: $showSignIn) { SignInView() }
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.cohGreen.opacity(0.15)).frame(height: 3)
                Capsule().fill(Color.cohGreen)
                    .frame(width: max(0, g.size.width * CGFloat(step - 1) / 4.0), height: 3)
                    .animation(.easeInOut(duration: 0.3), value: step)
            }
        }
        .frame(height: 3)
    }

    // MARK: - Step 0: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 32) {
                Text("cohab")
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .tracking(5)
                    .foregroundStyle(Color.cohGreen)

                VStack(spacing: 14) {
                    Text(s.onboardingHero)
                        .font(.system(size: 40, weight: .bold, design: .serif))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.cohInk)
                        .lineSpacing(-2)

                    Text(s.onboardingHeroSub)
                        .font(.subheadline)
                        .foregroundStyle(Color.cohMuted)
                        .multilineTextAlignment(.center)
                }
            }
            Spacer()
            VStack(spacing: 12) {
                ctaButton(s.onboardingGetStarted, enabled: true) { advance() }

                GoogleSignInButton(label: "Continue with Google") { user in
                    if nameA.isEmpty { nameA = user.givenName }
                    if emailA.isEmpty { emailA = user.email }
                    advance()
                } onError: { err in
                    googleSignInError = err.localizedDescription
                }

                Button {
                    showSignIn = true
                } label: {
                    Text(s.onboardingAlreadyHaveAccount)
                        .font(.subheadline)
                        .foregroundStyle(Color.cohMuted)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                }

                if let err = googleSignInError {
                    Text(err)
                        .font(.caption).foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 52)
        }
    }

    // MARK: - Step 1: Country

    private var countryStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepHeader(s.onboardingWhereDoYouLive, subtitle: s.onboardingCountrySub)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(CohabCountry.defaults) { country in
                        Button {
                            selectedCountry = country
                        } label: {
                            HStack(spacing: 14) {
                                Text(country.flag).font(.title2)
                                Text(country.name)
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(Color.cohInk)
                                Spacer()
                                Image(systemName: selectedCountry.id == country.id
                                      ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(selectedCountry.id == country.id
                                                     ? Color.cohGreen : Color(.tertiaryLabel))
                            }
                            .padding(.horizontal, 18).padding(.vertical, 16)
                            .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(
                                        selectedCountry.id == country.id
                                            ? Color.cohGreen.opacity(0.5) : .clear,
                                        lineWidth: 1.5
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 16)
            }

            ctaButton(s.onboardingContinue, enabled: true) { advance() }
                .padding(.horizontal, 28)
                .padding(.bottom, 52)
        }
    }

    // MARK: - Step 2: Partners

    private var partnersStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                stepHeader(s.onboardingWhoDoYouShare, subtitle: s.onboardingPartnerSub)

                VStack(spacing: 14) {
                    inputField(label: s.onboardingYourName,
                               placeholder: "Enter your full name",
                               text: $nameA, contentType: .name)
                    inputField(label: s.onboardingPartnerName,
                               placeholder: "Enter partner's full name",
                               text: $nameB, contentType: .name)

                    if setupMode == "formal" {
                        inputField(label: s.onboardingYourEmail,
                                   placeholder: "For agreement signing",
                                   text: $emailA, contentType: .emailAddress, keyboard: .emailAddress)
                        inputField(label: s.onboardingPartnerEmail,
                                   placeholder: "For agreement signing",
                                   text: $emailB, contentType: .emailAddress, keyboard: .emailAddress)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(s.onboardingRelationship)
                            .font(.caption.bold()).tracking(1)
                            .foregroundStyle(Color(.secondaryLabel))
                        ForEach([
                            ("couple",     s.onboardingCouple),
                            ("housemates", s.onboardingHousemates),
                            ("business",   s.onboardingBusiness)
                        ], id: \.0) { type, label in
                            Button { relationshipType = type } label: {
                                HStack {
                                    Text(label)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(Color.cohInk)
                                    Spacer()
                                    Image(systemName: relationshipType == type
                                          ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundStyle(relationshipType == type
                                                         ? Color.cohGreen : Color(.tertiaryLabel))
                                }
                                .padding(.horizontal, 16).padding(.vertical, 14)
                                .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(
                                            relationshipType == type
                                                ? Color.cohGreen.opacity(0.5) : .clear,
                                            lineWidth: 1.5
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 28)

                ctaButton(s.onboardingContinue, enabled: canAdvancePartners) { advance() }
                    .padding(.horizontal, 28)
                    .padding(.top, 28)
                    .padding(.bottom, 52)
            }
        }
    }

    private var canAdvancePartners: Bool {
        !nameA.trimmingCharacters(in: .whitespaces).isEmpty &&
        !nameB.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Step 3: Cohab Option

    private var cohabOptionStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepHeader(s.onboardingProtect, subtitle: s.onboardingProtectSub)

            VStack(spacing: 14) {
                Button { setupMode = "formal"; advance() } label: {
                    HStack(alignment: .top, spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.cohGreen.opacity(0.10))
                                .frame(width: 48, height: 48)
                            Image(systemName: "doc.text.fill")
                                .font(.title3).foregroundStyle(Color.cohGreen)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text(s.onboardingYesAgreement)
                                .font(.headline).foregroundStyle(Color.cohInk)
                            Text(s.onboardingYesAgreementSub)
                                .font(.subheadline).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(18)
                    .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
                    .shadow(color: .black.opacity(0.05), radius: 12, y: 3)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(Color.cohGreen.opacity(0.35), lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)

                Button { setupMode = "memory"; advance() } label: {
                    HStack(alignment: .top, spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                                .frame(width: 48, height: 48)
                            Image(systemName: "clock")
                                .font(.title3).foregroundStyle(Color(.secondaryLabel))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(s.onboardingSkipForNow)
                                .font(.headline).foregroundStyle(Color.cohInk)
                            Text(s.onboardingSkipSub)
                                .font(.subheadline).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer()
                    }
                    .padding(18)
                    .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
                    .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                }
                .buttonStyle(.plain)

                Text(s.onboardingAgreementNote)
                    .font(.caption)
                    .foregroundStyle(Color.cohMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 28)

            Spacer()
        }
    }

    // MARK: - Step 4: Add Asset

    private var addAssetStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepHeader(s.onboardingWhatDoYouShare, subtitle: s.onboardingWhatSub)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 14
            ) {
                ForEach(AssetType.allCases, id: \.self) { type in
                    let selected = selectedAssetType == type
                    Button { selectedAssetType = selected ? nil : type } label: {
                        VStack(spacing: 12) {
                            Image(systemName: type.icon)
                                .font(.title2)
                                .foregroundStyle(selected ? .white : type.color)
                            Text(type.displayName)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(selected ? .white : Color.cohInk)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 22)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selected ? Color.cohGreen : Color.cohCard)
                        )
                        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 28)

            Spacer()

            ctaButton(selectedAssetType == nil ? s.onboardingSkipForNow : s.onboardingContinue, enabled: true) {
                advance()
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 52)
        }
    }

    // MARK: - Step 5: Ready

    private var readyStep: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    ZStack {
                        Circle().fill(Color.cohGreen.opacity(0.10)).frame(width: 88, height: 88)
                        Image(systemName: "checkmark")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(Color.cohGreen)
                    }
                    VStack(spacing: 10) {
                        Text(s.onboardingAllSet)
                            .font(.system(size: 34, weight: .bold, design: .serif))
                            .foregroundStyle(Color.cohInk)
                        Text(setupMode == "formal"
                             ? "Your agreement can be generated and signed from the Agreement tab."
                             : "Start adding assets to track your ownership and contributions.")
                            .font(.subheadline).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center).padding(.horizontal, 28)
                    }
                    summaryCard.padding(.horizontal, 28)
                }
                .padding(.top, 40)
                .padding(.bottom, 24)
            }

            // Disclaimer + CTA always visible at bottom
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button { disclaimerAccepted.toggle() } label: {
                        HStack(spacing: 10) {
                            Image(systemName: disclaimerAccepted ? "checkmark.square.fill" : "square")
                                .font(.title3)
                                .foregroundStyle(disclaimerAccepted ? Color.cohGreen : Color(.tertiaryLabel))
                            Text(s.onboardingDisclaimerAck)
                                .font(.caption).foregroundStyle(.secondary)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .buttonStyle(.plain)

                    Button { showDisclaimerSheet = true } label: {
                        Image(systemName: "info.circle")
                            .font(.caption).foregroundStyle(Color(.tertiaryLabel))
                    }
                    .buttonStyle(.plain)
                }
                ctaButton(s.onboardingStartTracking, enabled: disclaimerAccepted) { finish() }
            }
            .padding(.horizontal, 28)
            .padding(.top, 12)
            .padding(.bottom, 52)
            .background(Color.cohBg)
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                partnerChip(nameA.trimmingCharacters(in: .whitespaces), color: .cohGreen)
                Image(systemName: "arrow.left.arrow.right").font(.caption2).foregroundStyle(.secondary)
                partnerChip(nameB.trimmingCharacters(in: .whitespaces),
                            color: Color(red: 0.20, green: 0.49, blue: 0.96))
                Spacer()
                Text(selectedCountry.flag + " " + selectedCountry.currency)
                    .font(.caption.bold()).foregroundStyle(.secondary)
            }
            HStack(spacing: 6) {
                Image(systemName: setupMode == "formal" ? "checkmark.shield.fill" : "clock")
                    .font(.caption)
                    .foregroundStyle(setupMode == "formal" ? Color.cohGreen : .secondary)
                Text(setupMode == "formal"
                     ? "Formal agreement — legally binding"
                     : "Track only — no formal agreement")
                    .font(.caption.weight(.medium)).foregroundStyle(.secondary)
            }
            if let type = selectedAssetType {
                HStack(spacing: 6) {
                    Image(systemName: type.icon).font(.caption).foregroundStyle(type.color)
                    Text("Starting with: \(type.displayName)")
                        .font(.caption.weight(.medium)).foregroundStyle(.secondary)
                }
            }
        }
        .padding(18)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 3)
    }

    // MARK: - Shared components

    private func stepHeader(_ title: String, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 34, weight: .bold, design: .serif))
                .foregroundStyle(Color.cohInk)
                .lineSpacing(2)
            if let subtitle {
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 28)
        .padding(.top, 24)
        .padding(.bottom, 24)
    }

    private func inputField(
        label: String,
        placeholder: String,
        text: Binding<String>,
        contentType: UITextContentType,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption.bold()).tracking(1)
                .foregroundStyle(Color(.secondaryLabel))
            TextField(placeholder, text: text)
                .textContentType(contentType)
                .keyboardType(keyboard)
                .autocorrectionDisabled()
                .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
                .font(.body)
                .padding(.horizontal, 16).padding(.vertical, 14)
                .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color(.separator).opacity(0.5), lineWidth: 1)
                )
        }
    }

    private func ctaButton(_ label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.headline).foregroundStyle(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(
                    enabled ? Color.cohGreen : Color.cohGreen.opacity(0.35),
                    in: RoundedRectangle(cornerRadius: 14)
                )
        }
        .disabled(!enabled)
    }

    private func partnerChip(_ name: String, color: Color) -> some View {
        HStack(spacing: 6) {
            ZStack {
                Circle().fill(color.opacity(0.12)).frame(width: 24, height: 24)
                Text(String(name.prefix(1)).uppercased())
                    .font(.caption2.bold()).foregroundStyle(color)
            }
            Text(name).font(.subheadline.weight(.semibold))
        }
    }

    // MARK: - Disclaimer sheet

    private var disclaimerSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange.opacity(0.1)).frame(width: 48, height: 48)
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title3).foregroundStyle(.orange)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(s.disclaimerTitle).font(.headline)
                            Text("cohab · Legal notice").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Text(s.disclaimerBody)
                        .font(.subheadline).foregroundStyle(.primary).lineSpacing(3)
                    Button {
                        disclaimerAccepted = true
                        showDisclaimerSheet = false
                    } label: {
                        Text("I understand")
                            .font(.headline).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(Color.cohGreen, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(24)
            }
            .background(Color.cohBg.ignoresSafeArea())
            .navigationTitle("").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { showDisclaimerSheet = false }
                }
            }
        }
    }

    private var legalNotice: String {
        AppStrings.shared.disclaimerBody
    }

    // MARK: - Navigation

    private func advance() {
        withAnimation(.easeInOut(duration: 0.32)) { step += 1 }
    }

    private func finish() {
        let h = Household(
            partnerAName: nameA.trimmingCharacters(in: .whitespaces),
            partnerBName: nameB.trimmingCharacters(in: .whitespaces),
            country: selectedCountry.code,
            currency: selectedCountry.currency,
            setupMode: setupMode,
            includeDissolutionClause: true,
            emailA: emailA.trimmingCharacters(in: .whitespaces),
            emailB: emailB.trimmingCharacters(in: .whitespaces),
            relationshipType: relationshipType
        )
        modelContext.insert(h)
        if let type = selectedAssetType {
            let asset = Asset(
                assetType: type.rawValue,
                label: type.displayName,
                currentValue: 0,
                salesCostFraction: type.defaultSalesCostFraction
            )
            h.assets.append(asset)
        }
        withAnimation { onboardingComplete = true }
    }
}

#Preview {
    OnboardingView()
        .modelContainer(
            for: [Household.self, Asset.self, ContributionRecord.self, SharedExpense.self],
            inMemory: true
        )
}
