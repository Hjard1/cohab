import SwiftUI
import SwiftData
import GoogleSignIn

struct OnboardingView: View {
    private let onFinished: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(HouseholdStore.self) private var store
    @AppStorage("onboardingComplete") private var onboardingComplete = false
    @AppStorage("wasSignedOut") private var wasSignedOut = false
    @EnvironmentObject private var auth: AuthManager

    // 0=welcome, 1=country, 2=partners, 3=relationship, 4=cohab-option, 5=agreement-type, 6=add-asset, 7=ready
    @State private var step = 0
    @State private var setupMode = "formal"
    @State private var nameA = ""
    @State private var nameB = ""
    @State private var emailA = ""
    @State private var emailB = ""
    @State private var relationshipType = "partner"
    @State private var agreementType = "cohabitation"
    @State private var selectedCountry = CohabCountry.defaults.first(where: { $0.code == "GB" }) ?? CohabCountry.defaults[0]
    @State private var selectedAssetTypes: Set<AssetType> = [.home]
    @State private var disclaimerAccepted = false
    @State private var showDisclaimerSheet = false
    @State private var showDisclaimerRequiredAlert = false
    @State private var googleSignInError: String?
    @State private var finishError: String?
    @State private var isFinishing = false

    // Partner invite flow (step 2)
    @State private var inviteAnswer: String? = nil   // nil / "yes" / "later"
    @State private var showInviteQuestion = false
    @State private var showPartnerName = false
    @State private var showPartnerEmail = false
    @State private var showYourEmail = false

    private var s: AppStrings { AppStrings.shared }

    init(onFinished: @escaping () -> Void = {}) {
        self.onFinished = onFinished
    }

