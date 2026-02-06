import Foundation
import Combine

// MARK: - EmptyResponse
struct EmptyResponse: Codable {}

// MARK: - PortfolioService
@MainActor
class PortfolioService: ObservableObject {
    static let shared = PortfolioService()

    private let repository = PortfolioRepository.shared
    private let stockService = StockService.shared
    private let exchangeRateService = ExchangeRateService.shared
    private let apiClient = APIClient.shared

    @Published var isLoading = false
    @Published var error: Error?

    private init() {}

    // MARK: - Load Portfolio

    /// Load portfolio with API-first approach (API is source of truth)
    func loadPortfolio() async throws -> Portfolio {
        isLoading = true
        defer { isLoading = false }

        do {
            // 1. Try to load from API first (source of truth)
            AppLogger.portfolio.info("Loading portfolio from API...")
            let apiPortfolio: Portfolio = try await apiClient.request(.portfolio)

            // 2. Save API data to Core Data (cache for offline)
            try repository.saveStocks(apiPortfolio.stocks)
            AppLogger.portfolio.info("✅ Loaded \(apiPortfolio.stocks.count) stocks from API")

            return apiPortfolio

        } catch {
            // 3. Fallback to Core Data if API fails (offline mode)
            AppLogger.portfolio.warning("⚠️ API failed, loading from cache: \(error.localizedDescription)")

            do {
                let cachedStocks = try repository.fetchAllStocks()
                AppLogger.portfolio.info("📦 Using cached data: \(cachedStocks.count) stocks")
                return Portfolio(stocks: cachedStocks)
            } catch {
                AppLogger.portfolio.error("❌ Failed to load from both API and cache")
                self.error = error
                throw error
            }
        }
    }

    // MARK: - Save Portfolio

    /// Save entire portfolio (API-first) - used for bulk operations
    func savePortfolio(_ portfolio: Portfolio) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            // 1. Save to API first (source of truth)
            AppLogger.portfolio.info("Saving entire portfolio to API...")
            let _: Portfolio = try await apiClient.upload(.savePortfolio, body: portfolio)

            // 2. Save to Core Data (local cache)
            try repository.saveStocks(portfolio.stocks)
            AppLogger.portfolio.info("✅ Portfolio saved successfully")

        } catch {
            AppLogger.portfolio.error("❌ Failed to save portfolio: \(error.localizedDescription)")
            self.error = error
            throw error
        }
    }

    // MARK: - Add Stock

    /// Add a new stock with lot to portfolio (API-first)
    func addStock(_ stock: Stock) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            // 1. Save to API first (source of truth)
            AppLogger.portfolio.info("Adding stock \(stock.symbol) to API...")
            let _: Stock = try await apiClient.upload(.addStock, body: stock)

            // 2. Save to Core Data (local cache)
            try repository.saveStock(stock)
            AppLogger.portfolio.info("✅ Added stock: \(stock.symbol)")

        } catch {
            AppLogger.portfolio.error("❌ Failed to add stock: \(error.localizedDescription)")
            self.error = error
            throw error
        }
    }

    // MARK: - Update Stock

    /// Update an existing stock (API-first)
    func updateStock(_ stock: Stock) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            // 1. Update API first (source of truth)
            AppLogger.portfolio.info("Updating stock \(stock.symbol) in API...")
            let _: Stock = try await apiClient.upload(.updateStock(symbol: stock.symbol), body: stock)

            // 2. Update Core Data (local cache)
            try repository.saveStock(stock)
            AppLogger.portfolio.info("✅ Updated stock: \(stock.symbol)")

        } catch {
            AppLogger.portfolio.error("❌ Failed to update stock: \(error.localizedDescription)")
            self.error = error
            throw error
        }
    }

    // MARK: - Delete Stock

    /// Delete a stock and all its lots (API-first)
    func deleteStock(symbol: String) async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            // 1. Delete from API first (source of truth)
            AppLogger.portfolio.info("Deleting stock \(symbol) from API...")
            try await apiClient.request(.deleteStock(symbol: symbol)) as EmptyResponse

            // 2. Delete from Core Data (local cache)
            try repository.deleteStock(symbol: symbol)
            AppLogger.portfolio.info("✅ Deleted stock: \(symbol)")

        } catch {
            AppLogger.portfolio.error("❌ Failed to delete stock: \(error.localizedDescription)")
            self.error = error
            throw error
        }
    }

    // MARK: - Refresh Prices

    /// Refresh prices for all stocks in portfolio
    func refreshPrices(for stocks: [Stock]) async throws -> [Stock] {
        isLoading = true
        defer { isLoading = false }

        do {
            let symbols = stocks.map { $0.symbol }
            let prices = try await stockService.refreshPrices(for: symbols)

            var updatedStocks: [Stock] = []

            for stock in stocks {
                if let price = prices[stock.symbol] {
                    // Update stock with new price
                    var updatedStock = stock
                    updatedStock.currentPrice = price.currentPrice
                    updatedStock.previousClose = price.previousClose
                    updatedStock.lastUpdated = price.lastUpdated

                    // Save to repository
                    try repository.updateStockPrice(
                        symbol: stock.symbol,
                        currentPrice: price.currentPrice,
                        previousClose: price.previousClose
                    )

                    updatedStocks.append(updatedStock)
                } else {
                    updatedStocks.append(stock)
                }
            }

            AppLogger.portfolio.info("Refreshed prices for \(updatedStocks.count) stocks")
            return updatedStocks
        } catch {
            AppLogger.portfolio.error("Failed to refresh prices: \(error.localizedDescription)")
            self.error = error
            throw error
        }
    }


    // MARK: - Statistics

    /// Get portfolio summary statistics
    func getPortfolioSummary(currency: Currency = .usd) async throws -> PortfolioSummary {
        let stocks = try repository.fetchAllStocks()
        let portfolio = Portfolio(stocks: stocks, currency: currency)
        return PortfolioSummary(portfolio: portfolio)
    }

    // MARK: - Currency Conversion

    /// Get portfolio value in specific currency
    func getPortfolioValue(in currency: Currency) async throws -> Double {
        let stocks = try repository.fetchAllStocks()

        // Ensure we have exchange rates
        try await exchangeRateService.fetchExchangeRates()

        var totalValue: Double = 0

        for stock in stocks {
            let stockValue = stock.lots.reduce(0) { sum, lot in
                sum + (lot.shares * (stock.currentPrice ?? lot.pricePerShare))
            }

            // Convert if stock currency differs from target
            if let stockCurrency = Currency(rawValue: stock.currency), stockCurrency != currency {
                totalValue += try await exchangeRateService.convert(amount: stockValue, from: stockCurrency, to: currency)
            } else {
                totalValue += stockValue
            }
        }

        return totalValue
    }
}
