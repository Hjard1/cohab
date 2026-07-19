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
    @State private var isCheckingStatus = false
    @State private var lastChecked: Date? = nil
    @State private var showResetConfirm = false
    @State private var showNewVersionConfirm = false
    @State private var showPaywall = false
    @State private var advancedExpanded = false
    @State private var showHowItWorks = false
    @FocusState private var rentAmountFocused: Bool
    @ObservedObject private var strings = AppStrings.shared

    private var household: Household? { households.first }

    private var missingEmails: Bool {
        guard let h = household, h.isFormalMode else { return false }
        return !DocuSealService.isValidEmail(h.emailA) || !DocuSealService.isValidEmail(h.emailB)
    }

    var body: some View {
        agreementContent
    }

    private var agreementContent: some View {
        NavigationStack {
            ZStack {
                Color.cohBg.ignoresSafeArea()

                if let h = household, h.isFormalMode {
                    // Show wizard on first visit when no agreement created yet.
                    // Married couples skip the promotional intro — the agreement stays
                    // reachable via the neutral status card in formalContent instead.
                    if !introSeen && h.agreementStatus == "none" && h.relationshipType != "married" {
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
        .sheet(isPresented: $showContractPreview) {
            if let h = household { ContractPreviewView(household: h) }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
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
                            .font(.subheadline).foregroundStyle(Color.cohSecondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Status banner
                statusBanner(h)

                // Linear wizard: configure everything first…
                // 1. What's included (summary)
                clausesCard(h)

                // 2. Rental details — only relevant for a rental agreement
                if h.agreementType == "rental" {
                    rentalDetailsCard(h)
                }

                // 3. Advanced optional clauses
                advancedClausesCard(h)

                // …then review the assembled document…
                previewButton

                // How settlement works — collapsible (already covered in the intro)
                howItWorksDisclosure

                // …then act (send for signing / view).
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
                            _ = await DocuSealService.checkSigned(household: h)
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
                            .font(.subheadline).foregroundStyle(Color.cohSecondary)
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
        }
        .padding(18)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    // MARK: - Preview full contract (own step, after configuration)

    private var previewButton: some View {
        Button { showContractPreview = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.subheadline).foregroundStyle(Color.cohGreen)
                Text(strings.agreementPreviewFullContract)
                    .font(.subheadline.weight(.semibold)).foregroundStyle(Color.cohGreen)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.bold()).foregroundStyle(Color.cohTertiary)
            }
            .padding(18)
            .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - How it works (collapsible disclosure)

    private var howItWorksDisclosure: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.spring(duration: 0.3)) { showHowItWorks.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "shield.checkered")
                        .font(.subheadline.weight(.semibold)).foregroundStyle(Color.cohGreen)
                    Text(strings.agreementHowItWorksTitle)
                        .font(.subheadline.bold()).foregroundStyle(Color.cohInk)
                    Spacer()
                    Image(systemName: showHowItWorks ? "chevron.up" : "chevron.down")
                        .font(.caption.bold()).foregroundStyle(Color.cohSecondary)
                }
                .padding(18)
            }
            .buttonStyle(.plain)
            if showHowItWorks {
                howItWorksSteps.padding(.bottom, 4)
            }
        }
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
                        .font(.subheadline)
                        .foregroundStyle(Color.cohSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Rental details card

    private func rentalDetailsCard(_ h: Household) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(strings.agreementRentalDetailsTitle)
                .font(.subheadline.bold())
                .foregroundStyle(Color.cohInk)
            Text(strings.agreementRentalDetailsSub)
                .font(.subheadline)
                .foregroundStyle(Color.cohSecondary)

            VStack(alignment: .leading, spacing: 8) {
                Text(strings.agreementRentalWhoPays)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.cohSecondary)

                VStack(spacing: 8) {
                    rentPayerRow(h, value: "a", label: h.partnerAName)
                    rentPayerRow(h, value: "", label: strings.agreementRentalBothToLandlord)
                    rentPayerRow(h, value: "b", label: h.partnerBName)
                }
            }

            HStack {
                Text(strings.agreementRentalAmountLabel)
                    .font(.subheadline).foregroundStyle(Color.cohInk)
                Spacer()
                HStack(spacing: 4) {
                    Text(h.currencySymbol).foregroundStyle(Color.cohSecondary)
                    TextField("0", text: Binding(
                        get: { h.rentAmount > 0 ? String(Int(h.rentAmount)) : "" },
                        set: { h.rentAmount = parseExpenseAmount($0) }
                    ))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 90)
                    .focused($rentAmountFocused)
                }
            }

            Stepper(value: Binding(
                get: { h.rentPaymentDay },
                set: { h.rentPaymentDay = $0 }
            ), in: 1...28) {
                Text("\(strings.agreementRentalPaymentDayLabel) \(h.rentPaymentDay)")
                    .font(.subheadline).foregroundStyle(Color.cohInk)
            }
        }
        .padding(18)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(strings.done) { rentAmountFocused = false }
            }
        }
    }

    private func rentPayerRow(_ h: Household, value: String, label: String) -> some View {
        let isSelected = h.rentPayerKey == value
        return Button {
            h.rentPayerKey = value
        } label: {
            HStack {
                Text(label)
                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.cohInk : Color.cohSecondary)
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.cohGreen : Color(.tertiaryLabel))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(
                isSelected ? Color.cohGreen.opacity(0.08) : Color(.systemGray6),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.cohGreen.opacity(0.35) : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
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
        let isSignedFinal = h.agreementStatus == "signed" && !h.agreementNeedsUpdate

        return VStack(spacing: 12) {
            if isSignedFinal {
                // Signed & up to date: NO "generate" primary (that would silently
                // create a new submission and reset status). Offer view + an
                // explicit, confirmed "create new version" instead.
                if !h.docusealViewUrl.isEmpty, let url = URL(string: h.docusealViewUrl) {
                    Button { UIApplication.shared.open(url) } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.up.right.square")
                            Text(strings.agreementViewDownload)
                        }
                        .font(.headline).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Color.cohGreen, in: RoundedRectangle(cornerRadius: 14))
                    }
                }
                Button { showNewVersionConfirm = true } label: {
                    Text(strings.agreementCreateNewVersion)
                        .font(.subheadline)
                        .foregroundStyle(Color.cohSecondary)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .confirmationDialog(
                    strings.agreementCreateNewVersionTitle,
                    isPresented: $showNewVersionConfirm,
                    titleVisibility: .visible
                ) {
                    Button(strings.agreementCreateNewVersion, role: .destructive) {
                        resetAgreement(h)
                    }
                } message: {
                    Text(strings.agreementCreateNewVersionMessage)
                }
            } else {
                if missingEmails {
                    emailPromptCard(h)
                }

                let (label, color) = primaryAction(for: h)
                Button {
                    if !pm.hasFormalAccess {
                        showPaywall = true
                    } else {
                        // Always route through the review → confirm recipients →
                        // send sheet. Email capture lives inside that sheet now.
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

                // Reset option when pending — lets user cancel and start fresh
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
    }

    private func resetAgreement(_ h: Household) {
        h.agreementStatus   = "none"
        h.docusealSlug      = ""
        h.docusealViewUrl   = ""
        submission          = nil
        agreementError      = nil
        lastChecked         = nil
        // Also supersede any pending BankID signing case for this household.
        Task { await DealBuilderService.reset(household: h) }
    }

    private func primaryAction(for h: Household) -> (String, Color) {
        if h.agreementNeedsUpdate  { return (strings.agreementUpdate, .orange) }
        if h.agreementStatus == "pending" { return (strings.agreementViewSigning, Color.cohGreen) }
        return (strings.agreementReviewAndSend, Color.cohGreen)
    }

    // MARK: - Update notice

    private func updateNotice(_ h: Household) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(strings.agreementNeedUpdate)
                .font(.headline).foregroundStyle(Color.cohInk)
            Text(strings.agreementNeedUpdateSub)
                .font(.subheadline).foregroundStyle(Color.cohSecondary)
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
                .font(.subheadline).foregroundStyle(Color.cohSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.orange.opacity(0.3), lineWidth: 1))
    }

    // MARK: - Advanced clauses card

    private func advancedClausesCard(_ h: Household) -> some View {
        let activeCount = [h.includeSeparatePropertyClause, h.includeBuyoutRightsClause,
                           h.includeDisposalConsentClause, h.includeDisputeResolutionClause,
                           h.includeDebtClause].filter { $0 }.count
        return VStack(alignment: .leading, spacing: 0) {
            // Chevron is PURE UI expand/collapse — it never clears selections.
            // The contract generator reads each clause flag directly, so collapsing
            // the section simply hides the rows; toggled clauses stay active.
            Button {
                withAnimation(.spring(duration: 0.3)) { advancedExpanded.toggle() }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(strings.agreementAdvancedTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.cohInk)
                        Text(activeCount > 0 && !advancedExpanded
                             ? "\(activeCount) \(strings.agreementClausesSelected)"
                             : strings.agreementAdvancedSub)
                            .font(.subheadline).foregroundStyle(activeCount > 0 && !advancedExpanded ? Color.cohGreen : Color.cohSecondary)
                    }
                    Spacer()
                    Image(systemName: advancedExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.bold()).foregroundStyle(Color.cohSecondary)
                }
                .padding(18)
            }
            .buttonStyle(.plain)

            if advancedExpanded {
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
                    .font(.subheadline).foregroundStyle(Color.cohSecondary)
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

            howItWorksSteps.padding(.bottom, 4)
        }
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    // Flow steps with connecting line — shared by the card and the disclosure.
    private var howItWorksSteps: some View {
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
                    .font(.subheadline)
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
                        .font(.subheadline).foregroundStyle(Color.cohSecondary)
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
