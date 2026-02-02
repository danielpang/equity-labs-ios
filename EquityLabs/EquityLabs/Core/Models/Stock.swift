import Foundation

// MARK: - Stock
struct Stock: Codable, Identifiable, Hashable {
    let id: String
    let symbol: String
    let name: String
    var lots: [StockLot]
    var currentPrice: Double?
    var previousClose: Double?
    var currency: String
    var lastUpdated: Date?

    // Computed properties
    var totalShares: Double {
        lots.reduce(0) { $0 + $1.shares }
    }

    var totalCost: Double {
        lots.reduce(0) { $0 + ($1.shares * $1.pricePerShare) }
    }

    var averageCost: Double {
        guard totalShares > 0 else { return 0 }
        return totalCost / totalShares
    }

    var currentValue: Double {
        guard let price = currentPrice else { return 0 }
        return totalShares * price
    }

    var profitLoss: Double {
        currentValue - totalCost
    }

    var profitLossPercentage: Double {
        guard totalCost > 0 else { return 0 }
        return (profitLoss / totalCost) * 100
    }

    var dayChange: Double? {
        guard let current = currentPrice, let previous = previousClose else { return nil }
        return current - previous
    }

    var dayChangePercentage: Double? {
        guard let previous = previousClose, previous > 0, let change = dayChange else { return nil }
        return (change / previous) * 100
    }

    init(id: String = UUID().uuidString,
         symbol: String,
         name: String,
         lots: [StockLot] = [],
         currentPrice: Double? = nil,
         previousClose: Double? = nil,
         currency: String = "USD",
         lastUpdated: Date? = nil) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.lots = lots
        self.currentPrice = currentPrice
        self.previousClose = previousClose
        self.currency = currency
        self.lastUpdated = lastUpdated
    }
}

// MARK: - StockLot
struct StockLot: Codable, Identifiable, Hashable {
    let id: String
    var shares: Double
    var pricePerShare: Double
    var purchaseDate: Date
    var currency: String
    var notes: String?

    var totalCost: Double {
        shares * pricePerShare
    }

    init(id: String = UUID().uuidString,
         shares: Double,
         pricePerShare: Double,
         purchaseDate: Date = Date(),
         currency: String = "USD",
         notes: String? = nil) {
        self.id = id
        self.shares = shares
        self.pricePerShare = pricePerShare
        self.purchaseDate = purchaseDate
        self.currency = currency
        self.notes = notes
    }
}

// MARK: - HistoricalDataPoint
struct HistoricalDataPoint: Codable, Identifiable, Hashable {
    let id: String
    let date: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Int64

    init(id: String = UUID().uuidString,
         date: Date,
         open: Double,
         high: Double,
         low: Double,
         close: Double,
         volume: Int64) {
        self.id = id
        self.date = date
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
    }
}

// MARK: - StockSearchResult
struct StockSearchResult: Codable, Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let exchange: String?
    let type: String?

    enum CodingKeys: String, CodingKey {
        case symbol, name, exchange, type
    }
}

// MARK: - StockQuote
struct StockQuote: Codable {
    let symbol: String
    let price: Double
    let previousClose: Double
    let change: Double
    let changePercent: Double
    let volume: Int64?
    let marketCap: Double?
    let high: Double?
    let low: Double?
    let open: Double?
    let timestamp: Date
}

// MARK: - TimeRange
enum TimeRange: String, CaseIterable, Codable {
    case oneDay = "1D"
    case oneWeek = "1W"
    case oneMonth = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case oneYear = "1Y"
    case fiveYears = "5Y"
    case tenYears = "10Y"

    var days: Int {
        switch self {
        case .oneDay: return 1
        case .oneWeek: return 7
        case .oneMonth: return 30
        case .threeMonths: return 90
        case .sixMonths: return 180
        case .oneYear: return 365
        case .fiveYears: return 1825
        case .tenYears: return 3650
        }
    }
}
