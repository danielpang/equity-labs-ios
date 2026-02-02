import Foundation
import Combine

// MARK: - DashboardViewModel
@MainActor
class DashboardViewModel: ObservableObject {
    @Published var stocks: [Stock] = []
    @Published var summary: PortfolioSummary?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showAddStock = false
    @Published var showSettings = false

    private let portfolioService: PortfolioService
    private var cancellables = Set<AnyCancellable>()

    init(portfolioService: PortfolioService = PortfolioService.shared) {
        self.portfolioService = portfolioService
    }

    // MARK: - Load Portfolio
    func loadPortfolio() async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            // TODO: Implement in Phase 3
            // For now, return empty portfolio
            stocks = []
            updateSummary()

            AppLogger.portfolio.debug("Portfolio loaded: \(stocks.count) stocks")
        } catch {
            self.error = error
            AppLogger.portfolio.error("Failed to load portfolio: \(error.localizedDescription)")
        }
    }

    // MARK: - Refresh Prices
    func refreshPrices() async {
        // TODO: Implement in Phase 3
        AppLogger.portfolio.debug("Refreshing prices...")
        updateSummary()
    }

    // MARK: - Delete Stock
    func deleteStock(_ stock: Stock) async {
        do {
            // TODO: Implement in Phase 3
            stocks.removeAll { $0.id == stock.id }
            updateSummary()

            AppLogger.portfolio.info("Deleted stock: \(stock.symbol)")
        } catch {
            self.error = error
            AppLogger.portfolio.error("Failed to delete stock: \(error.localizedDescription)")
        }
    }

    // MARK: - Update Summary
    private func updateSummary() {
        let portfolio = Portfolio(stocks: stocks)
        summary = PortfolioSummary(portfolio: portfolio)
    }
}
