import Foundation

// MARK: - Portfolio
struct Portfolio: Codable {
    var stocks: [Stock]
    var lastSynced: Date?
    var currency: Currency

    var totalValue: Double {
        stocks.reduce(0) { $0 + $1.currentValue }
    }

    var totalCost: Double {
        stocks.reduce(0) { $0 + $1.totalCost }
    }

    var totalProfitLoss: Double {
        totalValue - totalCost
    }

    var totalProfitLossPercentage: Double {
        guard totalCost > 0 else { return 0 }
        return (totalProfitLoss / totalCost) * 100
    }

    var totalDayChange: Double? {
        let changes = stocks.compactMap { stock -> Double? in
            guard let dayChange = stock.dayChange else { return nil }
            return dayChange * stock.totalShares
        }
        guard !changes.isEmpty else { return nil }
        return changes.reduce(0, +)
    }

    var totalDayChangePercentage: Double? {
        guard let dayChange = totalDayChange, totalValue > 0 else { return nil }
        let previousValue = totalValue - dayChange
        guard previousValue > 0 else { return nil }
        return (dayChange / previousValue) * 100
    }

    init(stocks: [Stock] = [], lastSynced: Date? = nil, currency: Currency = .usd) {
        self.stocks = stocks
        self.lastSynced = lastSynced
        self.currency = currency
    }

    // MARK: - Custom Codable

    enum CodingKeys: String, CodingKey {
        case stocks, lastSynced, currency
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode stocks - handle both array and dictionary formats
        if let stocksArray = try? container.decode([Stock].self, forKey: .stocks) {
            // API returns array format: { "stocks": [...] }
            self.stocks = stocksArray
        } else if let stocksDict = try? container.decode([String: Stock].self, forKey: .stocks) {
            // API returns dictionary format: { "stocks": { "id1": {...}, "id2": {...} } }
            self.stocks = Array(stocksDict.values)
        } else {
            // Fallback to empty array
            self.stocks = []
        }

        self.lastSynced = try container.decodeIfPresent(Date.self, forKey: .lastSynced)
        self.currency = (try? container.decode(Currency.self, forKey: .currency)) ?? .usd
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(stocks, forKey: .stocks)
        try container.encodeIfPresent(lastSynced, forKey: .lastSynced)
        try container.encode(currency, forKey: .currency)
    }
}

// MARK: - PortfolioSummary
struct PortfolioSummary: Codable {
    let totalValue: Double
    let totalCost: Double
    let totalProfitLoss: Double
    let totalProfitLossPercentage: Double
    let totalDayChange: Double?
    let totalDayChangePercentage: Double?
    let stockCount: Int
    let currency: Currency
    let lastUpdated: Date

    init(portfolio: Portfolio) {
        self.totalValue = portfolio.totalValue
        self.totalCost = portfolio.totalCost
        self.totalProfitLoss = portfolio.totalProfitLoss
        self.totalProfitLossPercentage = portfolio.totalProfitLossPercentage
        self.totalDayChange = portfolio.totalDayChange
        self.totalDayChangePercentage = portfolio.totalDayChangePercentage
        self.stockCount = portfolio.stocks.count
        self.currency = portfolio.currency
        self.lastUpdated = Date()
    }
}

// MARK: - Currency
enum Currency: String, Codable, CaseIterable {
    case usd = "USD"
    case cad = "CAD"

    var symbol: String {
        switch self {
        case .usd: return "$"
        case .cad: return "C$"
        }
    }

    var name: String {
        switch self {
        case .usd: return "US Dollar"
        case .cad: return "Canadian Dollar"
        }
    }
}

// MARK: - PortfolioUpdate
struct PortfolioUpdate: Codable {
    let stocks: [String: StockData]

    struct StockData: Codable {
        let symbol: String
        let name: String
        let lots: [LotData]
    }

    struct LotData: Codable {
        let shares: Double
        let pricePerShare: Double
        let purchaseDate: String
        let currency: String
        let notes: String?
    }
}