    var body: some View {
        ZStack {
            Color.cohBg.ignoresSafeArea()

            VStack(spacing: 0) {
                if step > 0 && step < 7 {
                    HStack(spacing: 12) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.32)) { step -= 1 }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(Color.cohInk)
                                .frame(width: 32, height: 32)
                        }
                        progressBar
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 56)
                    .padding(.bottom, 4)
                }

                ZStack {
                    switch step {
                    case 0: welcomeStep
                    case 1: countryStep
                    case 2: partnersStep
                    case 3: relationshipStep
                    case 4: cohabOptionStep
                    case 5: agreementTypeStep
                    case 6: addAssetStep
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
        .alert(s.disclaimerTitle, isPresented: $showDisclaimerRequiredAlert) {
            Button(s.ok, role: .cancel) { }
        } message: {
            Text(s.onboardingAcceptDisclaimerToContinue)
        }
        .alert(s.error, isPresented: Binding(
            get: { finishError != nil },
            set: { if !$0 { finishError = nil } }
        )) {
            Button(s.ok, role: .cancel) { finishError = nil }
        } message: {
            Text(finishError ?? "")
        }
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.cohGreen.opacity(0.15)).frame(height: 3)
                Capsule().fill(Color.cohGreen)
                    .frame(width: max(0, g.size.width * CGFloat(step - 1) / 6.0), height: 3)
                    .animation(.easeInOut(duration: 0.3), value: step)
            }
        }
        .frame(height: 3)
    }

    // MARK: - Step 0: Welcome
    // GeometryReader gives exact dimensions — avoids the layout offset bug
    // that ignoresSafeArea(edges:) causes when mixed with maxHeight:.infinity.

    private var welcomeStep: some View {
        GeometryReader { geo in
            let imageHeight = geo.size.height * 0.52 + geo.safeAreaInsets.top

            ZStack(alignment: .top) {
                Color.cohBg.ignoresSafeArea()

                // PHOTO — explicit size, bleeds under status bar
                ZStack(alignment: .bottom) {
                    LinearGradient(
                        colors: [Color(red: 0.06, green: 0.25, blue: 0.18),
                                 Color(red: 0.03, green: 0.15, blue: 0.10)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    Image("onboardingHero")
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: imageHeight)
                        .clipped()

                    // Gradient fade into cream — no hard cut
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .clear, location: 0.45),
                            .init(color: Color.cohBg.opacity(0.7), location: 0.78),
                            .init(color: Color.cohBg, location: 1.0)
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                }
                .frame(width: geo.size.width, height: imageHeight)
                .ignoresSafeArea(edges: .top)

                // TEXT + CTAs — positioned below the photo fade zone
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: imageHeight - geo.safeAreaInsets.top - 60)

                    VStack(alignment: .leading, spacing: 12) {
                        // Eyebrow
                        Text(s.onboardingEyebrow.uppercased())
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1.2)
                            .foregroundStyle(Color.cohGreen)

                        // H1
                        Text(s.onboardingHero)
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundStyle(Color.cohInk)
                            .fixedSize(horizontal: false, vertical: true)

                        // H2
                        Text(s.onboardingHeroSub)
                            .font(.subheadline)
                            .foregroundStyle(Color.cohMuted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 28)

                    Spacer()

                    VStack(spacing: 12) {
                        // Sign-in is the only way forward: the app is cloud-first
                        // (partner sync + contracts), and the old unsigned
                        // "Get started" path dead-ended at the final step where
                        // sign-in was required anyway.
                        GoogleSignInButton(label: s.onboardingContinueWithGoogle) { user in
                            if nameA.isEmpty { nameA = user.givenName }
                            if emailA.isEmpty { emailA = user.email }
                            advance()
                        } onError: { err in
                            googleSignInError = err.localizedDescription
                        }

                        AppleSignInButtonView {
                            advance()
                        } onError: { msg in
                            googleSignInError = msg
                        }

                        if let err = googleSignInError {
                            Text(err).font(.caption).foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, geo.safeAreaInsets.bottom + 28)
                }
                .frame(width: geo.size.width, height: geo.size.height + geo.safeAreaInsets.top)
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Step 1: Country

    private var countryStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepHeader(s.onboardingCountryTitle, subtitle: s.onboardingCountrySub)

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

    // MARK: - Step 2: Partners (default = add partner, subtle skip link)

    private var partnersStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                stepHeader(s.onboardingAboutYou, subtitle: s.onboardingPartnerSub)

                VStack(alignment: .leading, spacing: 16) {

                    // ── YOUR NAME ─────────────────────────────────────────
                    inputField(label: s.onboardingYourName,
                               placeholder: s.onboardingYourNamePlaceholder,
                               text: $nameA, contentType: .name)
                        .onChange(of: nameA) { _, val in
                            if !val.trimmingCharacters(in: .whitespaces).isEmpty,
                               !showPartnerName, inviteAnswer != "later" {
                                withAnimation(.spring(duration: 0.4)) {
                                    showPartnerName = true
                                }
                            }
                        }

                    // ── PARTNER'S NAME (appears automatically) ────────────
                    if showPartnerName && inviteAnswer != "later" {
                        VStack(alignment: .leading, spacing: 8) {
                            inputField(label: s.onboardingPartnerName,
                                       placeholder: s.onboardingPartnerNamePlaceholder,
                                       text: $nameB, contentType: .name)
                                .onChange(of: nameB) { _, val in
                                    if !val.trimmingCharacters(in: .whitespaces).isEmpty,
                                       !showPartnerEmail {
                                        withAnimation(.spring(duration: 0.4).delay(0.1)) {
                                            showPartnerEmail = true
                                        }
                                    }
                                }

                            // Subtle skip link — right-aligned, low contrast
                            if !showPartnerEmail {
                                Button {
                                    withAnimation(.spring(duration: 0.35)) {
                                        inviteAnswer = "later"
                                        nameB = ""; emailA = ""; emailB = ""
                                        showPartnerEmail = false
                                        showYourEmail = false
                                    }
                                } label: {
                                    Text(s.onboardingAddPartnerLater + " →")
                                        .font(.caption)
                                        .foregroundStyle(Color.cohTertiary)
                                }
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .buttonStyle(.plain)
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    // ── SKIPPED indicator (tap to undo) ───────────────────
                    if inviteAnswer == "later" {
                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                                .font(.caption2)
                                .foregroundStyle(Color.cohTertiary)
                            Text(s.onboardingAddingLater)
                                .font(.caption)
                                .foregroundStyle(Color.cohTertiary)
                            Spacer()
                            Button {
                                withAnimation(.spring(duration: 0.35)) {
                                    inviteAnswer = nil
                                    showPartnerName = true
                                }
                            } label: {
                                Text(s.onboardingChange)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.cohGreen)
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }

                    // Emails collected later at agreement creation — less friction here
                }
                .padding(.horizontal, 28)
                .animation(.spring(duration: 0.4), value: showPartnerName)
                .animation(.spring(duration: 0.4), value: inviteAnswer)

                ctaButton(s.onboardingContinue, enabled: canAdvancePartners) { advance() }
                    .padding(.horizontal, 28)
                    .padding(.top, 28)
                    .padding(.bottom, 52)
            }
        }
        .onAppear {
            // nameA can be prefilled from the sign-in profile — onChange
            // never fires for a prefilled value, so the partner field would
            // stay hidden and Continue greyed out until the user edited
            // their name. Reveal it immediately instead.
            if !nameA.trimmingCharacters(in: .whitespaces).isEmpty,
               inviteAnswer != "later", !showPartnerName {
                showPartnerName = true
            }
        }
    }

    private var canAdvancePartners: Bool {
        guard !nameA.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        if inviteAnswer == "later" { return true }         // skipped — ok
        return !nameB.trimmingCharacters(in: .whitespaces).isEmpty  // has partner name
    }

    // MARK: - Step 3: Relationship type

    private var relationshipStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepHeader(s.onboardingRelationshipTitle, subtitle: s.onboardingRelationshipSub)

            VStack(spacing: 14) {
                relationshipOption(
                    value: "partner", icon: "heart.fill", color: Color.cohGreen,
                    title: s.onboardingRelPartner, subtitle: s.onboardingRelPartnerSub)
                relationshipOption(
                    value: "friend", icon: "person.2.fill", color: Color(red: 0.20, green: 0.47, blue: 0.83),
                    title: s.onboardingRelFriend, subtitle: s.onboardingRelFriendSub)
                relationshipOption(
                    value: "married", icon: "figure.2.arms.open", color: Color(red: 0.54, green: 0.31, blue: 0.96),
                    title: s.onboardingRelMarried, subtitle: s.onboardingRelMarriedSub)
            }
            .padding(.horizontal, 28)

            Spacer()
        }
    }

    private func relationshipOption(
        value: String, icon: String, color: Color, title: String, subtitle: String
    ) -> some View {
        Button {
            relationshipType = value
            advance()
        } label: {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.10))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.title3).foregroundStyle(color)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(.headline).foregroundStyle(Color.cohInk)
                    Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: relationshipType == value ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(relationshipType == value ? color : Color(.tertiaryLabel))
            }
            .padding(18)
            .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 5: Agreement type (cohabitation vs rental)
    // Only reached when setupMode == "formal" and relationshipType != "married" —
    // see cohabOptionStep, which skips straight to addAssetStep otherwise so we
    // never ask "which agreement?" for someone who just said they don't want one.

    private var agreementTypeStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepHeader(s.onboardingAgreementTypeTitle, subtitle: s.onboardingAgreementTypeSub)

            VStack(spacing: 14) {
                agreementTypeOption(
                    value: "cohabitation", icon: "house.fill",
                    title: s.onboardingAgreementCohab, subtitle: s.onboardingAgreementCohabSub)
                agreementTypeOption(
                    value: "rental", icon: "key.fill",
                    title: s.onboardingAgreementRental, subtitle: s.onboardingAgreementRentalSub)
            }
            .padding(.horizontal, 28)

            Spacer()
        }
    }

    private func agreementTypeOption(
        value: String, icon: String, title: String, subtitle: String
    ) -> some View {
        Button {
            agreementType = value
            advance()
        } label: {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.cohGreen.opacity(0.10))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.title3).foregroundStyle(Color.cohGreen)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(.headline).foregroundStyle(Color.cohInk)
                    Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: agreementType == value ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(agreementType == value ? Color.cohGreen : Color(.tertiaryLabel))
            }
            .padding(18)
            .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 4: Cohab Option

    private var cohabOptionStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepHeader(s.onboardingProtect, subtitle: s.onboardingProtectSub)

            VStack(spacing: 14) {
                Button {
                    setupMode = "formal"
                    if relationshipType == "married" {
                        // Married users don't need the cohabitation-vs-rental
                        // question — default silently and skip straight to assets.
                        agreementType = "cohabitation"
                        withAnimation(.easeInOut(duration: 0.32)) { step = 6 }
                    } else {
                        advance()
                    }
                } label: {
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

                Button {
                    // Skipping the agreement entirely — no need to ask which
                    // agreement type they'd want, so jump straight to assets.
                    setupMode = "memory"
                    agreementType = "cohabitation"
                    withAnimation(.easeInOut(duration: 0.32)) { step = 6 }
                } label: {
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

    // MARK: - Step 6: Add Asset

    private var addAssetStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepHeader(s.onboardingWhatDoYouShare, subtitle: s.onboardingWhatSub)

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 14
            ) {
                ForEach(AssetType.allCases, id: \.self) { type in
                    let selected = selectedAssetTypes.contains(type)
                    Button {
                        if selected {
                            selectedAssetTypes.remove(type)
                        } else {
                            selectedAssetTypes.insert(type)
                        }
                    } label: {
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

            Text(s.onboardingAssetsHint)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 28)
                .padding(.top, 16)

            Spacer()

            ctaButton(s.onboardingContinue, enabled: true) {
                advance()
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 52)
        }
    }

    // MARK: - Step 7: Ready

    private var readyStep: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 32) {

                    // Wordmark
                    Text("cohab")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .tracking(5)
                        .foregroundStyle(Color.cohGreen)

                    // Hero headline
                    Text(s.onboardingReadyTitle)
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundStyle(Color.cohInk)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)

                    // Two feature points
                    VStack(alignment: .leading, spacing: 16) {
                        featureRow(icon: "arrow.up.right.circle.fill",
                                   text: s.onboardingFeatureTrack)
                        featureRow(icon: "doc.text.fill",
                                   text: s.onboardingFeatureAgreement)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.top, 32)
                .padding(.bottom, 24)
            }

            // Disclaimer — the "agree" section, prominent at the bottom
            VStack(spacing: 16) {
                // Disclaimer checkbox — large and clear
                Button { disclaimerAccepted.toggle() } label: {
                    HStack(alignment: .top, spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(
                                    disclaimerAccepted ? Color.cohGreen : Color(.systemGray4),
                                    lineWidth: 2
                                )
                                .frame(width: 24, height: 24)
                            if disclaimerAccepted {
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundStyle(Color.cohGreen)
                            }
                        }
                        .padding(.top, 1)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(s.onboardingDisclaimerAck)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(Color.cohInk)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                            Button { showDisclaimerSheet = true } label: {
                                Text(s.disclaimerReadMore)
                                    .font(.caption)
                                    .foregroundStyle(Color.cohGreen)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                    .background(
                        disclaimerAccepted
                            ? Color.cohGreen.opacity(0.06)
                            : Color(.systemGray6),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(
                                disclaimerAccepted ? Color.cohGreen.opacity(0.3) : Color.clear,
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
                .animation(.spring(duration: 0.2), value: disclaimerAccepted)

                if !auth.isSignedIn {
                    GoogleSignInButton(label: s.onboardingContinueWithGoogle) { user in
                        if nameA.isEmpty { nameA = user.givenName }
                        if emailA.isEmpty { emailA = user.email }
                    } onError: { err in
                        googleSignInError = err.localizedDescription
                    }
                    AppleSignInButtonView {
                        googleSignInError = nil
                    } onError: { msg in
                        googleSignInError = msg
                    }
                    Text(s.onboardingSignInRequiredNote)
                        .font(.caption).foregroundStyle(Color.cohMuted)
                        .multilineTextAlignment(.center)
                    if let err = googleSignInError {
                        Text(err).font(.caption).foregroundStyle(.red).multilineTextAlignment(.center)
                    }
                }

                Button {
                    guard disclaimerAccepted else {
                        showDisclaimerRequiredAlert = true
                        return
                    }
                    finish()
                } label: {
                    HStack(spacing: 10) {
                        if isFinishing { ProgressView().tint(.white) }
                        Text(s.onboardingStartTracking)
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        (disclaimerAccepted && auth.isSignedIn)
                            ? Color.cohGreen : Color.cohGreen.opacity(0.35),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                }
                .disabled(!auth.isSignedIn || isFinishing)
                .accessibilityHint(disclaimerAccepted ? "" : s.onboardingAcceptDisclaimerToContinue)
            }
            .padding(.horizontal, 28)
            .padding(.top, 16)
            .padding(.bottom, 52)
            .background(Color.cohBg)
        }
    }

    // MARK: - Shared components

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.cohGreen)
                .frame(width: 28)
            Text(text)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Color.cohInk)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

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
                            Text("cohab · \(AppStrings.shared.disclaimerTitle)").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Text(s.disclaimerBody)
                        .font(.subheadline).foregroundStyle(.primary).lineSpacing(3)
                    Button {
                        disclaimerAccepted = true
                        showDisclaimerSheet = false
                    } label: {
                        Text(s.disclaimerIUnderstand)
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
                    Button(s.disclaimerClose) { showDisclaimerSheet = false }
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
        // Sign-in is required so the household is written to Supabase and can sync
        // with the partner. The button is disabled until signed in; this is a guard.
        guard auth.isSignedIn else { return }
        guard !isFinishing else { return }

        let selectedTypes = AssetType.allCases.filter { selectedAssetTypes.contains($0) }
        isFinishing = true
        googleSignInError = nil

        Task {
            do {
                // Document the disclaimer acceptance on the profile (legal
                // trail) — before create/adopt so it is recorded either way.
                do {
                    try await SupabaseService.recordDisclaimerAcceptance(
                        version: Disclaimer.currentVersion)
                } catch {
                    print("[Cohab] Disclaimer record failed: \(error.localizedDescription)")
                }

                // Guard against duplicate households: if this user already has
                // one on the server (after a local reset, reinstall, or a
                // sign-out/in cycle), adopt it instead of creating another.
                // Duplicates orphan data — the app always shows the newest
                // household, so entries in the older ones look "gone".
                if try await SupabaseService.fetchHousehold() != nil {
                    await store.sync(modelContext: modelContext)
                    await MainActor.run {
                        isFinishing = false
                        wasSignedOut = false
                        withAnimation { onboardingComplete = true }
                        onFinished()
                    }
                    return
                }

                // 1. Create the household in Supabase FIRST so we have the canonical id.
                let householdId = try await SupabaseService.createHousehold(
                    partnerALabel: nameA.trimmingCharacters(in: .whitespaces),
                    partnerBLabel: nameB.trimmingCharacters(in: .whitespaces),
                    currency: selectedCountry.currency,
                    country: selectedCountry.code,
                    annualInterestRate: 0,
                    setupMode: setupMode,
                    relationshipType: relationshipType,
                    agreementType: agreementType,
                    emailA: emailA.trimmingCharacters(in: .whitespaces),
                    emailB: emailB.trimmingCharacters(in: .whitespaces)
                )

                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let today = dateFormatter.string(from: Date())

                var remoteAssets: [(type: AssetType, id: UUID)] = []
                for type in selectedTypes {
                    let dbAsset = try await SupabaseService.insertAsset(
                        householdId: householdId,
                        assetType: type.rawValue,
                        label: type.displayName,
                        address: "",
                        currentValue: 0,
                        remainingLoan: 0,
                        salesCostFraction: type.defaultSalesCostFraction,
                        ownershipShareA: 0.5,
                        purchaseDate: today
                    )
                    remoteAssets.append((type, dbAsset.id))
                }

                // 2. Mirror to local SwiftData using the same ids (offline source of truth).
                await MainActor.run {
                    let h = Household(
                        partnerAName: nameA.trimmingCharacters(in: .whitespaces),
                        partnerBName: nameB.trimmingCharacters(in: .whitespaces),
                        country: selectedCountry.code,
                        currency: selectedCountry.currency,
                        setupMode: setupMode,
                        includeDissolutionClause: true,
                        emailA: emailA.trimmingCharacters(in: .whitespaces),
                        emailB: emailB.trimmingCharacters(in: .whitespaces),
                        relationshipType: relationshipType,
                        agreementType: agreementType
                    )
                    h.id = householdId
                    modelContext.insert(h)
                    for pair in remoteAssets {
                        let asset = Asset(
                            assetType: pair.type.rawValue,
                            label: pair.type.displayName,
                            currentValue: 0,
                            salesCostFraction: pair.type.defaultSalesCostFraction
                        )
                        asset.id = pair.id
                        h.assets.append(asset)
                    }
                    try? modelContext.save()

                    isFinishing = false
                    wasSignedOut = false   // never get stuck on SignInView after fresh onboarding
                    withAnimation { onboardingComplete = true }
                    onFinished()
                }
            } catch {
                await MainActor.run {
                    isFinishing = false
                    finishError = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    OnboardingView()
        .modelContainer(
            for: [Household.self, Asset.self, ContributionRecord.self, SharedExpense.self],
            inMemory: true
        )
}
