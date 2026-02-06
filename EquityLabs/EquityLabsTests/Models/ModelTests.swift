import XCTest
@testable import EquityLabs

final class ModelTests: XCTestCase {

    // MARK: - Stock Tests

    func testStockTotalShares() {
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            lots: [
                StockLot(shares: 10, pricePerShare: 140),
                StockLot(shares: 5, pricePerShare: 150)
            ]
        )
        XCTAssertEqual(stock.totalShares, 15)
    }

    func testStockTotalCost() {
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            lots: [
                StockLot(shares: 10, pricePerShare: 140),
                StockLot(shares: 5, pricePerShare: 150)
            ]
        )
        // 10 * 140 + 5 * 150 = 1400 + 750 = 2150
        XCTAssertEqual(stock.totalCost, 2150)
    }

    func testStockAverageCost() {
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            lots: [
                StockLot(shares: 10, pricePerShare: 140),
                StockLot(shares: 5, pricePerShare: 150)
            ]
        )
        // 2150 / 15 ≈ 143.33
        XCTAssertEqual(stock.averageCost, 2150.0 / 15.0, accuracy: 0.01)
    }

    func testStockCurrentValue() {
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            lots: [StockLot(shares: 10, pricePerShare: 140)],
            currentPrice: 160
        )
        // 10 * 160 = 1600
        XCTAssertEqual(stock.currentValue, 1600)
    }

    func testStockCurrentValueNilPrice() {
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            lots: [StockLot(shares: 10, pricePerShare: 140)]
        )
        XCTAssertEqual(stock.currentValue, 0)
    }

    func testStockProfitLoss() {
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            lots: [StockLot(shares: 10, pricePerShare: 140)],
            currentPrice: 160
        )
        // 1600 - 1400 = 200
        XCTAssertEqual(stock.profitLoss, 200)
    }

    func testStockProfitLossPercentage() {
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            lots: [StockLot(shares: 10, pricePerShare: 100)],
            currentPrice: 120
        )
        // (200 / 1000) * 100 = 20%
        XCTAssertEqual(stock.profitLossPercentage, 20, accuracy: 0.01)
    }

    func testStockProfitLossPercentageNoShares() {
        let stock = Stock(symbol: "AAPL", name: "Apple Inc.", lots: [])
        XCTAssertEqual(stock.profitLossPercentage, 0)
    }

    func testStockDayChange() {
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            lots: [],
            currentPrice: 155,
            previousClose: 150
        )
        XCTAssertEqual(stock.dayChange, 5)
    }

    func testStockDayChangeNilPrices() {
        let stock = Stock(symbol: "AAPL", name: "Apple Inc.", lots: [])
        XCTAssertNil(stock.dayChange)
    }

    func testStockDayChangePercentage() {
        let stock = Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            lots: [],
            currentPrice: 155,
            previousClose: 150
        )
        // (5 / 150) * 100 ≈ 3.33
        XCTAssertEqual(stock.dayChangePercentage!, 3.33, accuracy: 0.01)
    }

    func testStockDayChangePercentageNil() {
        let stock = Stock(symbol: "AAPL", name: "Apple Inc.", lots: [])
        XCTAssertNil(stock.dayChangePercentage)
    }

    // MARK: - StockLot Tests

    func testStockLotTotalCost() {
        let lot = StockLot(shares: 10, pricePerShare: 150)
        XCTAssertEqual(lot.totalCost, 1500)
    }

    func testStockLotDefaults() {
        let lot = StockLot(shares: 5, pricePerShare: 100)
        XCTAssertEqual(lot.currency, "USD")
        XCTAssertNil(lot.notes)
        XCTAssertFalse(lot.id.isEmpty)
    }

    // MARK: - Portfolio Tests

    func testPortfolioTotalValue() {
        let portfolio = Portfolio(stocks: [
            Stock(symbol: "AAPL", name: "Apple", lots: [StockLot(shares: 10, pricePerShare: 100)], currentPrice: 120),
            Stock(symbol: "GOOGL", name: "Alphabet", lots: [StockLot(shares: 5, pricePerShare: 200)], currentPrice: 250)
        ])
        // 10*120 + 5*250 = 1200 + 1250 = 2450
        XCTAssertEqual(portfolio.totalValue, 2450)
    }

    func testPortfolioTotalCost() {
        let portfolio = Portfolio(stocks: [
            Stock(symbol: "AAPL", name: "Apple", lots: [StockLot(shares: 10, pricePerShare: 100)]),
            Stock(symbol: "GOOGL", name: "Alphabet", lots: [StockLot(shares: 5, pricePerShare: 200)])
        ])
        // 10*100 + 5*200 = 1000 + 1000 = 2000
        XCTAssertEqual(portfolio.totalCost, 2000)
    }

    func testPortfolioTotalProfitLoss() {
        let portfolio = Portfolio(stocks: [
            Stock(symbol: "AAPL", name: "Apple", lots: [StockLot(shares: 10, pricePerShare: 100)], currentPrice: 120)
        ])
        // 1200 - 1000 = 200
        XCTAssertEqual(portfolio.totalProfitLoss, 200)
    }

    func testPortfolioTotalProfitLossPercentage() {
        let portfolio = Portfolio(stocks: [
            Stock(symbol: "AAPL", name: "Apple", lots: [StockLot(shares: 10, pricePerShare: 100)], currentPrice: 120)
        ])
        // (200 / 1000) * 100 = 20%
        XCTAssertEqual(portfolio.totalProfitLossPercentage, 20, accuracy: 0.01)
    }

    func testPortfolioTotalProfitLossPercentageEmpty() {
        let portfolio = Portfolio(stocks: [])
        XCTAssertEqual(portfolio.totalProfitLossPercentage, 0)
    }

    func testPortfolioTotalDayChange() {
        let portfolio = Portfolio(stocks: [
            Stock(symbol: "AAPL", name: "Apple", lots: [StockLot(shares: 10, pricePerShare: 100)], currentPrice: 120, previousClose: 115),
            Stock(symbol: "GOOGL", name: "Alphabet", lots: [StockLot(shares: 5, pricePerShare: 200)], currentPrice: 250, previousClose: 245)
        ])
        // AAPL: (120-115)*10 = 50, GOOGL: (250-245)*5 = 25 => 75
        XCTAssertEqual(portfolio.totalDayChange!, 75, accuracy: 0.01)
    }

    func testPortfolioTotalDayChangeNilWhenNoPrices() {
        let portfolio = Portfolio(stocks: [
            Stock(symbol: "AAPL", name: "Apple", lots: [StockLot(shares: 10, pricePerShare: 100)])
        ])
        XCTAssertNil(portfolio.totalDayChange)
    }

    // MARK: - PortfolioSummary Tests

    func testPortfolioSummaryFromPortfolio() {
        let portfolio = Portfolio(stocks: [
            Stock(symbol: "AAPL", name: "Apple", lots: [StockLot(shares: 10, pricePerShare: 100)], currentPrice: 120)
        ])
        let summary = PortfolioSummary(portfolio: portfolio)

        XCTAssertEqual(summary.totalValue, 1200)
        XCTAssertEqual(summary.totalCost, 1000)
        XCTAssertEqual(summary.totalProfitLoss, 200)
        XCTAssertEqual(summary.stockCount, 1)
        XCTAssertEqual(summary.currency, .usd)
    }

    // MARK: - Currency Tests

    func testCurrencySymbol() {
        XCTAssertEqual(Currency.usd.symbol, "$")
        XCTAssertEqual(Currency.cad.symbol, "C$")
    }

    func testCurrencyName() {
        XCTAssertEqual(Currency.usd.name, "US Dollar")
        XCTAssertEqual(Currency.cad.name, "Canadian Dollar")
    }

    func testCurrencyRawValue() {
        XCTAssertEqual(Currency.usd.rawValue, "USD")
        XCTAssertEqual(Currency.cad.rawValue, "CAD")
    }

    func testCurrencyFromRawValue() {
        XCTAssertEqual(Currency(rawValue: "USD"), .usd)
        XCTAssertEqual(Currency(rawValue: "CAD"), .cad)
        XCTAssertNil(Currency(rawValue: "EUR"))
    }

    // MARK: - Double Currency Formatting Tests

    func testDoubleToCurrency() {
        let value = 1234.56
        let formatted = value.toCurrency(currency: .usd)
        XCTAssertTrue(formatted.contains("$"))
        XCTAssertTrue(formatted.contains("1,234.56"))
    }

    func testDoubleToCurrencyCAD() {
        let value = 1234.56
        let formatted = value.toCurrency(currency: .cad)
        XCTAssertTrue(formatted.contains("C$"))
    }

    func testDoubleToPercentage() {
        let value = 12.345
        let formatted = value.toPercentage()
        XCTAssertTrue(formatted.contains("12.35"))
        XCTAssertTrue(formatted.contains("%"))
    }

    func testDoubleToPercentageNegative() {
        let value = -5.5
        let formatted = value.toPercentage()
        XCTAssertTrue(formatted.contains("-"))
        XCTAssertTrue(formatted.contains("5.50"))
    }

    func testDoubleToShortCurrencyBillions() {
        let value = 2_500_000_000.0
        let formatted = value.toShortCurrency()
        XCTAssertTrue(formatted.contains("B"))
    }

    func testDoubleToShortCurrencyMillions() {
        let value = 1_500_000.0
        let formatted = value.toShortCurrency()
        XCTAssertTrue(formatted.contains("M"))
    }

    func testDoubleToShortCurrencyThousands() {
        let value = 5_000.0
        let formatted = value.toShortCurrency()
        XCTAssertTrue(formatted.contains("K"))
    }

    func testDoubleConvertSameCurrency() {
        let value = 100.0
        let converted = value.convert(from: .usd, to: .usd, rate: 1.35)
        XCTAssertEqual(converted, 100.0)
    }

    func testDoubleConvertUSDToCAD() {
        let value = 100.0
        let converted = value.convert(from: .usd, to: .cad, rate: 1.35)
        XCTAssertEqual(converted, 135.0)
    }

    func testDoubleConvertCADToUSD() {
        let value = 135.0
        let converted = value.convert(from: .cad, to: .usd, rate: 1.35)
        XCTAssertEqual(converted, 100.0)
    }

    func testDoubleRoundedToPlaces() {
        XCTAssertEqual(3.14159.rounded(toPlaces: 2), 3.14, accuracy: 0.001)
        XCTAssertEqual(3.14159.rounded(toPlaces: 0), 3, accuracy: 0.001)
    }

    // MARK: - Optional Double Tests

    func testOptionalDoubleToCurrency() {
        let value: Double? = 100.50
        let formatted = value.toCurrency()
        XCTAssertTrue(formatted.contains("100.50"))
    }

    func testOptionalDoubleNilToCurrency() {
        let value: Double? = nil
        let formatted = value.toCurrency()
        XCTAssertEqual(formatted, "--")
    }

    func testOptionalDoubleNilToPercentage() {
        let value: Double? = nil
        let formatted = value.toPercentage()
        XCTAssertEqual(formatted, "--")
    }

    // MARK: - TimeRange Tests

    func testTimeRangeDays() {
        XCTAssertEqual(TimeRange.oneDay.days, 1)
        XCTAssertEqual(TimeRange.oneWeek.days, 7)
        XCTAssertEqual(TimeRange.oneMonth.days, 30)
        XCTAssertEqual(TimeRange.oneYear.days, 365)
    }

    // MARK: - StockPrice Tests

    func testStockPriceChange() {
        let price = StockPrice(symbol: "AAPL", currentPrice: 155, previousClose: 150, lastUpdated: Date())
        XCTAssertEqual(price.change, 5)
    }

    func testStockPriceChangePercent() {
        let price = StockPrice(symbol: "AAPL", currentPrice: 155, previousClose: 150, lastUpdated: Date())
        XCTAssertEqual(price.changePercent, 3.33, accuracy: 0.01)
    }

    func testStockPriceChangePercentZeroPreviousClose() {
        let price = StockPrice(symbol: "AAPL", currentPrice: 155, previousClose: 0, lastUpdated: Date())
        XCTAssertEqual(price.changePercent, 0)
    }

    // MARK: - PendingMutation Tests

    func testPendingMutationCreation() {
        let stock = Stock(symbol: "AAPL", name: "Apple Inc.")
        let mutation = PendingMutation(type: .addStock, stock: stock)

        XCTAssertEqual(mutation.type, .addStock)
        XCTAssertEqual(mutation.stock?.symbol, "AAPL")
        XCTAssertFalse(mutation.id.isEmpty)
    }

    func testPendingMutationDeleteType() {
        let mutation = PendingMutation(type: .deleteStock, symbol: "AAPL")

        XCTAssertEqual(mutation.type, .deleteStock)
        XCTAssertEqual(mutation.symbol, "AAPL")
        XCTAssertNil(mutation.stock)
    }

    func testMutationTypeCodable() throws {
        let mutation = PendingMutation(type: .updateStock, stock: Stock(symbol: "TSLA", name: "Tesla"))
        let data = try JSONEncoder().encode(mutation)
        let decoded = try JSONDecoder().decode(PendingMutation.self, from: data)
        XCTAssertEqual(decoded.type, .updateStock)
        XCTAssertEqual(decoded.stock?.symbol, "TSLA")
    }
}
