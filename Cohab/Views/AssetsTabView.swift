import SwiftUI
import SwiftData

struct AssetsTabView: View {
    @Query private var households: [Household]
    @State private var showAddAsset = false
    @State private var editingAsset: Asset?
    @ObservedObject private var strings = AppStrings.shared

    private var household: Household? { households.first }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color.cohBg.ignoresSafeArea()

                if let h = household {
                    if h.assets.isEmpty {
                        emptyState { showAddAsset = true }
                    } else {
                        ScrollView {
                            VStack(spacing: 14) {
                                ForEach(h.assets) { asset in
                                    NavigationLink(destination: AssetDetailView(asset: asset, household: h)) {
                                        AssetRowCard(asset: asset, household: h)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(20)
                            .padding(.bottom, 88)
                        }
                    }

                    Button { showAddAsset = true } label: {
                        Image(systemName: "plus")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                            .frame(width: 58, height: 58)
                            .background(Color.cohGreen, in: Circle())
                            .shadow(color: .cohGreen.opacity(0.35), radius: 14, y: 6)
                    }
                    .padding(24)
                } else {
                    emptyState {}
                }
            }
            .navigationTitle("Assets")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showAddAsset) {
            if let h = household { AddAssetView(household: h) }
        }
        .sheet(item: $editingAsset) { asset in
            if let h = household { EditAssetView(asset: asset, household: h) }
        }
    }

    private func emptyState(action: @escaping () -> Void) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "plus.square.dashed")
                .font(.system(size: 48))
                .foregroundStyle(Color(.tertiaryLabel))
            VStack(spacing: 8) {
                Text(strings.assetsNoAssetsTitle).font(.title3.bold())
                Text(strings.assetsNoAssetsSub)
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal, 32)
            }
            Button(action: action) {
                Label(strings.assetsAddFirst, systemImage: "plus")
                    .font(.headline).foregroundStyle(.white)
                    .padding(.horizontal, 28).padding(.vertical, 14)
                    .background(Color.cohGreen, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Asset row card

struct AssetRowCard: View {
    let asset: Asset
    let household: Household

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(asset.type.color.opacity(0.12))
                    .frame(width: 50, height: 50)
                Image(systemName: asset.type.icon)
                    .font(.title3).foregroundStyle(asset.type.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(asset.label)
                    .font(.headline).foregroundStyle(Color.cohInk)
                if !asset.address.isEmpty {
                    Text(asset.address)
                        .font(.caption).foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                HStack(spacing: 4) {
                    Text("\(Int(asset.ownershipShareA * 100))% \(household.partnerAName)")
                        .font(.caption.bold()).foregroundStyle(Color.cohGreen)
                    Text("·")
                        .font(.caption).foregroundStyle(.secondary)
                    Text("\(household.currencySymbol)\(Int(asset.currentValue).formatted())")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .padding(16)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
}
