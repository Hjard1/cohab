import SwiftUI
import SwiftData

struct AgreementTabView: View {
    @Query private var households: [Household]
    @EnvironmentObject private var pm: PurchaseManager
    @AppStorage("agreementIntroSeen") private var introSeen = false
    @State private var showSigningSheet = false
    @State private var showContractPreview = false
    @State private var submission: DocuSealSubmission?
    @State private var isGenerating = false
    @State private var agreementError: String?
    @State private var showEmailPrompt = false
    @State private var draftEmailA = ""
    @State private var draftEmailB = ""
    @State private var isCheckingStatus = false
    @State private var lastChecked: Date? = nil
    @State private var showResetConfirm = false
    @ObservedObject private var strings = AppStrings.shared

    private var household: Household? { households.first }

    private var missingEmails: Bool {
        guard let h = household, h.isFormalMode else { return false }
        return !DocuSealService.isValidEmail(h.emailA) || !DocuSealService.isValidEmail(h.emailB)
    }

    var body: some View {
        if !pm.hasFormalAccess {
            PaywallView()
        } else {
            agreementContent
        }
    }

    private var agreementContent: some View {
        NavigationStack {
            ZStack {
                Color.cohBg.ignoresSafeArea()

                if let h = household, h.isFormalMode {
                    // Show wizard on first visit when no agreement created yet
                    if !introSeen && h.agreementStatus == "none" {
                        AgreementIntroView(household: h) {
                            introSeen = true
                        }
                    } else {
                        formalContent(h)
                    }
                } else {
                    noAgreementState
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showSigningSheet) {
            if let h = household {
                AgreementSheetView(
                    household: h,
                    submission: $submission,
                    isGenerating: $isGenerating,
                    error: $agreementError
                )
            }
        }
        .sheet(isPresented: $showEmailPrompt) {
            emailSheet
        }
        .sheet(isPresented: $showContractPreview) {
            if let h = household { ContractPreviewView(household: h) }
        }
    }

    private var emailSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text(strings.agreementAddSigningEmails)
                    .font(.title3.bold()).foregroundStyle(Color.cohInk)
                Text(strings.agreementEmailBothNeed)
                    .font(.subheadline).foregroundStyle(.secondary)

                if let h = household {
                    VStack(spacing: 14) {
                        emailField(label: "\(h.partnerAName)\(strings.agreementPartnerEmailSuffix)", text: $draftEmailA)
                        emailField(label: "\(h.partnerBName)\(strings.agreementPartnerEmailSuffix)", text: $draftEmailB)
                    }
                }

                Spacer()

                Button {
                    if let h = household {
                        h.emailA = draftEmailA.trimmingCharacters(in: .whitespaces)
                        h.emailB = draftEmailB.trimmingCharacters(in: .whitespaces)
                    }
                    showEmailPrompt = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        submission = nil
                        agreementError = nil
                        showSigningSheet = true
                    }
                } label: {
                    Text(strings.agreementSaveAndContinue)
                        .font(.headline).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(
                            canSaveEmails ? Color.cohGreen : Color.cohGreen.opacity(0.35),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                }
                .disabled(!canSaveEmails)
            }
            .padding(24)
            .background(Color.cohBg.ignoresSafeArea())
            .navigationTitle("").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(strings.cancel) { showEmailPrompt = false }
                }
            }
        }
    }

    private var canSaveEmails: Bool {
        draftEmailA.contains("@") && draftEmailB.contains("@")
    }

    private func emailField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.caption.bold()).tracking(1).foregroundStyle(Color.cohSecondary)
            TextField("email@example.com", text: text)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .font(.body)
                .padding(.horizontal, 16).padding(.vertical, 14)
                .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color(.separator).opacity(0.5), lineWidth: 1))
        }
    }

    // MARK: - Formal agreement content

    private func formalContent(_ h: Household) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Screen header
                VStack(alignment: .leading, spacing: 4) {
                    Text(strings.agreementYourAgreement)
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundStyle(Color.cohInk)
                    if h.agreementStatus == "signed", let date = h.signedAt {
                        Text(strings.agreementSignedPrefix + date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption).foregroundStyle(Color.cohGreen)
                    } else {
                        Text("\(strings.agreementBetweenPartners) \(h.partnerAName)\(strings.agreementAndConnector)\(h.partnerBName)")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Status banner
                statusBanner(h)

                // How it works — waterfall principle
                howItWorksCard

                // Clauses card
                clausesCard(h)

                // Advanced optional clauses
                advancedClausesCard(h)

                // Actions
                actionsCard(h)

                // Update notice
                if h.agreementNeedsUpdate && h.agreementStatus != "none" {
                    updateNotice(h)
                }

                Spacer(minLength: 40)
            }
            .padding(20)
        }
    }

    // MARK: - Status banner

    private func statusBanner(_ h: Household) -> some View {
        Group {
            switch h.agreementStatus {
            case "signed" where !h.agreementNeedsUpdate:
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title3).foregroundStyle(.white)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(strings.agreementSigned)
                            .font(.subheadline.bold()).foregroundStyle(.white)
                        if let date = h.signedAt {
                            Text(date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption).foregroundStyle(.white.opacity(0.75))
                        }
                    }
                    Spacer()
                }
                .padding(16)
                .background(Color.cohGreen, in: RoundedRectangle(cornerRadius: 14))

            case "pending":
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "envelope.badge.fill")
                            .font(.title3).foregroundStyle(.white)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(strings.agreementSentWaiting)
                                .font(.subheadline.bold()).foregroundStyle(.white)
                            if let checked = lastChecked {
                                Text(strings.agreementCheckedAt + checked.formatted(date: .omitted, time: .shortened))
                                    .font(.caption).foregroundStyle(.white.opacity(0.75))
                            } else {
                                Text(strings.agreementLinksSentByEmail)
                                    .font(.caption).foregroundStyle(.white.opacity(0.75))
                            }
                        }
                        Spacer()
                    }
                    Button {
                        isCheckingStatus = true
                        Task {
                            await DocuSealService.checkSigned(household: h)
                            lastChecked = Date()
                            isCheckingStatus = false
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if isCheckingStatus {
                                ProgressView().scaleEffect(0.7).tint(.orange)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.caption.bold())
                            }
                            Text(isCheckingStatus ? strings.agreementChecking : strings.agreementCheckStatus)
                                .font(.caption.bold())
                        }
                        .foregroundStyle(Color.orange)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Color.white, in: Capsule())
                    }
                    .disabled(isCheckingStatus)
                }
                .padding(16)
                .background(Color.orange, in: RoundedRectangle(cornerRadius: 14))

            default:
                HStack(spacing: 12) {
                    Image(systemName: "doc.badge.plus")
                        .font(.title3).foregroundStyle(Color.cohGreen)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(strings.agreementNoAgreement)
                            .font(.subheadline.bold()).foregroundStyle(Color.cohInk)
                        Text(strings.agreementNoAgreementSub)
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(16)
                .background(Color.cohGreen.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.cohGreen.opacity(0.25), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Agreement summary card

    private func clausesCard(_ h: Household) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(strings.agreementWhatsIn)
                .font(.subheadline.bold())
                .foregroundStyle(Color.cohInk)

            // Assets
            summaryRow(
                icon: "house.fill",
                color: Color.cohGreen,
                title: h.assets.isEmpty
                    ? strings.agreementNoAssetsYet
                    : "\(h.assets.count) \(h.assets.count == 1 ? strings.agreementSharedAsset : strings.agreementSharedAssets)",
                detail: h.assets.map { "\($0.label) — \(h.partnerAName) \(Int($0.ownershipShareA * 100))% · \(h.partnerBName) \(Int((1 - $0.ownershipShareA) * 100))%" }.joined(separator: "\n")
            )

            Divider()

            // Contributions
            let totalContribs = h.assets.reduce(0) { $0 + $1.contributions.count }
            let contribA = h.assets.flatMap { $0.contributions }.filter { $0.ownerKey == "A" }.reduce(0) { $0 + $1.amount }
            let contribB = h.assets.flatMap { $0.contributions }.filter { $0.ownerKey == "B" }.reduce(0) { $0 + $1.amount }

            summaryRow(
                icon: "banknote",
                color: Color.cohBlue,
                title: "\(totalContribs) \(totalContribs == 1 ? strings.agreementContribTracked : strings.agreementContribsTracked)",
                detail: totalContribs > 0
                    ? "\(h.partnerAName): \(h.currencySymbol)\(Int(contribA).formatted())  ·  \(h.partnerBName): \(h.currencySymbol)\(Int(contribB).formatted())"
                    : strings.agreementNoContribs
            )

            if h.includeDissolutionClause {
                Divider()
                summaryRow(
                    icon: "scale.3d",
                    color: Color(red: 0.54, green: 0.31, blue: 0.96),
                    title: strings.agreementDissolutionIncluded,
                    detail: strings.agreementDissolutionSub
                )
            }

            Divider()

            // Preview full contract text
            Button { showContractPreview = true } label: {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.subheadline).foregroundStyle(Color.cohGreen)
                    Text(strings.agreementPreviewFullContract)
                        .font(.subheadline.weight(.medium)).foregroundStyle(Color.cohGreen)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.bold()).foregroundStyle(Color.cohTertiary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func summaryRow(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.10))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.subheadline).foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.cohInk)
                if !detail.isEmpty {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func clauses(for h: Household) -> [(title: String, subtitle: String)] {
        var result = [(title: String, subtitle: String)]()
        result.append(("Property ownership", ""))
        result.append(("Financial contributions", ""))
        if h.includeDissolutionClause {
            result.append(("Dissolution terms", ""))
        }
        return result
    }

    // MARK: - Actions card

    private func actionsCard(_ h: Household) -> some View {
        VStack(spacing: 12) {
            if missingEmails {
                emailPromptCard(h)
            }

            // Primary action
            let (label, color) = primaryAction(for: h)
            Button {
                if missingEmails {
                    draftEmailA = h.emailA
                    draftEmailB = h.emailB
                    showEmailPrompt = true
                } else {
                    submission = nil
                    agreementError = nil
                    showSigningSheet = true
                }
            } label: {
                Text(label)
                    .font(.headline).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(color, in: RoundedRectangle(cornerRadius: 14))
            }

            if h.agreementStatus == "signed", !h.docusealViewUrl.isEmpty,
               let url = URL(string: h.docusealViewUrl) {
                Button { UIApplication.shared.open(url) } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.right.square")
                        Text(strings.agreementViewDownload)
                    }
                    .font(.headline).foregroundStyle(Color.cohInk)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.cohInk.opacity(0.2), lineWidth: 1.5)
                    )
                }
            }

            // Reset option when pending — lets user cancel and generate a fresh PDF
            if h.agreementStatus == "pending" {
                Button { showResetConfirm = true } label: {
                    Text(strings.agreementGenerateFresh)
                        .font(.subheadline)
                        .foregroundStyle(Color.cohSecondary)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .confirmationDialog(
                    strings.agreementCancelSigningTitle,
                    isPresented: $showResetConfirm,
                    titleVisibility: .visible
                ) {
                    Button(strings.agreementYesGenerateNew, role: .destructive) {
                        resetAgreement(h)
                    }
                } message: {
                    Text(strings.agreementCancelSigningMessage)
                }
            }
        }
    }

    private func resetAgreement(_ h: Household) {
        h.agreementStatus   = "none"
        h.docusealSlug      = ""
        h.docusealViewUrl   = ""
        submission          = nil
        agreementError      = nil
        lastChecked         = nil
    }

    private func primaryAction(for h: Household) -> (String, Color) {
        if h.agreementNeedsUpdate  { return (strings.agreementUpdate, .orange) }
        if h.agreementStatus == "pending" { return (strings.agreementViewSigning, Color.cohGreen) }
        return (strings.agreementGenerate, Color.cohGreen)
    }

    // MARK: - Update notice

    private func updateNotice(_ h: Household) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(strings.agreementNeedUpdate)
                .font(.headline).foregroundStyle(Color.cohInk)
            Text(strings.agreementNeedUpdateSub)
                .font(.subheadline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    // MARK: - Email prompt card

    private func emailPromptCard(_ h: Household) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(strings.agreementEmailsNeeded, systemImage: "envelope.badge")
                .font(.subheadline.bold()).foregroundStyle(Color.cohInk)
            Text(strings.agreementEmailsNeededSub)
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.orange.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Advanced clauses card

    private func advancedClausesCard(_ h: Household) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                h.includeAdvancedClauses.toggle()
                if !h.includeAdvancedClauses {
                    h.includeSeparatePropertyClause = false
                    h.includeBuyoutRightsClause = false
                    h.includeDisposalConsentClause = false
                    h.includeDisputeResolutionClause = false
                    h.includeDebtClause = false
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(strings.agreementAdvancedTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.cohInk)
                        Text(strings.agreementAdvancedSub)
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: h.includeAdvancedClauses ? "chevron.up" : "chevron.down")
                        .font(.caption.bold()).foregroundStyle(.secondary)
                }
                .padding(18)
            }
            .buttonStyle(.plain)

            if h.includeAdvancedClauses {
                Divider().padding(.horizontal, 18)
                VStack(spacing: 0) {
                    advancedToggle(
                        title: strings.agreementClauseSeparate,
                        subtitle: strings.agreementClauseSeparateSub,
                        isOn: Binding(get: { h.includeSeparatePropertyClause },
                                      set: { h.includeSeparatePropertyClause = $0 })
                    )
                    Divider().padding(.leading, 18)
                    advancedToggle(
                        title: strings.agreementClauseBuyout,
                        subtitle: strings.agreementClauseBuyoutSub,
                        isOn: Binding(get: { h.includeBuyoutRightsClause },
                                      set: { h.includeBuyoutRightsClause = $0 })
                    )
                    Divider().padding(.leading, 18)
                    advancedToggle(
                        title: strings.agreementClauseDisposal,
                        subtitle: strings.agreementClauseDisposalSub,
                        isOn: Binding(get: { h.includeDisposalConsentClause },
                                      set: { h.includeDisposalConsentClause = $0 })
                    )
                    Divider().padding(.leading, 18)
                    advancedToggle(
                        title: strings.agreementClauseDispute,
                        subtitle: strings.agreementClauseDisputeSub,
                        isOn: Binding(get: { h.includeDisputeResolutionClause },
                                      set: { h.includeDisputeResolutionClause = $0 })
                    )
                    Divider().padding(.leading, 18)
                    advancedToggle(
                        title: strings.agreementClauseDebt,
                        subtitle: strings.agreementClauseDebtSub,
                        isOn: Binding(get: { h.includeDebtClause },
                                      set: { h.includeDebtClause = $0 })
                    )
                }
            }
        }
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func advancedToggle(title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.cohInk)
                Text(subtitle)
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .toggleStyle(SwitchToggleStyle(tint: Color.cohGreen))
                .labelsHidden()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .buttonStyle(.plain)
    }

    // MARK: - How it works card

    private var howItWorksCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: "shield.checkered")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.cohGreen)
                Text(strings.agreementHowItWorksTitle)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.cohInk)
            }
            .padding(.horizontal, 18).padding(.top, 18).padding(.bottom, 20)

            // Flow steps with connecting line
            VStack(spacing: 0) {
                flowStep(
                    step: 1, total: 3,
                    color: Color.cohGreen,
                    icon: "arrow.up.circle.fill",
                    title: strings.agreementWaterfallStep1Title,
                    body: strings.agreementWaterfallStep1Body
                )
                flowStep(
                    step: 2, total: 3,
                    color: Color.cohBlue,
                    icon: "chart.pie.fill",
                    title: strings.agreementWaterfallStep2Title,
                    body: strings.agreementWaterfallStep2Body
                )
                flowStep(
                    step: 3, total: 3,
                    color: .orange,
                    icon: "exclamationmark.triangle.fill",
                    title: strings.agreementWaterfallStep3Title,
                    body: strings.agreementWaterfallStep3Body
                )
            }
            .padding(.bottom, 4)
        }
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func flowStep(step: Int, total: Int, color: Color,
                           icon: String, title: String, body: String) -> some View {
        let isLast = step == total
        return HStack(alignment: .top, spacing: 0) {
            // Left: circle + line
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(color)
                }
                if !isLast {
                    Rectangle()
                        .fill(LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.05)],
                            startPoint: .top, endPoint: .bottom
                        ))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 4)
                }
            }
            .frame(width: 44)
            .padding(.leading, 18)

            // Right: content
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text("\(step)")
                        .font(.caption2.bold())
                        .foregroundStyle(color)
                        .frame(width: 18, height: 18)
                        .background(color.opacity(0.12), in: Circle())
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.cohInk)
                }
                Text(body)
                    .font(.caption)
                    .foregroundStyle(Color.cohSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
            .padding(.leading, 14)
            .padding(.trailing, 18)
            .padding(.top, 10)
            .padding(.bottom, isLast ? 18 : 20)
        }
    }

    // MARK: - No agreement state

    private var noAgreementState: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Serif header
                VStack(alignment: .leading, spacing: 4) {
                    Text(strings.agreementTitle)
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundStyle(Color.cohInk)
                    Text(strings.agreementNoFormal)
                        .font(.caption).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // What this agreement protects — always visible
                howItWorksCard

                Spacer(minLength: 20)
            }
            .padding(20)
        }
    }
}
