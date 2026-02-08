import Foundation

// MARK: - SubscriptionTier
enum SubscriptionTier: String, Codable, CaseIterable {
    case free = "free"
    case paid = "paid"

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .paid: return "Premium"
        }
    }

    var maxStocks: Int? {
        switch self {
        case .free: return 5
        case .paid: return nil // unlimited
        }
    }

    var hasNewsSentiment: Bool {
        switch self {
        case .free: return false
        case .paid: return true
        }
    }

    var features: [String] {
        switch self {
        case .free:
            return [
                "Track up to 5 stocks",
                "Real-time prices",
                "Interactive charts",
                "Basic news feed"
            ]
        case .paid:
            return [
                "Unlimited stocks",
                "Real-time prices",
                "Interactive charts",
                "AI news sentiment analysis",
                "Article summaries",
                "Cloud sync across devices",
                "Priority support"
            ]
        }
    }
}

// MARK: - SubscriptionState
struct SubscriptionState: Codable {
    var tier: SubscriptionTier
    var productId: String?
    var purchaseDate: Date?
    var expirationDate: Date?
    var isActive: Bool
    var lastValidated: Date?

    var isExpired: Bool {
        guard let expiration = expirationDate else { return false }
        return Date() > expiration
    }

    var daysUntilExpiration: Int? {
        guard let expiration = expirationDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expiration).day
        return days
    }

    init(tier: SubscriptionTier = .free,
         productId: String? = nil,
         purchaseDate: Date? = nil,
         expirationDate: Date? = nil,
         isActive: Bool = false,
         lastValidated: Date? = nil) {
        self.tier = tier
        self.productId = productId
        self.purchaseDate = purchaseDate
        self.expirationDate = expirationDate
        self.isActive = isActive
        self.lastValidated = lastValidated
    }
}

// MARK: - SubscriptionProduct
struct SubscriptionProduct: Identifiable {
    let id: String
    let displayName: String
    let description: String
    let price: String
    let tier: SubscriptionTier

    static let monthly = SubscriptionProduct(
        id: "com.equitylabs.premium.monthly",
        displayName: "Premium Monthly",
        description: "Unlock all premium features",
        price: "$4.99/month",
        tier: .paid
    )
}

// MARK: - ReceiptValidationRequest
struct ReceiptValidationRequest: Codable {
    let receiptData: String
    let productId: String
}

// MARK: - ReceiptValidationResponse
struct ReceiptValidationResponse: Codable {
    let isValid: Bool
    let expiresAt: String?
    let tier: SubscriptionTier
    let message: String?
}
