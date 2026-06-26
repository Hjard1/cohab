import SwiftUI

/// Reusable disclaimer sheet — shown in onboarding and accessible from settings.
struct DisclaimerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var strings: AppStrings

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Icon + heading
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange.opacity(0.1))
                                .frame(width: 48, height: 48)
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title3).foregroundStyle(.orange)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(strings.disclaimerTitle)
                                .font(.headline)
                            Text("cohab · Legal notice")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }

                    Text(strings.disclaimerBody)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineSpacing(3)
                }
                .padding(24)
            }
            .background(Color.cohBg.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
