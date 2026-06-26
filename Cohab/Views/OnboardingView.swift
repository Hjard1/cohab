import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("onboardingComplete") private var onboardingComplete = false

    // Step 0 = intro (dark), 1 = purpose, 2 = dissolution (formal only),
    // 3 = partners, 4 = ready
    @State private var step = 0
    @State private var setupMode = "formal"
    @State private var includeDissolution = true
    @State private var nameA = ""
    @State private var nameB = ""
    @State private var emailA = ""
    @State private var emailB = ""
    @State private var selectedCountry = CohabCountry.defaults.first(where: { $0.code == "GB" }) ?? CohabCountry.defaults[0]
    @State private var disclaimerAccepted = false
    @State private var showDisclaimerSheet = false

    private var currency: String { selectedCountry.currency }

    var body: some View {
        ZStack {
            // Background transitions with step
            backgroundView

            VStack(spacing: 0) {
                if step > 0 {
                    progressBar
                        .padding(.horizontal, 32)
                        .padding(.top, 20)
                        .padding(.bottom, 4)
                }

                ZStack {
                    switch step {
                    case 0: introStep
                    case 1: purposeStep
                    case 2 where setupMode == "formal": dissolutionStep
                    case 3, 2: partnersStep   // step 2 when memory mode → same as 3
                    case 4: readyStep
                    default: EmptyView()
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
        .preferredColorScheme(step == 0 ? .dark : .light)
    }

    // MARK: - Background

    private var backgroundView: some View {
        Group {
            if step == 0 {
                Color(red: 0.04, green: 0.05, blue: 0.06)
            } else {
                Color.cohBg
            }
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.35), value: step == 0)
    }

    // MARK: - Progress bar

    private var progressBar: some View {
        let total = setupMode == "formal" ? 4 : 3   // steps 1..4 minus intro
        let current = {
            if step <= 1 { return step - 1 }
            if setupMode == "memory" { return step - 2 }  // skip dissolution
            return step - 1
        }()
        return GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.cohGreen.opacity(0.15)).frame(height: 3)
                Capsule().fill(Color.cohGreen)
                    .frame(width: max(0, g.size.width * CGFloat(current) / CGFloat(total)), height: 3)
                    .animation(.easeInOut(duration: 0.3), value: step)
            }
        }
        .frame(height: 3)
    }

    // MARK: - Step 0: Intro

    private var introStep: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 32) {
                Text("cohab")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .tracking(5)
                    .foregroundStyle(Color.cohGreen)

                VStack(spacing: 14) {
                    Text("Track ownership.\nTrust the numbers.")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)

                    Text("A shared record of what you own together\n— and what's fair if anything changes.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.55))
                        .multilineTextAlignment(.center)
                }
            }
            Spacer()
            ctaButton("Get started", enabled: true, dark: true) { advance() }
                .padding(.horizontal, 32)
                .padding(.bottom, 52)
        }
    }

    // MARK: - Step 1: Purpose

    private var purposeStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepTitle("How will you\nuse cohab?")

            VStack(spacing: 14) {
                selectionCard(
                    icon: "doc.badge.checkmark.fill",
                    color: Color.cohGreen,
                    title: "Formal ownership record",
                    body: "Register assets, track contributions, and sign a simple ownership agreement via DocuSeal.",
                    selected: setupMode == "formal"
                ) {
                    setupMode = "formal"
                    advance()
                }

                selectionCard(
                    icon: "bookmark.fill",
                    color: Color(red: 0.54, green: 0.31, blue: 0.96),
                    title: "Shared memory",
                    body: "Keep a record of assets and contributions together, without a formal document.",
                    selected: setupMode == "memory"
                ) {
                    setupMode = "memory"
                    advance()
                }
            }
            .padding(.horizontal, 28)

            Spacer()
        }
    }

    // MARK: - Step 2 (formal): Dissolution clause

    private var dissolutionStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepTitle("Add a settlement\nclause?", subtitle: "Sets out how assets are divided if the arrangement ends.")

            VStack(spacing: 14) {
                selectionCard(
                    icon: "checkmark.shield.fill",
                    color: Color.cohGreen,
                    badge: "Recommended",
                    title: "Yes — include it",
                    body: "Assets split by ownership % and tracked contributions. Mirrors the cohab settlement formula exactly.",
                    selected: includeDissolution
                ) {
                    includeDissolution = true
                    advance()
                }

                selectionCard(
                    icon: "doc.text",
                    color: Color(.systemGray),
                    title: "No — skip it",
                    body: "Agreement covers ownership and contributions only, without dissolution terms.",
                    selected: !includeDissolution
                ) {
                    includeDissolution = false
                    advance()
                }
            }
            .padding(.horizontal, 28)

            Spacer()
        }
    }

    // MARK: - Step 3: Partners

    private var partnersStep: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                stepTitle("Who is this\nbetween?")

                VStack(spacing: 16) {
                    partnerCard(
                        letter: "A", color: Color.cohGreen,
                        name: $nameA, email: $emailA,
                        namePlaceholder: "Full name", emailPlaceholder: "Email address"
                    )
                    partnerCard(
                        letter: "B", color: Color(red: 0.20, green: 0.49, blue: 0.96),
                        name: $nameB, email: $emailB,
                        namePlaceholder: "Full name", emailPlaceholder: "Email address"
                    )

                    VStack(alignment: .leading, spacing: 10) {
                        Text("COUNTRY")
                            .font(.caption.bold()).tracking(1).foregroundStyle(.secondary)
                        Picker("Country", selection: $selectedCountry) {
                            ForEach(CohabCountry.defaults) { country in
                                HStack(spacing: 8) {
                                    Text(country.flag)
                                    Text(country.name)
                                    Spacer()
                                    Text(country.currency)
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                .tag(country)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                        Text("\(selectedCountry.flag)  \(selectedCountry.currency) · rate from \(selectedCountry.bankName)")
                            .font(.caption2).foregroundStyle(Color(.tertiaryLabel))
                    }
                }
                .padding(.horizontal, 28)

                ctaButton("Continue", enabled: canAdvanceFromPartners, dark: false) { advance() }
                    .padding(.horizontal, 28)
                    .padding(.top, 28)
                    .padding(.bottom, 52)
            }
        }
    }

    private var canAdvanceFromPartners: Bool {
        let a = nameA.trimmingCharacters(in: .whitespaces)
        let b = nameB.trimmingCharacters(in: .whitespaces)
        let hasNames = !a.isEmpty && !b.isEmpty
        if setupMode == "formal" {
            return hasNames && emailA.contains("@") && emailB.contains("@")
        }
        return hasNames
    }

    // MARK: - Step 4: Ready

    private var readyStep: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                ZStack {
                    Circle()
                        .fill(Color.cohGreen.opacity(0.1))
                        .frame(width: 88, height: 88)
                    Image(systemName: "checkmark")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(Color.cohGreen)
                }

                VStack(spacing: 8) {
                    Text("You're all set.")
                        .font(.system(size: 34, weight: .bold))
                    Text(setupMode == "formal"
                         ? "Your agreement can be generated and sent for signing from the dashboard."
                         : "Start adding assets to track your ownership and contributions.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }

                summaryCard
                    .padding(.horizontal, 28)
            }

            Spacer()

            // Disclaimer acknowledgement — checkbox left, info button right
            HStack(spacing: 12) {
                // Checkbox — toggles acceptance
                Button { disclaimerAccepted.toggle() } label: {
                    HStack(spacing: 10) {
                        Image(systemName: disclaimerAccepted ? "checkmark.square.fill" : "square")
                            .font(.title3)
                            .foregroundStyle(disclaimerAccepted ? Color.cohGreen : Color(.tertiaryLabel))
                        Text("I understand — cohab provides tools, not legal advice")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .buttonStyle(.plain)

                // Info — opens full disclaimer sheet
                Button { showDisclaimerSheet = true } label: {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundStyle(Color(.tertiaryLabel))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 12)

            ctaButton("Start tracking", enabled: disclaimerAccepted, dark: false) { finish() }
                .padding(.horizontal, 28)
                .padding(.bottom, 52)
        }
        .sheet(isPresented: $showDisclaimerSheet) {
            disclaimerSheet
        }
    }

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
                            Text("Important notice").font(.headline)
                            Text("cohab · Legal notice").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Text(legalNotice)
                        .font(.subheadline).foregroundStyle(.primary).lineSpacing(3)
                    Button { disclaimerAccepted = true; showDisclaimerSheet = false } label: {
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
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Close") { showDisclaimerSheet = false } } }
        }
    }

    private var legalNotice: String {
        let lang = AppLanguage.from(country: selectedCountry.code)
        AppStrings.shared.language = lang
        return AppStrings.shared.disclaimerBody
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                partnerChip(nameA.trimmingCharacters(in: .whitespaces), color: .cohGreen)
                Image(systemName: "arrow.left.arrow.right")
                    .font(.caption2).foregroundStyle(.secondary)
                partnerChip(nameB.trimmingCharacters(in: .whitespaces),
                            color: Color(red: 0.20, green: 0.49, blue: 0.96))
                Spacer()
                Text(selectedCountry.flag + " " + selectedCountry.currency)
                    .font(.caption.bold()).foregroundStyle(.secondary)
            }

            HStack(spacing: 6) {
                Image(systemName: setupMode == "formal" ? "doc.badge.checkmark.fill" : "bookmark.fill")
                    .font(.caption)
                    .foregroundStyle(setupMode == "formal"
                                     ? Color.cohGreen
                                     : Color(red: 0.54, green: 0.31, blue: 0.96))
                Text(setupMode == "formal"
                     ? (includeDissolution ? "Formal · with dissolution clause" : "Formal · ownership only")
                     : "Shared memory")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 3)
    }

    // MARK: - Shared components

    private func stepTitle(_ text: String, subtitle: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(text)
                .font(.system(size: 34, weight: .bold))
                .lineSpacing(2)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 28)
        .padding(.top, 36)
        .padding(.bottom, 28)
    }

    private func selectionCard(
        icon: String,
        color: Color,
        badge: String? = nil,
        title: String,
        body: String,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(selected ? 0.18 : 0.09))
                        .frame(width: 48, height: 48)
                    Image(systemName: icon)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(color)
                }

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        if let badge {
                            Text(badge)
                                .font(.caption2.bold())
                                .foregroundStyle(color)
                                .padding(.horizontal, 7).padding(.vertical, 3)
                                .background(color.opacity(0.12), in: Capsule())
                        }
                    }
                    Text(body)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)

                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selected ? color : Color(.tertiaryLabel))
            }
            .padding(18)
            .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.05), radius: 12, y: 3)
            .overlay(RoundedRectangle(cornerRadius: 18)
                .strokeBorder(selected ? color.opacity(0.5) : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
    }

    private func partnerCard(
        letter: String, color: Color,
        name: Binding<String>, email: Binding<String>,
        namePlaceholder: String, emailPlaceholder: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    Circle().fill(color.opacity(0.12)).frame(width: 28, height: 28)
                    Text(letter).font(.caption.bold()).foregroundStyle(color)
                }
                Text("Partner \(letter)")
                    .font(.caption.bold()).tracking(0.5).foregroundStyle(color)
            }
            obField(placeholder: namePlaceholder, text: name, type: .name, keyboard: .default)
            obField(placeholder: emailPlaceholder + (setupMode == "formal" ? " (for signing)" : " (optional)"),
                    text: email, type: .emailAddress, keyboard: .emailAddress)
        }
        .padding(18)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func obField(placeholder: String, text: Binding<String>,
                         type: UITextContentType, keyboard: UIKeyboardType) -> some View {
        TextField(placeholder, text: text)
            .textContentType(type)
            .keyboardType(keyboard)
            .autocorrectionDisabled()
            .textInputAutocapitalization(keyboard == .emailAddress ? .never : .words)
            .font(.subheadline)
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
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

    private func ctaButton(_ label: String, enabled: Bool, dark: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.headline)
                .foregroundStyle(dark ? Color.black : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    enabled ? (dark ? Color.white : Color.cohGreen) : Color.cohGreen.opacity(0.4),
                    in: RoundedRectangle(cornerRadius: 14)
                )
        }
        .disabled(!enabled)
    }

    // MARK: - Navigation

    private func advance() {
        withAnimation(.easeInOut(duration: 0.32)) {
            switch step {
            case 1 where setupMode == "memory": step = 3   // skip dissolution
            default: step += 1
            }
        }
    }

    private func finish() {
        let h = Household(
            partnerAName: nameA.trimmingCharacters(in: .whitespaces),
            partnerBName: nameB.trimmingCharacters(in: .whitespaces),
            country: selectedCountry.code,
            currency: selectedCountry.currency,
            setupMode: setupMode,
            includeDissolutionClause: includeDissolution,
            emailA: emailA.trimmingCharacters(in: .whitespaces),
            emailB: emailB.trimmingCharacters(in: .whitespaces)
        )
        modelContext.insert(h)
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
