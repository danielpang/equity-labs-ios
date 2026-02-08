import Foundation
import Combine

// MARK: - SettingsViewModel
@MainActor
class SettingsViewModel: ObservableObject {
    @Published var preferences: UserPreferences
    @Published var isSyncing = false
    @Published var error: Error?

    private let apiClient = APIClient.shared
    private let authManager = AuthManager.shared

    init() {
        self.preferences = SettingsViewModel.loadLocalPreferences()
    }

    // MARK: - Load Preferences

    /// Load server-synced preferences (currency, sortBy) from API, merge with local settings.
    func loadPreferences() async {
        do {
            let remote: UserPreferences = try await apiClient.request(.preferences)
            preferences.currency = remote.currency
            preferences.sortBy = remote.sortBy
            saveLocally(preferences)
            AppLogger.settings.info("Loaded preferences from API")
        } catch {
            AppLogger.settings.warning("Failed to load remote preferences, using local: \(error.localizedDescription)")
        }
    }

    // MARK: - Server-Synced Preferences

    func setCurrency(_ currency: Currency) {
        preferences.currency = currency
        saveLocally(preferences)
        syncToBackend(PreferencesUpdate(currency: currency.rawValue, sortBy: nil))
    }

    func setSortBy(_ sortBy: SortBy) {
        preferences.sortBy = sortBy
        saveLocally(preferences)
        syncToBackend(PreferencesUpdate(currency: nil, sortBy: sortBy.rawValue))
    }

    // MARK: - Local-Only Preferences

    func setNotifications(_ enabled: Bool) {
        preferences.enableNotifications = enabled
        saveLocally(preferences)
    }

    func setBackgroundRefresh(_ enabled: Bool) {
        preferences.enableBackgroundRefresh = enabled
        saveLocally(preferences)
    }

    func setChartTimeRange(_ range: TimeRange) {
        preferences.chartDefaultTimeRange = range
        saveLocally(preferences)
    }

    // MARK: - Sign Out

    func signOut() async {
        await authManager.signOut()
    }

    // MARK: - Sync to Backend

    private func syncToBackend(_ update: PreferencesUpdate) {
        Task {
            isSyncing = true
            defer { isSyncing = false }

            do {
                try await apiClient.uploadWithoutResponse(.updatePreferences, body: update)
                AppLogger.settings.debug("Preference synced to backend")
            } catch {
                AppLogger.settings.warning("Failed to sync preference, queued for retry: \(error.localizedDescription)")
                queueOfflineUpdate(update)
            }
        }
    }

    /// Replay any queued preference updates from offline sessions.
    func replayOfflineUpdates() async {
        let queue = loadOfflineQueue()
        guard !queue.isEmpty else { return }

        AppLogger.settings.info("Replaying \(queue.count) offline preference updates...")
        var remaining: [PreferencesUpdate] = []

        for update in queue {
            do {
                try await apiClient.uploadWithoutResponse(.updatePreferences, body: update)
            } catch {
                remaining.append(update)
            }
        }

        saveOfflineQueue(remaining)
    }

    // MARK: - Local Persistence (UserDefaults)

    static func loadLocalPreferences() -> UserPreferences {
        let defaults = UserDefaults.standard
        let currency = Currency(rawValue: defaults.string(forKey: Constants.UserDefaultsKeys.currency) ?? "") ?? .usd
        let sortBy = SortBy(rawValue: defaults.string(forKey: Constants.UserDefaultsKeys.sortBy) ?? "") ?? .alphabetical
        let notifications = defaults.object(forKey: Constants.UserDefaultsKeys.enableNotifications) as? Bool ?? true
        let backgroundRefresh = defaults.object(forKey: Constants.UserDefaultsKeys.enableBackgroundRefresh) as? Bool ?? true
        let timeRange = TimeRange(rawValue: defaults.string(forKey: Constants.UserDefaultsKeys.chartDefaultTimeRange) ?? "") ?? .oneMonth

        return UserPreferences(
            currency: currency,
            sortBy: sortBy,
            enableNotifications: notifications,
            enableBackgroundRefresh: backgroundRefresh,
            chartDefaultTimeRange: timeRange
        )
    }

    private func saveLocally(_ prefs: UserPreferences) {
        let defaults = UserDefaults.standard
        defaults.set(prefs.currency.rawValue, forKey: Constants.UserDefaultsKeys.currency)
        defaults.set(prefs.sortBy.rawValue, forKey: Constants.UserDefaultsKeys.sortBy)
        defaults.set(prefs.enableNotifications, forKey: Constants.UserDefaultsKeys.enableNotifications)
        defaults.set(prefs.enableBackgroundRefresh, forKey: Constants.UserDefaultsKeys.enableBackgroundRefresh)
        defaults.set(prefs.chartDefaultTimeRange.rawValue, forKey: Constants.UserDefaultsKeys.chartDefaultTimeRange)
    }

    // MARK: - Offline Queue

    private let offlineQueueKey = "pending_preferences_queue"

    private func queueOfflineUpdate(_ update: PreferencesUpdate) {
        var queue = loadOfflineQueue()
        queue.append(update)
        saveOfflineQueue(queue)
    }

    private func loadOfflineQueue() -> [PreferencesUpdate] {
        guard let data = UserDefaults.standard.data(forKey: offlineQueueKey),
              let queue = try? JSONDecoder().decode([PreferencesUpdate].self, from: data) else {
            return []
        }
        return queue
    }

    private func saveOfflineQueue(_ queue: [PreferencesUpdate]) {
        if queue.isEmpty {
            UserDefaults.standard.removeObject(forKey: offlineQueueKey)
        } else if let data = try? JSONEncoder().encode(queue) {
            UserDefaults.standard.set(data, forKey: offlineQueueKey)
        }
    }
}
