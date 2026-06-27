import SwiftUI
import SwiftData

struct AgreementTabView: View {
    @Query private var households: [Household]
    @State private var showSigningSheet = false
    @State private var submission: DocuSealSubmission?
    @State private var isGenerating = false
    @State private var agreementError: String?
    @State private var showEmailPrompt = false
    @State private var draftEmailA = ""
    @State private var draftEmailB = ""
    @State private var isCheckingStatus = false
    @State private var lastChecked: Date? = nil

    private var household: Household? { households.first }

    private var missingEmails: Bool {
        guard let h = household, h.isFormalMode else { return false }
        return !DocuSealService.isValidEmail(h.emailA) || !DocuSealService.isValidEmail(h.emailB)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cohBg.ignoresSafeArea()

                if let h = household, h.isFormalMode {
                    formalContent(h)
                } else {
                    noAgreementState
                }
            }
            .navigationTitle("Agreement")
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
    }

    private var emailSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Add signing emails")
                    .font(.title3.bold()).foregroundStyle(Color.cohInk)
                Text("Both partners need an email address to receive and sign the agreement via DocuSeal.")
                    .font(.subheadline).foregroundStyle(.secondary)

                if let h = household {
                    VStack(spacing: 14) {
                        emailField(label: "\(h.partnerAName)'s email", text: $draftEmailA)
                        emailField(label: "\(h.partnerBName)'s email", text: $draftEmailB)
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
                    Text("Save & continue")
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
                    Button("Cancel") { showEmailPrompt = false }
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
                .font(.caption.bold()).tracking(1).foregroundStyle(Color(.secondaryLabel))
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
                // Status banner
                statusBanner(h)

                // Clauses card
                clausesCard(h)

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
                        Text("Signed by both parties")
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
                            Text("Sent — waiting for signatures")
                                .font(.subheadline.bold()).foregroundStyle(.white)
                            if let checked = lastChecked {
                                Text("Checked \(checked.formatted(date: .omitted, time: .shortened))")
                                    .font(.caption).foregroundStyle(.white.opacity(0.75))
                            } else {
                                Text("Signing links sent to both parties by email")
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
                            Text(isCheckingStatus ? "Checking…" : "Check signing status")
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
                        Text("No agreement yet")
                            .font(.subheadline.bold()).foregroundStyle(Color.cohInk)
                        Text("Generate and sign your cohabitation agreement")
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
            Text("What's in your agreement")
                .font(.subheadline.bold())
                .foregroundStyle(Color.cohInk)

            // Assets
            summaryRow(
                icon: "house.fill",
                color: Color.cohGreen,
                title: h.assets.isEmpty
                    ? "No assets added yet"
                    : "\(h.assets.count) shared \(h.assets.count == 1 ? "asset" : "assets")",
                detail: h.assets.map { "\($0.label) — \(h.partnerAName) \(Int($0.ownershipShareA * 100))% · \(h.partnerBName) \(Int((1 - $0.ownershipShareA) * 100))%" }.joined(separator: "\n")
            )

            Divider()

            // Contributions
            let totalContribs = h.assets.reduce(0) { $0 + $1.contributions.count }
            let contribA = h.assets.flatMap { $0.contributions }.filter { $0.ownerKey == "A" }.reduce(0) { $0 + $1.amount }
            let contribB = h.assets.flatMap { $0.contributions }.filter { $0.ownerKey == "B" }.reduce(0) { $0 + $1.amount }

            summaryRow(
                icon: "banknote",
                color: Color(red: 0.20, green: 0.49, blue: 0.96),
                title: "\(totalContribs) contribution\(totalContribs == 1 ? "" : "s") tracked",
                detail: totalContribs > 0
                    ? "\(h.partnerAName): \(h.currencySymbol)\(Int(contribA).formatted())  ·  \(h.partnerBName): \(h.currencySymbol)\(Int(contribB).formatted())"
                    : "No contributions recorded yet"
            )

            if h.includeDissolutionClause {
                Divider()
                summaryRow(
                    icon: "scale.3d",
                    color: Color(red: 0.54, green: 0.31, blue: 0.96),
                    title: "Dissolution terms included",
                    detail: "Contributions returned first; remaining split by ownership share."
                )
            }
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
                        Text("View & download agreement")
                    }
                    .font(.headline).foregroundStyle(Color.cohInk)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.cohInk.opacity(0.2), lineWidth: 1.5)
                    )
                }
            }
        }
    }

    private func primaryAction(for h: Household) -> (String, Color) {
        if h.agreementNeedsUpdate  { return ("Update & resend agreement", .orange) }
        if h.agreementStatus == "pending" { return ("View signing links", Color.cohGreen) }
        return ("Generate & sign agreement", Color.cohGreen)
    }

    // MARK: - Update notice

    private func updateNotice(_ h: Household) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Need to update?")
                .font(.headline).foregroundStyle(Color.cohInk)
            Text("Generate a new agreement above — both parties will need to sign again.")
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
            Label("Email addresses needed for signing", systemImage: "envelope.badge")
                .font(.subheadline.bold()).foregroundStyle(Color.cohInk)
            Text("Both partners need an email to receive their signing link.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.orange.opacity(0.3), lineWidth: 1))
    }

    // MARK: - No agreement state

    private var noAgreementState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle().fill(Color.cohGreen.opacity(0.08)).frame(width: 88, height: 88)
                Image(systemName: "doc.text")
                    .font(.system(size: 38)).foregroundStyle(Color.cohGreen)
            }
            VStack(spacing: 8) {
                Text("No agreement set up")
                    .font(.title3.bold()).foregroundStyle(Color.cohInk)
                Text("You chose to track only. You can upgrade to a formal agreement any time from Settings.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
