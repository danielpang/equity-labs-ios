import Foundation
import Combine

// MARK: - StockService
/// Service for fetching stock data from API
@MainActor
class StockService: ObservableObject {
    static let shared = StockService()

    private let apiClient = APIClient.shared
    private var searchCancellable: AnyCancellable?

    @Published var isLoading = false
    @Published var error: Error?

    private init() {}

    // MARK: - Stock Detail

    /// Fetch detailed stock information
    func fetchStockDetail(symbol: String) async throws -> Stock {
        isLoading = true
        defer { isLoading = false }

        do {
            let response: StockDetailResponse = try await apiClient.request(.stockDetail(symbol: symbol))
            AppLogger.portfolio.info("Fetched stock detail for \(symbol)")
            return response.toStock(defaultSymbol: symbol, defaultName: symbol)
        } catch {
            AppLogger.portfolio.error("Failed to fetch stock detail: \(error.localizedDescription)")

            // If API fails, create a basic stock with the symbol
            // This allows adding stocks even if the detail endpoint fails
            AppLogger.portfolio.warning("Creating basic stock for \(symbol) due to API error")
            return Stock(
                symbol: symbol,
                name: symbol,
                lots: [],
                currency: "USD"
            )
        }
    }

    // MARK: - Stock Search

    /// Search for stocks by query string
    func searchStocks(query: String) async throws -> [StockSearchResult] {
        guard !query.isEmpty else {
            return []
        }

        do {
            // API returns array directly, not wrapped in response object
            let results: [StockSearchResult] = try await apiClient.request(.stockSearch(query: query))
            AppLogger.portfolio.debug("Found \(results.count) stocks for query: \(query)")
            return results
        } catch {
            AppLogger.portfolio.error("Stock search failed: \(error.localizedDescription)")
            self.error = error
            throw error
        }
    }

    /// Search with debouncing (call this from UI with reactive binding)
    func debouncedSearch(query: String, delay: TimeInterval = 0.3) -> AnyPublisher<[StockSearchResult], Never> {
        Just(query)
            .delay(for: .seconds(delay), scheduler: DispatchQueue.main)
            .flatMap { [weak self] searchQuery -> AnyPublisher<[StockSearchResult], Never> in
                guard let self = self, !searchQuery.isEmpty else {
                    return Just([]).eraseToAnyPublisher()
                }

                return Future { promise in
                    Task {
                        do {
                            let results = try await self.searchStocks(query: searchQuery)
                            promise(.success(results))
                        } catch {
                            promise(.success([]))
                        }
                    }
                }
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    // MARK: - Price Updates

    /// Refresh current prices for multiple stocks
    func refreshPrices(for symbols: [String]) async throws -> [String: StockPrice] {
        isLoading = true
        defer { isLoading = false }

        var prices: [String: StockPrice] = [:]

        // Fetch prices concurrently
        try await withThrowingTaskGroup(of: (String, StockPrice).self) { group in
            for symbol in symbols {
                group.addTask {
                    let stock = try await self.fetchStockDetail(symbol: symbol)
                    let price = StockPrice(
                        symbol: symbol,
                        currentPrice: stock.currentPrice ?? 0,
                        previousClose: stock.previousClose ?? 0,
                        lastUpdated: Date()
                    )
                    return (symbol, price)
                }
            }

            for try await (symbol, price) in group {
                prices[symbol] = price
            }
        }

        AppLogger.portfolio.info("Refreshed prices for \(prices.count) stocks")
        return prices
    }

    /// Refresh price for a single stock
    func refreshPrice(for symbol: String) async throws -> StockPrice {
        let stock = try await fetchStockDetail(symbol: symbol)
        return StockPrice(
            symbol: symbol,
            currentPrice: stock.currentPrice ?? 0,
            previousClose: stock.previousClose ?? 0,
            lastUpdated: Date()
        )
    }

    // MARK: - Historical Data

    /// Fetch historical price data from the stock detail endpoint
    func fetchHistoricalData(symbol: String, range: TimeRange) async throws -> [HistoricalDataPoint] {
        do {
            let response: StockDetailWithHistoryResponse = try await apiClient.request(
                .stockDetail(symbol: symbol)
            )

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")

            let cutoffDate = Calendar.current.date(
                byAdding: .day, value: -range.days, to: Date()
            ) ?? Date()

            let points = (response.history ?? []).compactMap { item -> HistoricalDataPoint? in
                guard let date = dateFormatter.date(from: item.date) else {
                    return nil
                }
                guard date >= cutoffDate else { return nil }
                return HistoricalDataPoint(
                    date: date,
                    open: item.price,
                    high: item.price,
                    low: item.price,
                    close: item.price,
                    volume: 0
                )
            }

            AppLogger.portfolio.info("Fetched \(points.count) historical data points for \(symbol) (range: \(range.rawValue))")
            return points
        } catch {
            AppLogger.portfolio.error("Failed to fetch historical data for \(symbol): \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Batch Operations

    /// Fetch details for multiple stocks
    func fetchStocks(symbols: [String]) async throws -> [Stock] {
        var stocks: [Stock] = []

        try await withThrowingTaskGroup(of: Stock.self) { group in
            for symbol in symbols {
                group.addTask {
                    try await self.fetchStockDetail(symbol: symbol)
                }
            }

            for try await stock in group {
                stocks.append(stock)
            }
        }

        AppLogger.portfolio.info("Fetched \(stocks.count) stocks")
        return stocks
    }
}

// MARK: - Supporting Models

/// Stock price information
struct StockPrice: Codable {
    let symbol: String
    let currentPrice: Double
    let previousClose: Double
    let lastUpdated: Date

    var change: Double {
        currentPrice - previousClose
    }

    var changePercent: Double {
        guard previousClose > 0 else { return 0 }
        return (change / previousClose) * 100
    }
}

/// API Response models
private struct StockDetailResponse: Codable {
    let symbol: String?
    let name: String?
    let currency: String?
    let currentPrice: Double?
    let previousClose: Double?
    let exchange: String?
    let marketCap: Double?
    let price: Double? // Alternative field name
    let close: Double? // Alternative field name

    // Support alternative field names
    enum CodingKeys: String, CodingKey {
        case symbol
        case name
        case currency
        case currentPrice
        case previousClose
        case exchange
        case marketCap
        case price
        case close
    }

    func toStock(defaultSymbol: String, defaultName: String) -> Stock {
        Stock(
            id: UUID().uuidString,
            symbol: symbol ?? defaultSymbol,
            name: name ?? defaultName,
            lots: [],
            currentPrice: currentPrice ?? price,
            previousClose: previousClose ?? close,
            currency: currency ?? "USD",
            lastUpdated: Date()
        )
    }
}

// StockSearchResponse removed - API returns array directly

/// Response from stock detail endpoint that includes history
private struct StockDetailWithHistoryResponse: Codable {
    let history: [HistoryItemDTO]?
}

private struct HistoryItemDTO: Codable {
    let date: String
    let price: Double
}
