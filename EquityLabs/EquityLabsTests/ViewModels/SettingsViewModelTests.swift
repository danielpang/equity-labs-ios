import XCTest
@testable import EquityLabs

final class SettingsViewModelTests: XCTestCase {

    // MARK: - Initial State

    @MainActor
    func testInitialState() {
        let vm = SettingsViewModel()
        XCTAssertFalse(vm.isSyncing)
        XCTAssertNil(vm.error)
    }

    // MARK: - Currency

    @MainActor
    func testSetCurrency() {
        let vm = SettingsViewModel()
        vm.setCurrency(.cad)
        XCTAssertEqual(vm.preferences.currency, .cad)

        vm.setCurrency(.usd)
        XCTAssertEqual(vm.preferences.currency, .usd)
    }

    @MainActor
    func testCurrencyPersistsToUserDefaults() {
        let vm = SettingsViewModel()
        vm.setCurrency(.cad)

        let stored = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.currency)
        XCTAssertEqual(stored, Currency.cad.rawValue)
    }

    // MARK: - Notifications

    @MainActor
    func testSetNotifications() {
        let vm = SettingsViewModel()
        vm.setNotifications(false)
        XCTAssertFalse(vm.preferences.enableNotifications)

        vm.setNotifications(true)
        XCTAssertTrue(vm.preferences.enableNotifications)
    }

    @MainActor
    func testNotificationsPersistsToUserDefaults() {
        let vm = SettingsViewModel()
        vm.setNotifications(false)

        let stored = UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.enableNotifications)
        XCTAssertFalse(stored)
    }

    // MARK: - Background Refresh

    @MainActor
    func testSetBackgroundRefresh() {
        let vm = SettingsViewModel()
        vm.setBackgroundRefresh(false)
        XCTAssertFalse(vm.preferences.enableBackgroundRefresh)

        vm.setBackgroundRefresh(true)
        XCTAssertTrue(vm.preferences.enableBackgroundRefresh)
    }

    @MainActor
    func testBackgroundRefreshPersistsToUserDefaults() {
        let vm = SettingsViewModel()
        vm.setBackgroundRefresh(false)

        let stored = UserDefaults.standard.bool(forKey: Constants.UserDefaultsKeys.enableBackgroundRefresh)
        XCTAssertFalse(stored)
    }

    // MARK: - Chart Time Range

    @MainActor
    func testSetChartTimeRange() {
        let vm = SettingsViewModel()
        vm.setChartTimeRange(.oneYear)
        XCTAssertEqual(vm.preferences.chartDefaultTimeRange, .oneYear)

        vm.setChartTimeRange(.oneWeek)
        XCTAssertEqual(vm.preferences.chartDefaultTimeRange, .oneWeek)
    }

    @MainActor
    func testChartTimeRangePersistsToUserDefaults() {
        let vm = SettingsViewModel()
        vm.setChartTimeRange(.threeMonths)

        let stored = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.chartDefaultTimeRange)
        XCTAssertEqual(stored, TimeRange.threeMonths.rawValue)
    }

    // MARK: - Sort By

    @MainActor
    func testSetSortBy() {
        let vm = SettingsViewModel()
        vm.setSortBy(.lastUpdated)
        XCTAssertEqual(vm.preferences.sortBy, .lastUpdated)

        vm.setSortBy(.alphabetical)
        XCTAssertEqual(vm.preferences.sortBy, .alphabetical)
    }

    @MainActor
    func testSortByPersistsToUserDefaults() {
        let vm = SettingsViewModel()
        vm.setSortBy(.lastUpdated)

        let stored = UserDefaults.standard.string(forKey: Constants.UserDefaultsKeys.sortBy)
        XCTAssertEqual(stored, SortBy.lastUpdated.rawValue)
    }

    // MARK: - Local Preferences Roundtrip

    @MainActor
    func testPreferencesLoadFromUserDefaults() {
        // Set values directly in UserDefaults
        UserDefaults.standard.set(Currency.cad.rawValue, forKey: Constants.UserDefaultsKeys.currency)
        UserDefaults.standard.set(SortBy.lastUpdated.rawValue, forKey: Constants.UserDefaultsKeys.sortBy)
        UserDefaults.standard.set(false, forKey: Constants.UserDefaultsKeys.enableNotifications)
        UserDefaults.standard.set(false, forKey: Constants.UserDefaultsKeys.enableBackgroundRefresh)
        UserDefaults.standard.set(TimeRange.sixMonths.rawValue, forKey: Constants.UserDefaultsKeys.chartDefaultTimeRange)

        // New ViewModel should pick them up
        let vm = SettingsViewModel()
        XCTAssertEqual(vm.preferences.currency, .cad)
        XCTAssertEqual(vm.preferences.sortBy, .lastUpdated)
        XCTAssertFalse(vm.preferences.enableNotifications)
        XCTAssertFalse(vm.preferences.enableBackgroundRefresh)
        XCTAssertEqual(vm.preferences.chartDefaultTimeRange, .sixMonths)
    }
}
