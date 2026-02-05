import Foundation
import SwiftUI
import Combine

// MARK: - StockDetailViewModel
@MainActor
class StockDetailViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var stock: Stock
    @Published var historicalData: [HistoricalDataPoint] = []
    @Published var selectedTimeRange: TimeRange = .oneMonth
    @Published var selectedTab: DetailTab = .overview
    @Published var newsArticles: [NewsArticle] = []

    @Published var isLoading = false
    @Published var isLoadingHistory = false
    @Published var isLoadingNews = false
    @Published var error: Error?

    // MARK: - Services

    private let stockService: StockService
    private let portfolioService: PortfolioService
    private let newsService: NewsService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(stock: Stock,
         stockService: StockService = StockService.shared,
         portfolioService: PortfolioService = PortfolioService.shared,
         newsService: NewsService = NewsService.shared) {
        self.stock = stock
        self.stockService = stockService
        self.portfolioService = portfolioService
        self.newsService = newsService
    }

    // MARK: - Load Data

    func loadData() async {
        await loadStockDetails()
        await loadHistoricalData()
        await loadNews()
    }

    func loadStockDetails() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let detailedStock = try await stockService.fetchStockDetail(symbol: stock.symbol)

            // Update current prices
            self.stock.currentPrice = detailedStock.currentPrice
            self.stock.previousClose = detailedStock.previousClose
            self.stock.lastUpdated = Date()

            AppLogger.portfolio.info("Loaded details for \(stock.symbol)")
        } catch {
            AppLogger.portfolio.error("Failed to load stock details: \(error.localizedDescription)")
            self.error = error
        }
    }

    func loadHistoricalData() async {
        isLoadingHistory = true
        defer { isLoadingHistory = false }

        do {
            let data = try await stockService.fetchHistoricalData(
                symbol: stock.symbol,
                range: selectedTimeRange
            )
            self.historicalData = data

            AppLogger.portfolio.debug("Loaded \(data.count) historical points for \(stock.symbol)")
        } catch {
            AppLogger.portfolio.error("Failed to load historical data: \(error.localizedDescription)")
            // Don't set error for historical data failure
        }
    }

    func loadNews() async {
        isLoadingNews = true
        defer { isLoadingNews = false }

        do {
            let articles = try await newsService.fetchNews(for: stock.symbol, count: 10)
            self.newsArticles = articles

            AppLogger.portfolio.debug("Loaded \(articles.count) news articles for \(stock.symbol)")
        } catch {
            AppLogger.portfolio.error("Failed to load news: \(error.localizedDescription)")
            // Don't set error for news failure
        }
    }

    // MARK: - Refresh

    func refreshPrice() async {
        do {
            let price = try await stockService.refreshPrice(for: stock.symbol)

            self.stock.currentPrice = price.currentPrice
            self.stock.previousClose = price.previousClose
            self.stock.lastUpdated = price.lastUpdated

            AppLogger.portfolio.info("Refreshed price for \(stock.symbol)")
        } catch {
            AppLogger.portfolio.error("Failed to refresh price: \(error.localizedDescription)")
            self.error = error
        }
    }

    // MARK: - Time Range Selection

    func changeTimeRange(_ range: TimeRange) async {
        selectedTimeRange = range
        await loadHistoricalData()
    }

    // MARK: - Lot Management

    func addLot(_ lot: StockLot) async {
        var updatedStock = stock
        updatedStock.lots.append(lot)

        do {
            try await portfolioService.updateStock(updatedStock)
            self.stock = updatedStock

            AppLogger.portfolio.info("Added lot to \(stock.symbol)")
        } catch {
            AppLogger.portfolio.error("Failed to add lot: \(error.localizedDescription)")
            self.error = error
        }
    }

    func updateLot(_ lot: StockLot) async {
        var updatedStock = stock

        if let index = updatedStock.lots.firstIndex(where: { $0.id == lot.id }) {
            updatedStock.lots[index] = lot

            do {
                try await portfolioService.updateStock(updatedStock)
                self.stock = updatedStock

                AppLogger.portfolio.info("Updated lot in \(stock.symbol)")
            } catch {
                AppLogger.portfolio.error("Failed to update lot: \(error.localizedDescription)")
                self.error = error
            }
        }
    }

    func deleteLot(_ lot: StockLot) async {
        var updatedStock = stock
        updatedStock.lots.removeAll { $0.id == lot.id }

        do {
            try await portfolioService.updateStock(updatedStock)
            self.stock = updatedStock

            AppLogger.portfolio.info("Deleted lot from \(stock.symbol)")
        } catch {
            AppLogger.portfolio.error("Failed to delete lot: \(error.localizedDescription)")
            self.error = error
        }
    }

    // MARK: - Computed Properties

    var currentPrice: Double {
        stock.currentPrice ?? stock.averageCost
    }

    var priceChange: Double? {
        stock.dayChange
    }

    var priceChangePercent: Double? {
        stock.dayChangePercentage
    }

    var totalValue: Double {
        stock.currentValue
    }

    var totalCost: Double {
        stock.totalCost
    }

    var gainLoss: Double {
        stock.profitLoss
    }

    var gainLossPercent: Double {
        stock.profitLossPercentage
    }

    var averageCost: Double {
        stock.averageCost
    }

    var totalShares: Double {
        stock.totalShares
    }

    var hasMultipleLots: Bool {
        stock.lots.count > 1
    }

    var hasNews: Bool {
        !newsArticles.isEmpty
    }

    // MARK: - Formatting

    func formatPrice(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = stock.currency
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    func formatPercent(_ value: Double) -> String {
        String(format: "%+.2f%%", value)
    }

    func formatShares(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 4
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}

// MARK: - DetailTab

enum DetailTab: String, CaseIterable {
    case overview = "Overview"
    case lots = "Lots"
    case news = "News"
}

