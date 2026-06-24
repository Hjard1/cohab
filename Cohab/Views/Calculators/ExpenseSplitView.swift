import SwiftUI

/// Calculates a fair monthly expense split in two modes:
/// - Weighted by income: each pays proportional to their share of total income.
/// - Equal disposable: split so both partners have the same money left over each month.
struct ExpenseSplitView: View {
    @State private var incomeA = ""
    @State private var incomeB = ""
    @State private var housing = ""
    @State private var utilities = ""
    @State private var groceries = ""
    @State private var transport = ""
    @State private var other = ""
    @State private var mode = SplitMode.weighted

    enum SplitMode: String, CaseIterable {
        case weighted = "Weighted by income"
        case equalDisposable = "Equal disposable"
    }

    private var iA: Double { parse(incomeA) }
    private var iB: Double { parse(incomeB) }
    private var totalIncome: Double { iA + iB }

    private var totalShared: Double {
        [housing, utilities, groceries, transport, other].map { parse($0) }.reduce(0, +)
    }

    private var splitRatioA: Double {
        switch mode {
        case .weighted:
            return totalIncome > 0 ? iA / totalIncome : 0.5
        case .equalDisposable:
            guard totalShared > 0 else { return 0.5 }
            // Solve: iA - s·T = iB - (1-s)·T  →  s = 0.5 + (iA - iB) / (2T)
            let s = 0.5 + (iA - iB) / (2 * totalShared)
            return min(1, max(0, s))
        }
    }

    private var payA: Double { totalShared * splitRatioA }
    private var payB: Double { totalShared * (1 - splitRatioA) }
    private var leftA: Double { iA - payA }
    private var leftB: Double { iB - payB }
    private var hasInput: Bool { totalIncome > 0 && totalShared > 0 }

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.05).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    inputSection
                    if hasInput { resultSection }
                }
                .padding(24)
            }
        }
        .navigationTitle("Expense split")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            cardSection("Monthly net income") {
                inputRow("Partner A (after tax)", placeholder: "3,500", binding: $incomeA)
                inputRow("Partner B (after tax)", placeholder: "2,800", binding: $incomeB)
            }

            cardSection("Monthly shared expenses") {
                inputRow("Housing (rent/mortgage)", placeholder: "1,200", binding: $housing)
                inputRow("Utilities", placeholder: "150", binding: $utilities)
                inputRow("Groceries", placeholder: "400", binding: $groceries)
                inputRow("Transport", placeholder: "200", binding: $transport)
                inputRow("Other", placeholder: "100", binding: $other)
            }

            cardSection("Split method") {
                Picker("Mode", selection: $mode) {
                    ForEach(SplitMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                Text(mode == .weighted
                     ? "Each pays their share of total income."
                     : "Adjusted so both partners have the same amount left each month.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
    }

    private var resultSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Result")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                resultColumn("Partner A", pays: payA, left: leftA, color: .green)
                resultColumn("Partner B", pays: payB, left: leftB, color: .blue)
            }

            splitBar(ratioA: splitRatioA)
                .frame(height: 8)

            VStack(alignment: .leading, spacing: 8) {
                detailRow("Total shared expenses", fmt(totalShared))
                detailRow("Partner A's share", String(format: "%.1f%%", splitRatioA * 100))
                detailRow("Partner B's share", String(format: "%.1f%%", (1 - splitRatioA) * 100))
            }
            .padding(16)
            .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private func resultColumn(_ name: String, pays: Double, left: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(name).font(.caption.bold()).foregroundStyle(color)
            Group {
                statRow("Pays", fmt(pays))
                statRow("Left over", fmt(max(0, left)), highlight: left >= 0)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
    }

    private func statRow(_ label: String, _ value: String, highlight: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label).font(.caption2).foregroundStyle(.white.opacity(0.4))
            Text(value)
                .font(.subheadline.bold().monospacedDigit())
                .foregroundStyle(highlight ? .white : .orange)
        }
    }

    private func splitBar(ratioA: Double) -> some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.green.opacity(0.7))
                    .frame(width: max(4, geo.size.width * ratioA - 1))
                RoundedRectangle(cornerRadius: 4).fill(.blue.opacity(0.7))
            }
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).font(.caption).foregroundStyle(.white.opacity(0.5))
            Spacer()
            Text(value).font(.caption.bold().monospacedDigit()).foregroundStyle(.white)
        }
    }

    private func cardSection<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title.uppercased()).font(.caption.bold()).tracking(1).foregroundStyle(.white.opacity(0.35))
            content()
        }
        .padding(16)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
    }

    private func inputRow(_ label: String, placeholder: String, binding: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.white.opacity(0.5))
            TextField(placeholder, text: binding)
                .keyboardType(.decimalPad)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.white)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private func parse(_ s: String) -> Double { Double(s.replacingOccurrences(of: ",", with: "")) ?? 0 }
    private func fmt(_ v: Double) -> String {
        let f = NumberFormatter(); f.numberStyle = .decimal; f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "0"
    }
}

#Preview { NavigationStack { ExpenseSplitView() } }
