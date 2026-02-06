import XCTest
@testable import EquityLabs

final class StockDetailViewModelTests: XCTestCase {

    // MARK: - Helpers

    private func makeSampleStock(
        lots: [StockLot] = [StockLot(shares: 10, pricePerShare: 150)],
        currentPrice: Double? = 165,
        previousClose: Double? = 163,
        currency: String = "USD"
    ) -> Stock {
        Stock(
            id: "test-1",
            symbol: "AAPL",
            name: "Apple Inc.",
            lots: lots,
            currentPrice: currentPrice,
            previousClose: previousClose,
            currency: currency,
            lastUpdated: Date()
        )
    }

    // MARK: - Initial State

    @MainActor
    func testInitialState() {
        let vm = StockDetailViewModel(stock: makeSampleStock())
        XCTAssertTrue(vm.historicalData.isEmpty)
        XCTAssertEqual(vm.selectedTimeRange, .oneMonth)
        XCTAssertEqual(vm.selectedTab, .overview)
        XCTAssertTrue(vm.newsArticles.isEmpty)
        XCTAssertFalse(vm.isLoading)
        XCTAssertFalse(vm.isLoadingHistory)
        XCTAssertFalse(vm.isLoadingNews)
        XCTAssertNil(vm.error)
    }

    // MARK: - Computed Properties

    @MainActor
    func testCurrentPriceUsesStockPrice() {
        let vm = StockDetailViewModel(stock: makeSampleStock(currentPrice: 170))
        XCTAssertEqual(vm.currentPrice, 170)
    }

    @MainActor
    func testCurrentPriceFallsBackToAverageCost() {
        let vm = StockDetailViewModel(stock: makeSampleStock(currentPrice: nil))
        // averageCost = totalCost / totalShares = (10*150)/10 = 150
        XCTAssertEqual(vm.currentPrice, 150)
    }

    @MainActor
    func testPriceChange() {
        let vm = StockDetailViewModel(stock: makeSampleStock(currentPrice: 165, previousClose: 163))
        XCTAssertEqual(vm.priceChange ?? 0, 2, accuracy: 0.01)
    }

    @MainActor
    func testPriceChangePercent() {
        let vm = StockDetailViewModel(stock: makeSampleStock(currentPrice: 165, previousClose: 163))
        // (2 / 163) * 100 = 1.227
        XCTAssertEqual(vm.priceChangePercent ?? 0, 1.227, accuracy: 0.01)
    }

    @MainActor
    func testPriceChangeNilWhenNoPreviousClose() {
        let vm = StockDetailViewModel(stock: makeSampleStock(previousClose: nil))
        XCTAssertNil(vm.priceChange)
        XCTAssertNil(vm.priceChangePercent)
    }

    @MainActor
    func testTotalValue() {
        let vm = StockDetailViewModel(stock: makeSampleStock(currentPrice: 165))
        // 10 shares * 165 = 1650
        XCTAssertEqual(vm.totalValue, 1650)
    }

    @MainActor
    func testTotalCost() {
        let vm = StockDetailViewModel(stock: makeSampleStock())
        // 10 shares * 150 = 1500
        XCTAssertEqual(vm.totalCost, 1500)
    }

    @MainActor
    func testGainLoss() {
        let vm = StockDetailViewModel(stock: makeSampleStock(currentPrice: 165))
        // 1650 - 1500 = 150
        XCTAssertEqual(vm.gainLoss, 150)
    }

    @MainActor
    func testGainLossPercent() {
        let vm = StockDetailViewModel(stock: makeSampleStock(currentPrice: 165))
        // (150 / 1500) * 100 = 10
        XCTAssertEqual(vm.gainLossPercent, 10, accuracy: 0.01)
    }

    @MainActor
    func testAverageCost() {
        let lots = [
            StockLot(shares: 10, pricePerShare: 140),
            StockLot(shares: 10, pricePerShare: 160)
        ]
        let vm = StockDetailViewModel(stock: makeSampleStock(lots: lots))
        // (10*140 + 10*160) / 20 = 3000/20 = 150
        XCTAssertEqual(vm.averageCost, 150)
    }

    @MainActor
    func testTotalShares() {
        let lots = [
            StockLot(shares: 10, pricePerShare: 140),
            StockLot(shares: 5, pricePerShare: 160)
        ]
        let vm = StockDetailViewModel(stock: makeSampleStock(lots: lots))
        XCTAssertEqual(vm.totalShares, 15)
    }

    @MainActor
    func testHasMultipleLots() {
        let singleLot = StockDetailViewModel(stock: makeSampleStock(lots: [StockLot(shares: 10, pricePerShare: 150)]))
        XCTAssertFalse(singleLot.hasMultipleLots)

        let multiLot = StockDetailViewModel(stock: makeSampleStock(lots: [
            StockLot(shares: 10, pricePerShare: 140),
            StockLot(shares: 5, pricePerShare: 160)
        ]))
        XCTAssertTrue(multiLot.hasMultipleLots)
    }

    @MainActor
    func testHasNewsDefault() {
        let vm = StockDetailViewModel(stock: makeSampleStock())
        XCTAssertFalse(vm.hasNews)
    }

    // MARK: - Sentiment Gating

    @MainActor
    func testCanViewSentimentDefaultFree() {
        // Default SubscriptionManager starts with free tier
        let vm = StockDetailViewModel(stock: makeSampleStock())
        XCTAssertFalse(vm.canViewSentiment)
    }

    // MARK: - Formatting

    @MainActor
    func testFormatPrice() {
        let vm = StockDetailViewModel(stock: makeSampleStock())
        let result = vm.formatPrice(123.45)
        // Should contain the number (exact format depends on locale)
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("123"))
    }

    @MainActor
    func testFormatPercent() {
        let vm = StockDetailViewModel(stock: makeSampleStock())
        XCTAssertEqual(vm.formatPercent(12.345), "+12.35%")
        XCTAssertEqual(vm.formatPercent(-5.5), "-5.50%")
        XCTAssertEqual(vm.formatPercent(0), "+0.00%")
    }

    @MainActor
    func testFormatShares() {
        let vm = StockDetailViewModel(stock: makeSampleStock())
        let result = vm.formatShares(10.5)
        XCTAssertTrue(result.contains("10"))
    }

    // MARK: - Tab Enum

    func testDetailTabAllCases() {
        XCTAssertEqual(DetailTab.allCases.count, 3)
    }

    func testDetailTabRawValues() {
        XCTAssertEqual(DetailTab.overview.rawValue, "Overview")
        XCTAssertEqual(DetailTab.lots.rawValue, "Lots")
        XCTAssertEqual(DetailTab.news.rawValue, "News")
    }
}
