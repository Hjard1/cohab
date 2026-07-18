import SwiftUI

struct FurnitureListView: View {
    let asset: Asset
    let household: Household
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var strings = AppStrings.shared

    @State private var showAdd = false
    @State private var editingItem: FurnitureItem? = nil

    private var sym: String { household.currencySymbol }

    private var sortedItems: [FurnitureItem] {
        asset.furnitureItems.sorted { $0.label < $1.label }
    }

    private var totalValue: Double {
        asset.furnitureItems.reduce(0) { $0 + $1.currentValue }
    }

    private var valueA: Double {
        asset.furnitureItems.reduce(0) {
            let share: Double = switch $1.ownerKey {
            case "A": 1.0
            case "shared": asset.ownershipShareA
            default: 0.0
            }
            return $0 + $1.currentValue * share
        }
    }

    private var valueB: Double { totalValue - valueA }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cohBg.ignoresSafeArea()

                if asset.furnitureItems.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            summaryHeader
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                                .padding(.bottom, 20)

                            Text(strings.furnSectionHeader)
                                .font(.caption.bold()).tracking(1).foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 10)

                            VStack(spacing: 10) {
                                ForEach(sortedItems) { item in
                                    itemRow(item)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            .navigationTitle(asset.label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(strings.cancel) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddFurnitureItemView(asset: asset, household: household)
        }
        .sheet(item: $editingItem) { item in
            EditFurnitureItemView(item: item, household: household)
        }
    }

    // MARK: Summary header

    private var summaryHeader: some View {
        VStack(spacing: 14) {
            HStack {
                Text(strings.furnTotalValue)
                    .font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text(sym + Int(totalValue).formatted())
                    .font(.title3.bold().monospacedDigit()).foregroundStyle(Color.cohInk)
            }
            HStack(spacing: 8) {
                partnerPill(household.partnerAName, amount: valueA, color: .cohGreen)
                partnerPill(household.partnerBName, amount: valueB, color: Color.cohBlue)
            }
        }
        .padding(16)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
    }

    private func partnerPill(_ name: String, amount: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(name).font(.caption.weight(.semibold)).foregroundStyle(color)
            Text(sym + Int(amount).formatted()).font(.subheadline.bold().monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: Item row

    private func itemRow(_ item: FurnitureItem) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(item.label)
                    .font(.subheadline.weight(.medium)).foregroundStyle(Color.cohInk)
                Text(ownerLabel(item.ownerKey))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if item.currentValue > 0 {
                Text(sym + Int(item.currentValue).formatted())
                    .font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
            }
            Button {
                withAnimation { modelContext.delete(item) }
            } label: {
                Image(systemName: "trash")
                    .font(.subheadline).foregroundStyle(Color.cohTertiary)
                    .frame(width: 44, height: 44).contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.03), radius: 4, y: 2)
        .onTapGesture { editingItem = item }
    }

    private func ownerLabel(_ key: String) -> String {
        switch key {
        case "A":      return household.partnerAName
        case "B":      return household.partnerBName
        default:       return strings.furnShared
        }
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "sofa.fill")
                .font(.system(size: 44)).foregroundStyle(Color.cohTertiary)
            VStack(spacing: 8) {
                Text(strings.furnNoItemsYet)
                    .font(.title3.bold())
                Text(strings.furnNoItemsBody)
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal, 40)
            }
            Button {
                showAdd = true
            } label: {
                Label(strings.furnAddItem, systemImage: "plus")
                    .font(.headline).foregroundStyle(.white)
                    .padding(.horizontal, 24).padding(.vertical, 14)
                    .background(Color.cohGreen, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Add furniture item

struct AddFurnitureItemView: View {
    let asset: Asset
    let household: Household
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var strings = AppStrings.shared

    @State private var label = ""
    @State private var valueText = ""
    @State private var ownerKey = "shared"

    private var canAdd: Bool { !label.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section(strings.furnItemSection) {
                    TextField(strings.furnNamePlaceholder, text: $label)
                    HStack {
                        Text(household.currencySymbol).foregroundStyle(.secondary)
                        TextField(strings.furnValueOptional, text: $valueText)
                            .keyboardType(.decimalPad)
                    }
                }
                Section(strings.furnWhoOwns) {
                    Picker("", selection: $ownerKey) {
                        Text(household.partnerAName).tag("A")
                        Text(strings.furnShared).tag("shared")
                        Text(household.partnerBName).tag("B")
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(strings.furnAddItem)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button(strings.cancel) { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(strings.add) { add() }.bold().disabled(!canAdd)
                }
            }
        }
    }

    private func add() {
        let value = Double(valueText.replacingOccurrences(of: ",", with: "")) ?? 0
        let item = FurnitureItem(
            label: label.trimmingCharacters(in: .whitespaces),
            currentValue: value,
            ownerKey: ownerKey
        )
        asset.furnitureItems.append(item)
        dismiss()
    }
}

// MARK: - Edit furniture item

struct EditFurnitureItemView: View {
    let item: FurnitureItem
    let household: Household
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var strings = AppStrings.shared

    @State private var label: String
    @State private var valueText: String
    @State private var ownerKey: String

    init(item: FurnitureItem, household: Household) {
        self.item = item
        self.household = household
        _label    = State(wrappedValue: item.label)
        _valueText = State(wrappedValue: item.currentValue > 0 ? String(Int(item.currentValue)) : "")
        _ownerKey = State(wrappedValue: item.ownerKey)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(strings.furnItemSection) {
                    TextField(strings.furnNameShort, text: $label)
                    HStack {
                        Text(household.currencySymbol).foregroundStyle(.secondary)
                        TextField("0", text: $valueText).keyboardType(.decimalPad)
                    }
                }
                Section(strings.furnWhoOwns) {
                    Picker("", selection: $ownerKey) {
                        Text(household.partnerAName).tag("A")
                        Text(strings.furnShared).tag("shared")
                        Text(household.partnerBName).tag("B")
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle(strings.furnEditItem)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button(strings.cancel) { dismiss() } }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(strings.save) { save() }.bold()
                }
            }
        }
    }

    private func save() {
        item.label = label.trimmingCharacters(in: .whitespaces)
        item.currentValue = Double(valueText.replacingOccurrences(of: ",", with: "")) ?? 0
        item.ownerKey = ownerKey
        dismiss()
    }
}
