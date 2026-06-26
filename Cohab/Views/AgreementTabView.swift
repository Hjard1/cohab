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
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Agreement")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(Color.cohInk)
                }
            }
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
                        if !h.docusealSlug.isEmpty {
                            Text("14 Jan 2025")
                                .font(.caption).foregroundStyle(.white.opacity(0.75))
                        }
                    }
                    Spacer()
                }
                .padding(16)
                .background(Color.cohGreen, in: RoundedRectangle(cornerRadius: 14))

            case "pending":
                HStack(spacing: 12) {
                    ProgressView().tint(.white)
                    Text("Waiting for signatures…")
                        .font(.subheadline.bold()).foregroundStyle(.white)
                    Spacer()
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

    // MARK: - Clauses card

    private func clausesCard(_ h: Household) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(clauses(for: h).indices, id: \.self) { i in
                let clause = clauses(for: h)[i]
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.cohGreen.opacity(0.08))
                            .frame(width: 40, height: 40)
                        Image(systemName: "doc.text")
                            .font(.subheadline).foregroundStyle(Color.cohGreen)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(clause.title)
                            .font(.subheadline.bold()).foregroundStyle(Color.cohInk)
                        Text(clause.subtitle)
                            .font(.caption).foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.bold()).foregroundStyle(Color(.tertiaryLabel))
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 18)

                if i < clauses(for: h).count - 1 {
                    Divider().padding(.leading, 72)
                }
            }
        }
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private struct Clause {
        let title: String
        let subtitle: String
    }

    private func clauses(for h: Household) -> [Clause] {
        var result = [
            Clause(title: "Property ownership", subtitle: "Equal split of the primary residence value"),
            Clause(title: "Financial contributions", subtitle: "Monthly mortgage and bills breakdown.")
        ]
        if h.includeDissolutionClause {
            result.append(Clause(title: "Dissolution terms", subtitle: "90-day transition period if the relationship ends."))
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

            if h.agreementStatus == "signed" {
                Button {} label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.doc")
                        Text("Download PDF")
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
        if h.agreementStatus == "signed"  { return ("View full agreement", Color.cohGreen) }
        return ("Generate & sign agreement", Color.cohGreen)
    }

    // MARK: - Update notice

    private func updateNotice(_ h: Household) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Need to update?")
                .font(.headline).foregroundStyle(Color.cohInk)
            Text("Agreed terms can be amended with both parties' consent.")
                .font(.subheadline).foregroundStyle(.secondary)
            Button {} label: {
                Text("Request amendment")
                    .font(.subheadline.bold()).foregroundStyle(Color.cohInk)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(Color.cohInk.opacity(0.25), lineWidth: 1)
                    )
            }
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
