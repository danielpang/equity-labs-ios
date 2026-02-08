import Foundation
import StoreKit
import Combine

// MARK: - SubscriptionManager
@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published var subscriptionState: SubscriptionState = SubscriptionState()
    @Published var product: Product?
    @Published var isLoading = false
    @Published var error: Error?

    private let apiClient = APIClient.shared
    private var updateListenerTask: Task<Void, Error>?

    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
        Task { await loadProduct() }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Product
    func loadProduct() async {
        do {
            let products = try await Product.products(for: [Constants.Subscription.monthlyProductId])
            product = products.first
            AppLogger.subscription.info("Loaded product: \(product?.displayName ?? "none")")
        } catch {
            AppLogger.subscription.error("Failed to load products: \(error.localizedDescription)")
        }
    }

    // MARK: - Load Subscription State
    func loadSubscriptionState() async {
        isLoading = true
        defer { isLoading = false }

        // Check for active subscriptions
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }

            if transaction.productID == Constants.Subscription.monthlyProductId {
                subscriptionState = SubscriptionState(
                    tier: .paid,
                    productId: transaction.productID,
                    purchaseDate: transaction.purchaseDate,
                    expirationDate: transaction.expirationDate,
                    isActive: true,
                    lastValidated: Date()
                )

                AppLogger.subscription.info("Active subscription found")
                return
            }
        }

        // No active subscription found
        subscriptionState = SubscriptionState(tier: .free)
        AppLogger.subscription.debug("No active subscription")
    }

    // MARK: - Apply Backend Tier
    func applyBackendTier(_ tier: String) {
        if tier == "paid" && subscriptionState.tier == .free {
            subscriptionState = SubscriptionState(
                tier: .paid,
                isActive: true,
                lastValidated: Date()
            )
            AppLogger.subscription.info("Applied backend tier: paid")
        } else if tier == "free" && subscriptionState.tier == .paid {
            subscriptionState = SubscriptionState(tier: .free)
            AppLogger.subscription.info("Applied backend tier: free")
        }
    }

    // MARK: - Check Stock Limit
    func canAddStock(currentCount: Int) -> Bool {
        guard let maxStocks = subscriptionState.tier.maxStocks else {
            return true // Unlimited
        }
        return currentCount < maxStocks
    }

    func stocksRemaining(currentCount: Int) -> Int? {
        guard let maxStocks = subscriptionState.tier.maxStocks else {
            return nil // Unlimited
        }
        return max(0, maxStocks - currentCount)
    }

    // MARK: - Transaction Listener
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else {
                    continue
                }

                await transaction.finish()

                await MainActor.run {
                    Task {
                        await self.loadSubscriptionState()
                    }
                }
            }
        }
    }

    // MARK: - Purchase
    func purchase() async throws {
        guard let product else {
            throw SubscriptionError.productNotLoaded
        }

        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            guard case .verified(let transaction) = verification else {
                throw SubscriptionError.purchaseFailed
            }

            await transaction.finish()

            // Send App Store receipt to backend for validation
            await sendReceiptToBackend(productId: transaction.productID)

            // Reload subscription state
            await loadSubscriptionState()

            AppLogger.subscription.info("Purchase successful")

        case .userCancelled:
            AppLogger.subscription.debug("Purchase cancelled by user")

        case .pending:
            AppLogger.subscription.info("Purchase pending approval")

        @unknown default:
            throw SubscriptionError.purchaseFailed
        }
    }

    // MARK: - Send Receipt to Backend
    private func sendReceiptToBackend(productId: String) async {
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              let receiptData = try? Data(contentsOf: receiptURL) else {
            AppLogger.subscription.error("No App Store receipt found")
            return
        }

        do {
            let request = ReceiptValidationRequest(
                receiptData: receiptData.base64EncodedString(),
                productId: productId
            )
            let _: ReceiptValidationResponse = try await apiClient.upload(.validateReceipt, body: request)
            AppLogger.subscription.info("Receipt validated with backend")
        } catch {
            AppLogger.subscription.error("Receipt validation failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Restore Purchases
    func restorePurchases() async throws {
        try await AppStore.sync()
        await loadSubscriptionState()
    }
}

// MARK: - SubscriptionError
enum SubscriptionError: LocalizedError {
    case productNotLoaded
    case purchaseFailed
    case restoreFailed
    case validationFailed

    var errorDescription: String? {
        switch self {
        case .productNotLoaded:
            return "Subscription product not available. Please try again later."
        case .purchaseFailed:
            return "Purchase failed"
        case .restoreFailed:
            return "Failed to restore purchases"
        case .validationFailed:
            return "Receipt validation failed"
        }
    }
}
