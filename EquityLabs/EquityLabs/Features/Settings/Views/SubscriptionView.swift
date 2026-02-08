import SwiftUI
import StoreKit

// MARK: - SubscriptionView
struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    header

                    // Feature comparison
                    featureComparison

                    // Price & Subscribe
                    purchaseSection

                    // Restore
                    restoreButton

                    // Legal links
                    legalLinks
                }
                .padding()
            }
            .background(Color.backgroundPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Upgrade to Premium")
                .font(.title)
                .fontWeight(.bold)

            Text("Unlock the full power of EquityLabs")
                .font(.subheadline)
                .foregroundColor(.textSecondary)
        }
        .padding(.top, 20)
    }

    // MARK: - Feature Comparison

    private var featureComparison: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Premium Features")
                .font(.headline)

            ForEach(SubscriptionTier.paid.features, id: \.self) { feature in
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)

                    Text(feature)
                        .font(.subheadline)

                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    // MARK: - Purchase Section

    private var purchaseSection: some View {
        VStack(spacing: 12) {
            if let product = subscriptionManager.product {
                Text("\(product.displayPrice) / month")
                    .font(.title2)
                    .fontWeight(.semibold)
            } else {
                Text("$4.99 / month")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.textSecondary)
            }

            Button {
                Task {
                    await performPurchase()
                }
            } label: {
                Group {
                    if isPurchasing || subscriptionManager.isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Subscribe Now")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isPurchasing || subscriptionManager.isLoading)
        }
    }

    // MARK: - Restore Button

    private var restoreButton: some View {
        Button {
            Task {
                await performRestore()
            }
        } label: {
            Group {
                if isRestoring {
                    ProgressView()
                } else {
                    Text("Restore Purchases")
                        .font(.subheadline)
                }
            }
        }
        .disabled(isRestoring)
    }

    // MARK: - Legal Links

    private var legalLinks: some View {
        HStack(spacing: 16) {
            Link("Terms of Service", destination: URL(string: Constants.URLs.termsOfService)!)
                .font(.caption)

            Text("•")
                .font(.caption)
                .foregroundColor(.textTertiary)

            Link("Privacy Policy", destination: URL(string: Constants.URLs.privacyPolicy)!)
                .font(.caption)
        }
        .padding(.bottom)
    }

    // MARK: - Actions

    private func performPurchase() async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            try await subscriptionManager.purchase()
            if subscriptionManager.subscriptionState.tier == .paid {
                dismiss()
            }
        } catch {
            if !(error is CancellationError) {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func performRestore() async {
        isRestoring = true
        defer { isRestoring = false }

        do {
            try await subscriptionManager.restorePurchases()
            if subscriptionManager.subscriptionState.tier == .paid {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Preview
#Preview {
    SubscriptionView()
        .environmentObject(SubscriptionManager.shared)
}
