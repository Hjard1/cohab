import SwiftUI

struct ExpenseSplitView: View {
    @State private var incomeA  = ""
    @State private var incomeB  = ""
    @State private var housing  = ""
    @State private var utilities = ""
    @State private var groceries = ""
    @State private var transport = ""
    @State private var other    = ""
    @State private var mode = SplitMode.weighted

    enum SplitMode: String, CaseIterable {
        case weighted      = "By income"
        case equalDisp     = "Equal left over"
    }

    private var iA:          Double { parse(incomeA) }
    private var iB:          Double { parse(incomeB) }
    private var totalIncome: Double { iA + iB }
    private var totalShared: Double {
        [housing, utilities, groceries, transport, other].map { parse($0) }.reduce(0, +)
    }
    private var hasInput: Bool { totalIncome > 0 && totalShared > 0 }

    private var splitA: Double {
        switch mode {
        case .weighted:
            return totalIncome > 0 ? iA / totalIncome : 0.5
        case .equalDisp:
            guard totalShared > 0 else { return 0.5 }
            return min(1, max(0, 0.5 + (iA - iB) / (2 * totalShared)))
        }
    }

    private var payA:  Double { totalShared * splitA }
    private var payB:  Double { totalShared * (1 - splitA) }
    private var leftA: Double { iA - payA }
    private var leftB: Double { iB - payB }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                resultCard
                inputCard("MONTHLY NET INCOME") {
                    inputRow("Partner A (after tax)", placeholder: "3,500", text: $incomeA)
                    inputRow("Partner B (after tax)", placeholder: "2,800", text: $incomeB)
                }
                inputCard("MONTHLY SHARED EXPENSES") {
                    inputRow("Housing (rent / mortgage)", placeholder: "1,200", text: $housing)
                    inputRow("Utilities",                  placeholder: "150",   text: $utilities)
                    inputRow("Groceries",                  placeholder: "400",   text: $groceries)
                    inputRow("Transport",                  placeholder: "200",   text: $transport)
                    inputRow("Other",                      placeholder: "100",   text: $other)
                }
                splitMethodCard
            }
            .padding(20)
        }
        .background(Color.cohBg.ignoresSafeArea())
        .navigationTitle("Expense split")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Result card

    private var resultCard: some View {
        VStack(spacing: 16) {
            Text("Monthly contributions")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 12) {
                partnerResult(
                    "Partner A",
                    pays: hasInput ? payA : nil,
                    left: hasInput ? leftA : nil,
                    color: .cohGreen
                )
                partnerResult(
                    "Partner B",
                    pays: hasInput ? payB : nil,
                    left: hasInput ? leftB : nil,
                    color: Color(red: 0.20, green: 0.49, blue: 0.96)
                )
            }

            if hasInput {
                GeometryReader { g in
                    HStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 5).fill(Color.cohGreen)
                            .frame(width: max(8, g.size.width * splitA - 1.5))
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color(red: 0.20, green: 0.49, blue: 0.96))
                    }
                }
                .frame(height: 10)

                HStack {
                    Text("A: \(String(format: "%.0f%%", splitA * 100))")
                    Spacer()
                    Text("B: \(String(format: "%.0f%%", (1 - splitA) * 100))")
                }
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
            } else {
                Text("Enter income and expenses above to calculate a fair split.")
                    .font(.caption)
                    .foregroundStyle(Color(.tertiaryLabel))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 3)
    }

    private func partnerResult(_ name: String, pays: Double?, left: Double?, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 4) {
                Text("Pays")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(pays.map { fmt($0) } ?? "–")
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(pays != nil ? .primary : Color(.tertiaryLabel))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Left over")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(left.map { fmt($0) } ?? "–")
                    .font(.subheadline.bold().monospacedDigit())
                    .foregroundStyle(
                        left == nil ? Color(.tertiaryLabel)
                        : (left! >= 0 ? color : .red)
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(color.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: Split method card

    private var splitMethodCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("SPLIT METHOD")
                .font(.caption.bold()).tracking(1).foregroundStyle(.secondary)

            Picker("Mode", selection: $mode) {
                ForEach(SplitMode.allCases, id: \.self) { Text($0.rawValue) }
            }
            .pickerStyle(.segmented)

            Text(mode == .weighted
                 ? "Each pays proportional to their share of total household income."
                 : "Split adjusted so both partners have the same amount left over each month.")
                .font(.caption)
                .foregroundStyle(Color(.tertiaryLabel))
        }
        .padding(18)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    // MARK: Helpers

    private func inputCard<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(.caption.bold()).tracking(1).foregroundStyle(.secondary)
            content()
        }
        .padding(18)
        .background(Color.cohCard, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    private func inputRow(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label).font(.caption.weight(.medium)).foregroundStyle(.secondary)
            TextField(placeholder, text: text)
                .keyboardType(.decimalPad)
                .font(.subheadline.monospacedDigit())
                .padding(.horizontal, 14).padding(.vertical, 10)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func parse(_ s: String) -> Double { Double(s.replacingOccurrences(of: ",", with: "")) ?? 0 }
    private func fmt(_ v: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .decimal; f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "0"
    }
}

#Preview { NavigationStack { ExpenseSplitView() } }
