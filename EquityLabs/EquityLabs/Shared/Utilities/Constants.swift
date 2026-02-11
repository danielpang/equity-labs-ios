import Foundation

// MARK: - Constants
enum Constants {
    // MARK: - API
    enum API {
        static let baseURL = "https://equitylabs.app"
        static let timeout: TimeInterval = 30
        static let maxRetries = 3
    }

    // MARK: - App
    enum App {
        static let bundleId = "com.equitylabs.ios"
        static let appName = "EquityLabs"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    // MARK: - Subscription
    enum Subscription {
        static let monthlyProductId = "equitylabs.premium.monthly"
        static let freeStockLimit = 5
    }

    // MARK: - Cache
    enum Cache {
        static let newsCacheDuration: TimeInterval = 6 * 60 * 60 // 6 hours
        static let priceCacheDuration: TimeInterval = 5 * 60 // 5 minutes
    }

    // MARK: - Background
    enum Background {
        static let refreshTaskId = "com.equitylabs.refresh"
        static let syncTaskId = "com.equitylabs.sync"
        static let refreshInterval: TimeInterval = 15 * 60 // 15 minutes
    }

    // MARK: - UserDefaults Keys
    enum UserDefaultsKeys {
        static let currency = "user_currency"
        static let sortBy = "sort_by"
        static let enableNotifications = "enable_notifications"
        static let enableBackgroundRefresh = "enable_background_refresh"
        static let chartDefaultTimeRange = "chart_default_time_range"
        static let lastSyncDate = "last_sync_date"
        static let hasCompletedOnboarding = "has_completed_onboarding"
        static let appearanceMode = "appearance_mode"
    }

    // MARK: - Clerk
    enum Clerk {
        // TODO: Replace with your Clerk publishable key from dashboard
        // Get from: https://dashboard.clerk.com -> API Keys
        static let publishableKey: String? = ProcessInfo.processInfo.environment["CLERK_PUBLISHABLE_KEY"]
            ?? Bundle.main.infoDictionary?["CLERK_PUBLISHABLE_KEY"] as? String
    }

    // MARK: - Keychain Keys
    enum KeychainKeys {
        static let authToken = "auth_token"
        static let userId = "user_id"
        static let refreshToken = "refresh_token"
    }

    // MARK: - URLs
    enum URLs {
        static let privacyPolicy = "https://equitylabs.com/privacy"
        static let termsOfService = "https://equitylabs.com/terms"
        static let support = "https://equitylabs.com/support"
        static let website = "https://equitylabs.com"
    }

    // MARK: - Animations
    enum Animation {
        static let standard: Double = 0.3
        static let fast: Double = 0.15
        static let slow: Double = 0.5
    }

    // MARK: - Layout
    enum Layout {
        static let cornerRadius: CGFloat = 12
        static let glassCornerRadius: CGFloat = 20
        static let cardPadding: CGFloat = 16
        static let spacing: CGFloat = 12
        static let iconSize: CGFloat = 24
    }
}
