import Foundation
import Combine

// MARK: - DashboardViewModel
@MainActor
class DashboardViewModel: ObservableObject {
    @Published var stocks: [Stock] = []
    @Published var summary: PortfolioSummary?
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var error: Error?
    @Published var showAddStock = false
    @Published var showSettings = false
    @Published var selectedCurrency: Currency = .usd
    @Published var sortBy: SortBy = .alphabetical

    private let portfolioService: PortfolioService
    private let subscriptionManager: SubscriptionManager
    private var cancellables = Set<AnyCancellable>()

    init(portfolioService: PortfolioService = PortfolioService.shared,
         subscriptionManager: SubscriptionManager = SubscriptionManager.shared) {
        self.portfolioService = portfolioService
        self.subscriptionManager = subscriptionManager
        self.sortBy = SettingsViewModel.loadLocalPreferences().sortBy

        observePortfolioService()
    }

    // MARK: - Load Portfolio

    func loadPortfolio() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let portfolio = try await portfolioService.loadPortfolio()
            self.stocks = portfolio.stocks
            self.selectedCurrency = portfolio.currency
            updateSummary()

            AppLogger.portfolio.debug("Portfolio loaded: \(stocks.count) stocks")
        } catch {
            self.error = error
            AppLogger.portfolio.error("Failed to load portfolio: \(error.localizedDescription)")
        }
    }

    // MARK: - Refresh Prices

    func refreshPrices() async {
        isRefreshing = true
        error = nil
        defer { isRefreshing = false }

        do {
            let portfolio = try await portfolioService.loadPortfolio()
            self.stocks = portfolio.stocks
            self.selectedCurrency = portfolio.currency
            updateSummary()

            AppLogger.portfolio.info("Refreshed portfolio: \(stocks.count) stocks")
        } catch {
            self.error = error
            AppLogger.portfolio.error("Failed to refresh portfolio: \(error.localizedDescription)")
        }
    }

    // MARK: - Delete Stock

    func deleteStock(_ stock: Stock) async {
        do {
            // Delete from service
            try await portfolioService.deleteStock(symbol: stock.symbol)

            // Remove from local array
            stocks.removeAll { $0.id == stock.id }
            updateSummary()

            AppLogger.portfolio.info("Deleted stock: \(stock.symbol)")
        } catch {
            self.error = error
            AppLogger.portfolio.error("Failed to delete stock: \(error.localizedDescription)")
        }
    }

    // MARK: - Delete Stock at Index (for swipe actions)

    func deleteStock(at indexSet: IndexSet) async {
        for index in indexSet {
            let stock = stocks[index]
            await deleteStock(stock)
        }
    }

    // MARK: - Add Stock

    func addStockCompleted() async {
        // Reload portfolio after adding a stock
        await loadPortfolio()
    }

    // MARK: - Check Stock Limit

    var canAddStock: Bool {
        subscriptionManager.canAddStock(currentCount: stocks.count)
    }

    var stocksRemaining: Int? {
        subscriptionManager.stocksRemaining(currentCount: stocks.count)
    }

    var isAtStockLimit: Bool {
        guard let remaining = stocksRemaining else { return false }
        return remaining == 0
    }

    // MARK: - Sorting

    var sortedStocks: [Stock] {
        switch sortBy {
        case .alphabetical:
            return stocks.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .lastUpdated:
            return stocks.sorted { ($0.lastUpdated ?? .distantPast) > ($1.lastUpdated ?? .distantPast) }
        }
    }

    func reloadSortPreference() {
        sortBy = SettingsViewModel.loadLocalPreferences().sortBy
    }

    // MARK: - Update Summary

    private func updateSummary() {
        let portfolio = Portfolio(stocks: stocks, currency: selectedCurrency)
        summary = PortfolioSummary(portfolio: portfolio)
    }

    // MARK: - Currency Toggle

    func toggleCurrency() {
        selectedCurrency = (selectedCurrency == .usd) ? .cad : .usd
        updateSummary()
    }

    // MARK: - Observe Service

    private func observePortfolioService() {
        // Observe loading state
        portfolioService.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] loading in
                if !loading {
                    // Service finished loading, we might want to refresh UI
                }
            }
            .store(in: &cancellables)

        // Observe errors
        portfolioService.$error
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.error = error
            }
            .store(in: &cancellables)
    }

    // MARK: - Computed Properties

    var hasStocks: Bool {
        !stocks.isEmpty
    }

    var totalValue: Double {
        summary?.totalValue ?? 0
    }

    var totalGainLoss: Double {
        summary?.totalProfitLoss ?? 0
    }

    var totalGainLossPercent: Double {
        summary?.totalProfitLossPercentage ?? 0
    }

    var formattedTotalValue: String {
        formatCurrency(totalValue)
    }

    var formattedTotalGainLoss: String {
        formatCurrency(totalGainLoss)
    }

    var gainLossColor: String {
        totalGainLoss >= 0 ? "green" : "red"
    }

    // MARK: - Formatting Helpers

    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = selectedCurrency.rawValue
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    func formatPercent(_ value: Double) -> String {
        String(format: "%.2f%%", value)
    }
}
