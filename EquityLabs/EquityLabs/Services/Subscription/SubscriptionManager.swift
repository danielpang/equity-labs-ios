import Foundation
import StoreKit
import Combine

// MARK: - SubscriptionManager
@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published var subscriptionState: SubscriptionState = SubscriptionState()
    @Published var isLoading = false
    @Published var error: Error?

    private var updateListenerTask: Task<Void, Error>?

    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
    }

    deinit {
        updateListenerTask?.cancel()
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

    // MARK: - Purchase (Placeholder for Phase 5)
    func purchase() async throws {
        // TODO: Implement in Phase 5
        throw SubscriptionError.notImplemented
    }

    // MARK: - Restore Purchases
    func restorePurchases() async throws {
        try await AppStore.sync()
        await loadSubscriptionState()
    }
}

// MARK: - SubscriptionError
enum SubscriptionError: LocalizedError {
    case notImplemented
    case purchaseFailed
    case restoreFailed
    case validationFailed

    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "Feature not yet implemented"
        case .purchaseFailed:
            return "Purchase failed"
        case .restoreFailed:
            return "Failed to restore purchases"
        case .validationFailed:
            return "Receipt validation failed"
        }
    }
}
