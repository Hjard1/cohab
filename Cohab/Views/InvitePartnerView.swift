import SwiftUI

struct InvitePartnerView: View {
    let household: Household

    @Environment(\.dismiss) private var dismiss
    @Environment(HouseholdStore.self) private var store
    @ObservedObject private var strings = AppStrings.shared
    @State private var token: UUID? = nil
    @State private var isGenerating = false
    @State private var error: String? = nil

    private var inviteURL: URL? {
        guard let token else { return nil }
        return URL(string: "cohab://join?token=\(token.uuidString)")
    }

    var body: some View {
        ZStack {
            Color.cohBg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(strings.inviteTitle) \(household.partnerBName)")
                            .font(.system(size: 32, weight: .regular, design: .serif))
                            .foregroundStyle(Color.cohInk)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(strings.inviteExplain)
                            .font(.body)
                            .foregroundStyle(Color.cohInk.opacity(0.75))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        if token == nil {
                            Button {
                                Task { await generateToken() }
                            } label: {
                                HStack(spacing: 8) {
                                    if isGenerating { ProgressView().tint(.white) }
                                    Text(isGenerating ? strings.inviteGenerating : strings.inviteGenerate)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.cohGreen, in: RoundedRectangle(cornerRadius: 12))
                                .foregroundStyle(.white)
                            }
                            .disabled(isGenerating)
                        } else {
                            if let url = inviteURL {
                                // The message tells the recipient to install the
                                // app first — the cohab:// link only opens when
                                // the app is already on their phone.
                                ShareLink(item: url, message: Text(strings.inviteShareMessage)) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "square.and.arrow.up")
                                        Text(strings.inviteShare).fontWeight(.semibold)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.cohGreen, in: RoundedRectangle(cornerRadius: 12))
                                    .foregroundStyle(.white)
                                }
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text(strings.inviteManual)
                                    .font(.caption)
                                    .foregroundStyle(Color.cohInk.opacity(0.55))
                                    .textCase(.uppercase)
                                    .kerning(0.5)

                                HStack {
                                    Text(token!.uuidString)
                                        .font(.system(.footnote, design: .monospaced))
                                        .foregroundStyle(Color.cohInk)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                    Button {
                                        UIPasteboard.general.string = token!.uuidString
                                    } label: {
                                        Image(systemName: "doc.on.doc").foregroundStyle(Color.cohGreen)
                                    }
                                }
                                .padding(12)
                                .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 10))
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cohInk.opacity(0.08), lineWidth: 1))
                            }

                            Button { token = nil } label: {
                                Text(strings.inviteNewLink).font(.subheadline).foregroundStyle(Color.cohGreen)
                            }
                        }
                    }

                    if let error {
                        Text(error).font(.footnote).foregroundStyle(.red)
                            .padding(10).background(.red.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
                    }

                    Text(strings.inviteExpiry)
                        .font(.footnote)
                        .foregroundStyle(Color.cohInk.opacity(0.50))
                }
                .padding(24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(strings.done) { dismiss() }
                    .foregroundStyle(Color.cohGreen)
            }
        }
    }

    private func generateToken() async {
        isGenerating = true
        error = nil
        // The store's household is the canonical remote one. The local SwiftData
        // household passed in can be a leftover with an id the server doesn't
        // know (FK failure on insert), so prefer the store's id.
        let householdId = store.household?.id ?? household.id
        do {
            token = try await SupabaseService.createInviteToken(householdId: householdId)
        } catch {
            self.error = error.localizedDescription
        }
        isGenerating = false
    }
}
