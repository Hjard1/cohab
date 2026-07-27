import SwiftUI
import PhotosUI

struct AssetDetailView: View {
    let asset: Asset
    let household: Household

    @State private var showAddContribution = false
    @State private var showEdit = false
    @State private var showSettlement = false
    @State private var editingOwnership = false
    @State private var photoImage: UIImage?
    @State private var photoPickItem: PhotosPickerItem?
    @State private var imageUploadFailed = false
    @Environment(\.modelContext) private var modelContext
    @Environment(HouseholdStore.self) private var store
    @EnvironmentObject private var auth: AuthManager
    @ObservedObject private var strings = AppStrings.shared

    private var netEquity: Double { asset.currentValue - asset.remainingLoan }

    // Contribution-adjusted equity (no sale costs so totals sum to netEquity)
    private var equityResult: SettlementResult {
        SettlementEngine.settle(SettlementInput(
            salePrice: asset.currentValue,
            remainingLoan: asset.remainingLoan,
            salesCosts: 0,
            ownershipShareA: asset.ownershipShareA,
            annualRate: household.annualInterestRate,
            contributions: asset.contributions.map {
                Contribution(owner: $0.ownerKey == "A" ? .a : .b,
                             amount: $0.amount, date: $0.date, label: $0.label)
            },
            settlementDate: Date()
        ))
    }
    private var equityA: Double { equityResult.payout[.a] ?? 0 }
    private var equityB: Double { equityResult.payout[.b] ?? 0 }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Themed visual header — icon + colour per asset type,
                // so a home, a car, and a sofa don't all look like the same row of text.
                heroHeader

                // Settlement value + split (primary info first)
                equityCard

                // Ownership chart (compact)
                ownershipChart

                // Contribution history
                contributionHistory

