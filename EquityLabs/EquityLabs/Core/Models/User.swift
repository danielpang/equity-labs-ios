import Foundation

// MARK: - User
struct User: Codable, Identifiable {
    let id: String
    let email: String?
    let firstName: String?
    let lastName: String?
    let profileImageUrl: String?
    var preferences: UserPreferences
    var subscription: SubscriptionState

    var displayName: String {
        if let first = firstName, let last = lastName {
            return "\(first) \(last)"
        } else if let first = firstName {
            return first
        } else if let email = email {
            return email
        } else {
            return "User"
        }
    }

    var initials: String {
        let first = firstName?.prefix(1).uppercased() ?? ""
        let last = lastName?.prefix(1).uppercased() ?? ""
        return "\(first)\(last)"
    }

    init(id: String,
         email: String? = nil,
         firstName: String? = nil,
         lastName: String? = nil,
         profileImageUrl: String? = nil,
         preferences: UserPreferences = UserPreferences(),
         subscription: SubscriptionState = SubscriptionState()) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.profileImageUrl = profileImageUrl
        self.preferences = preferences
        self.subscription = subscription
    }
}

// MARK: - SortBy
enum SortBy: String, Codable, CaseIterable {
    case alphabetical
    case lastUpdated

    var displayName: String {
        switch self {
        case .alphabetical: return "Alphabetical"
        case .lastUpdated: return "Last Updated"
        }
    }
}

// MARK: - UserPreferences
struct UserPreferences: Codable {
    var currency: Currency
    var sortBy: SortBy
    var enableNotifications: Bool
    var enableBackgroundRefresh: Bool
    var chartDefaultTimeRange: TimeRange

    init(currency: Currency = .usd,
         sortBy: SortBy = .alphabetical,
         enableNotifications: Bool = true,
         enableBackgroundRefresh: Bool = true,
         chartDefaultTimeRange: TimeRange = .oneMonth) {
        self.currency = currency
        self.sortBy = sortBy
        self.enableNotifications = enableNotifications
        self.enableBackgroundRefresh = enableBackgroundRefresh
        self.chartDefaultTimeRange = chartDefaultTimeRange
    }
}

// MARK: - PreferencesUpdate
/// Currency and sortBy are synced to the backend API.
/// Other preferences (notifications, background refresh, chart range) are local-only.
struct PreferencesUpdate: Codable {
    let currency: String?
    let sortBy: String?
}
