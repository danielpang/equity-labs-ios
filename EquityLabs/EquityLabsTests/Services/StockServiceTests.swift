import XCTest
@testable import EquityLabs

final class StockServiceTests: XCTestCase {

    // MARK: - StockSearchResult Tests

    func testStockSearchResultIdentifiable() {
        let result = StockSearchResult(symbol: "AAPL", name: "Apple Inc.", exchange: "NASDAQ", type: "stock")
        XCTAssertEqual(result.symbol, "AAPL")
        XCTAssertEqual(result.name, "Apple Inc.")
        XCTAssertEqual(result.exchange, "NASDAQ")
    }

    func testStockSearchResultOptionalFields() {
        let result = StockSearchResult(symbol: "TEST", name: "Test Co.", exchange: nil, type: nil)
        XCTAssertNil(result.exchange)
        XCTAssertNil(result.type)
    }

    // MARK: - StockPrice Tests

    func testStockPricePositiveChange() {
        let price = StockPrice(
            symbol: "AAPL",
            currentPrice: 160,
            previousClose: 150,
            lastUpdated: Date()
        )
        XCTAssertEqual(price.change, 10)
        XCTAssertEqual(price.changePercent, 6.67, accuracy: 0.01)
    }

    func testStockPriceNegativeChange() {
        let price = StockPrice(
            symbol: "AAPL",
            currentPrice: 140,
            previousClose: 150,
            lastUpdated: Date()
        )
        XCTAssertEqual(price.change, -10)
        XCTAssertEqual(price.changePercent, -6.67, accuracy: 0.01)
    }

    func testStockPriceNoChange() {
        let price = StockPrice(
            symbol: "AAPL",
            currentPrice: 150,
            previousClose: 150,
            lastUpdated: Date()
        )
        XCTAssertEqual(price.change, 0)
        XCTAssertEqual(price.changePercent, 0)
    }

    func testStockPriceCodable() throws {
        let price = StockPrice(
            symbol: "AAPL",
            currentPrice: 155.50,
            previousClose: 150.25,
            lastUpdated: Date()
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(price)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(StockPrice.self, from: data)

        XCTAssertEqual(decoded.symbol, "AAPL")
        XCTAssertEqual(decoded.currentPrice, 155.50)
        XCTAssertEqual(decoded.previousClose, 150.25)
    }

    // MARK: - Stock Creation from API Pattern

    func testStockCreationWithDefaults() {
        let stock = Stock(symbol: "TSLA", name: "Tesla Inc.")
        XCTAssertEqual(stock.symbol, "TSLA")
        XCTAssertEqual(stock.name, "Tesla Inc.")
        XCTAssertTrue(stock.lots.isEmpty)
        XCTAssertNil(stock.currentPrice)
        XCTAssertNil(stock.previousClose)
        XCTAssertEqual(stock.currency, "USD")
        XCTAssertNil(stock.lastUpdated)
    }

    func testStockCreationWithAllFields() {
        let now = Date()
        let stock = Stock(
            id: "custom-id",
            symbol: "MSFT",
            name: "Microsoft Corp.",
            lots: [StockLot(shares: 20, pricePerShare: 350)],
            currentPrice: 370,
            previousClose: 365,
            currency: "CAD",
            lastUpdated: now
        )
        XCTAssertEqual(stock.id, "custom-id")
        XCTAssertEqual(stock.currency, "CAD")
        XCTAssertEqual(stock.lastUpdated, now)
    }

    // MARK: - TimeRange Tests

    func testTimeRangeAllCases() {
        XCTAssertEqual(TimeRange.allCases.count, 8)
    }

    func testTimeRangeRawValues() {
        XCTAssertEqual(TimeRange.oneDay.rawValue, "1D")
        XCTAssertEqual(TimeRange.oneWeek.rawValue, "1W")
        XCTAssertEqual(TimeRange.oneMonth.rawValue, "1M")
        XCTAssertEqual(TimeRange.threeMonths.rawValue, "3M")
        XCTAssertEqual(TimeRange.sixMonths.rawValue, "6M")
        XCTAssertEqual(TimeRange.oneYear.rawValue, "1Y")
        XCTAssertEqual(TimeRange.fiveYears.rawValue, "5Y")
        XCTAssertEqual(TimeRange.tenYears.rawValue, "10Y")
    }

    // MARK: - Stock Hashable/Equatable

    func testStockHashable() {
        let stock1 = Stock(id: "1", symbol: "AAPL", name: "Apple")
        let stock2 = Stock(id: "1", symbol: "AAPL", name: "Apple")
        let stock3 = Stock(id: "2", symbol: "GOOGL", name: "Alphabet")

        var set: Set<Stock> = []
        set.insert(stock1)
        set.insert(stock2) // Same id
        set.insert(stock3)

        XCTAssertEqual(set.count, 2)
    }
}