                Spacer(minLength: 20)
            }
            .padding(20)
            .padding(.bottom, 88)
        }
        .background(Color.cohBg.ignoresSafeArea())
        .navigationTitle(asset.address.isEmpty ? asset.label : asset.address)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showEdit = true } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Color.cohGreen)
                }
            }
        }
        .safeAreaInset(edge: .bottom) { bottomButtons }
        .sheet(isPresented: $showAddContribution) {
            AddContributionView(asset: asset, household: household)
        }
        .sheet(isPresented: $showEdit) {
            EditAssetView(asset: asset, household: household)
        }
        .sheet(isPresented: $showSettlement) {
            SettlementView(asset: asset, household: household)
        }
        .task(id: asset.id) {
            let signedIn = auth.isSignedIn
            // Show the disk-cached photo instantly, then refresh from remote;
            // on failure keep the cached image (signed out is local-only).
            if let cached = AssetImageStore.loadCached(assetId: asset.id) {
                photoImage = cached
            }
            guard signedIn else { return }
            if let fresh = await AssetImageStore.load(
                kind: .photo, householdId: household.id,
                assetId: asset.id, signedIn: true) {
                photoImage = fresh
            }
        }
        .onChange(of: photoPickItem) { _, item in handlePick(item) }
        .alert(strings.assetImageUploadFailed, isPresented: $imageUploadFailed) {
            Button(strings.ok, role: .cancel) {}
        }
    }

    // MARK: - Hero header

    private var heroHeader: some View {
        ZStack(alignment: .bottomLeading) {
            if let photoImage {
                // User-uploaded photo replaces the generated gradient header
                Image(uiImage: photoImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, minHeight: 168, maxHeight: 240)
                    .clipped()

                // Dark scrim so the title stays readable over any photo
                LinearGradient(
                    colors: [.black.opacity(0.55), .clear],
                    startPoint: .bottom, endPoint: .center
                )
            } else {
                LinearGradient(
                    colors: [asset.type.color, asset.type.color.opacity(0.72)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )

                // Oversized, low-opacity icon motif bleeding off the corner —
                // decorative texture, not competing with the readable text below.
                Image(systemName: asset.type.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 170, height: 170)
                    .foregroundStyle(.white.opacity(0.14))
                    .rotationEffect(.degrees(-10))
                    .offset(x: 78, y: -36)
            }

            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    Circle().fill(.white.opacity(0.20)).frame(width: 52, height: 52)
                    Image(systemName: asset.type.icon)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(asset.type.displayName.uppercased())
                        .font(.caption2.weight(.bold))
                        .tracking(1.2)
                        .foregroundStyle(.white.opacity(0.75))
                    Text(asset.label)
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    if !asset.address.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.and.ellipse").font(.caption2)
                            Text(asset.address).font(.caption).lineLimit(1)
                        }
                        .foregroundStyle(.white.opacity(0.75))
                    }
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, minHeight: 168, maxHeight: photoImage != nil ? 240 : .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: asset.type.color.opacity(0.25), radius: 12, y: 6)
        .overlay(alignment: .topTrailing) {
            PhotosPicker(selection: $photoPickItem, matching: .images) {
                HStack(spacing: 5) {
                    Image(systemName: "camera.fill")
                    Text(photoImage == nil ? strings.assetAddPhoto : strings.assetChangePhoto)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(.black.opacity(0.45), in: Capsule())
            }
            .padding(12)
            .accessibilityLabel(photoImage == nil ? strings.assetAddPhoto : strings.assetChangePhoto)
        }
    }

    // MARK: - Photo picking

    private func handlePick(_ item: PhotosPickerItem?) {
        guard let item else { return }
        Task { @MainActor in
            defer { photoPickItem = nil }
            guard let data = try? await item.loadTransferable(type: Data.self),
                  let uiImage = UIImage(data: data) else { return }
            do {
                photoImage = try await AssetImageStore.save(
                    uiImage, kind: .photo, householdId: household.id,
                    assetId: asset.id, signedIn: auth.isSignedIn)
            } catch {
                print("[Cohab] Asset image upload failed: \(error.localizedDescription)")
                imageUploadFailed = true
            }
        }
    }

    // MARK: - Donut chart

    private var ownershipChart: some View {
        VStack(spacing: 20) {
            // Tappable donut
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 16)
                    .frame(width: 130, height: 130)

                Circle()
                    .trim(from: 0, to: asset.ownershipShareA)
                    .stroke(Color.cohGreen, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .frame(width: 130, height: 130)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 3) {
                    Text(strings.assetOwnership)
                        .font(.caption2.bold()).tracking(1)
                        .foregroundStyle(Color.cohSecondary)
                    Text("\(Int(asset.ownershipShareA * 100))%")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.cohInk)
                    if !editingOwnership {
                        Image(systemName: "pencil.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.cohGreen.opacity(0.6))
                    }
                }
            }
            .animation(.easeInOut(duration: 0.4), value: asset.ownershipShareA)
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    editingOwnership.toggle()
                }
            }

            // Partner split row
            HStack(spacing: 24) {
                partnerShare(name: household.partnerAName,
                             share: asset.ownershipShareA,
                             color: Color.cohGreen)
                Divider().frame(height: 32)
                partnerShare(name: household.partnerBName,
                             share: 1 - asset.ownershipShareA,
                             color: Color.cohBlue)
            }
            .padding(.horizontal, 40)

            // Inline ownership slider — appears on tap
            if editingOwnership {
                VStack(spacing: 10) {
                    Divider()
                    HStack {
                        Text(household.partnerAName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.cohGreen)
                        Spacer()
                        Text(household.partnerBName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.cohBlue)
                    }
                    Slider(value: Binding(
                        get: { asset.ownershipShareA },
                        set: { asset.ownershipShareA = $0 }
                    ), in: 0...1, step: 0.01)
                    .tint(Color.cohGreen)

                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            editingOwnership = false
                        }
                        // Persist remotely too — the slider only wrote to local
                        // SwiftData, so the partner never saw the change and the
                        // next sync overwrote it.
                        let id = asset.id
                        let type = asset.assetType, lbl = asset.label, addr = asset.address
                        let val = asset.currentValue, loan = asset.remainingLoan
                        let salesCost = asset.salesCostFraction, share = asset.ownershipShareA
                        Task { @MainActor in
                            do {
                                try await store.updateAsset(
                                    id, assetType: type, label: lbl, address: addr,
                                    currentValue: val, remainingLoan: loan,
                                    salesCostFraction: salesCost, ownershipShareA: share)
                            } catch {
                                print("[Cohab] Ownership update failed: \(error.localizedDescription)")
                            }
                        }
                    } label: {
                        Text(strings.save)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.cohGreen, in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(24)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func partnerShare(name: String, share: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 6) {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(name).font(.caption).foregroundStyle(Color.cohSecondary).lineLimit(1)
            }
            Text("\(Int(share * 100))%")
                .font(.title3.bold()).foregroundStyle(Color.cohInk)
        }
    }

    // MARK: - Equity card

    private var equityCard: some View {
        let shortfall = equityResult.shortfall
        return VStack(alignment: .leading, spacing: 14) {
            Text(strings.assetNetEquity)
                .font(.caption.bold()).tracking(0.5)
                .foregroundStyle(Color.cohSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(household.currencySymbol)
                    .font(.title3.bold()).foregroundStyle(Color.cohSecondary)
                Text(fmtGroupedAmount(netEquity, country: household.country))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.cohInk)
            }

            Divider()

            HStack {
                equityRow(name: household.partnerAName, amount: equityA, color: Color.cohGreen)
                Spacer()
                equityRow(name: household.partnerBName, amount: equityB,
                          color: Color.cohBlue)
            }

            if !asset.contributions.isEmpty {
                Divider()
                Text(shortfall
                     ? strings.settlementShortfallInline
                     : strings.dashboardContribFirst)
                    .font(.caption)
                    .foregroundStyle(shortfall ? Color.orange : Color.cohMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func equityRow(name: String, amount: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(name)
                .font(.caption).foregroundStyle(Color.cohSecondary).lineLimit(1)
            HStack(spacing: 3) {
                Circle().fill(color).frame(width: 7, height: 7)
                Text(household.moneyText(amount))
                    .font(.subheadline.bold()).foregroundStyle(Color.cohInk)
            }
        }
    }

    // MARK: - Contribution history

    private var contributionHistory: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(strings.assetContribHistory)
                .font(.headline).foregroundStyle(Color.cohInk)

            if asset.contributions.isEmpty {
                Text(strings.assetNoContribs)
                    .font(.subheadline).foregroundStyle(Color.cohSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 0) {
                    ForEach(asset.contributions.sorted { $0.date > $1.date }) { contrib in
                        let contribColor: Color = contrib.ownerKey == "A" ? .cohGreen : .cohBlue
                        let contribName: String = contrib.ownerKey == "A" ? household.partnerAName : household.partnerBName
                        HStack(spacing: 12) {
                            ZStack {
                                Circle().fill(contribColor.opacity(0.12)).frame(width: 32, height: 32)
                                Text(String(contribName.prefix(1)).uppercased())
                                    .font(.caption.bold()).foregroundStyle(contribColor)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(contrib.label.isEmpty ? contrib.category.capitalized : contrib.label)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(Color.cohInk)
                                Text(contrib.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption).foregroundStyle(Color.cohSecondary)
                            }
                            Spacer()
                            ContributionReceiptBadge(contributionId: contrib.id,
                                                     householdId: household.id,
                                                     assetId: asset.id,
                                                     signedIn: auth.isSignedIn)
                            Text(household.moneyText(contrib.amount))
                                .font(.subheadline.bold())
                                .foregroundStyle(contribColor)
                            Button {
                                let id = contrib.id
                                // Remote-first delete: the local row is removed
                                // only on success, otherwise the next sync would
                                // resurrect it (looking like "cannot delete").
                                Task { @MainActor in
                                    do {
                                        try await SupabaseService.deleteContribution(id)
                                        modelContext.delete(contrib)
                                        // Best-effort cleanup of any attached receipt
                                        await AssetImageStore.deleteReceipt(
                                            contributionId: id, householdId: household.id,
                                            assetId: asset.id, signedIn: auth.isSignedIn)
                                    } catch {
                                        print("[Cohab] Delete contribution failed: \(error.localizedDescription)")
                                    }
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(Color.red.opacity(0.55))
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(strings.contribDelete)
                        }
                        .padding(.vertical, 12)

                        if contrib.id != asset.contributions.sorted(by: { $0.date > $1.date }).last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal, 18)
                .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
            }
        }
    }

    // MARK: - Bottom buttons

    private var bottomButtons: some View {
        HStack(spacing: 14) {
            Button { showSettlement = true } label: {
                Text(strings.settlementTitle)
                    .font(.headline).foregroundStyle(Color.cohInk)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.cohInk.opacity(0.2), lineWidth: 1.5)
                    )
            }
            if household.partnerLeft != true {
                Button { showAddContribution = true } label: {
                    Text(strings.assetAddContrib)
                        .font(.headline).foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Color.cohGreen, in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.cohBg.ignoresSafeArea(edges: .bottom))
    }
}

// MARK: - Contribution receipt badge

/// Paperclip shown on contribution rows that have a receipt; tap to view it
/// full screen. Existence is discovered by attempting a load — the local disk
/// cache and the store's memory cache make repeat checks cheap, so no storage
/// listing is needed.
private struct ContributionReceiptBadge: View {
    let contributionId: UUID
    let householdId: UUID
    let assetId: UUID
    let signedIn: Bool

    @State private var checked = false
    @State private var image: UIImage?
    @State private var showFull = false
    @ObservedObject private var strings = AppStrings.shared

    var body: some View {
        Group {
            if checked, let image {
                Button { showFull = true } label: {
                    Image(systemName: "paperclip")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.cohSecondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(strings.assetReceipt)
                .fullScreenCover(isPresented: $showFull) {
                    ZStack(alignment: .topTrailing) {
                        Color.black.ignoresSafeArea()
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .ignoresSafeArea()
                        Button { showFull = false } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundStyle(.white.opacity(0.9))
                                .padding(20)
                        }
                        .accessibilityLabel(strings.close)
                    }
                }
            } else if !checked {
                // Nothing to show until the receipt lookup finishes
                EmptyView()
            }
        }
        .task {
            image = await AssetImageStore.loadReceipt(
                contributionId: contributionId, householdId: householdId,
                assetId: assetId, signedIn: signedIn)
            checked = true
        }
    }
}
