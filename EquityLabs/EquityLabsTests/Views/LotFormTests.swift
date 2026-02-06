import XCTest
@testable import EquityLabs

final class LotFormTests: XCTestCase {

    // MARK: - StockLot Creation

    func testStockLotCreation() {
        let date = Date()
        let lot = StockLot(
            id: "lot-1",
            shares: 10,
            pricePerShare: 150.50,
            purchaseDate: date,
            currency: "USD",
            notes: "Initial purchase"
        )

        XCTAssertEqual(lot.id, "lot-1")
        XCTAssertEqual(lot.shares, 10)
        XCTAssertEqual(lot.pricePerShare, 150.50)
        XCTAssertEqual(lot.purchaseDate, date)
        XCTAssertEqual(lot.currency, "USD")
        XCTAssertEqual(lot.notes, "Initial purchase")
    }

    func testStockLotDefaults() {
        let lot = StockLot(shares: 5, pricePerShare: 100)

        XCTAssertFalse(lot.id.isEmpty)
        XCTAssertEqual(lot.currency, "USD")
        XCTAssertNil(lot.notes)
    }

    // MARK: - Total Cost

    func testTotalCostCalculation() {
        let lot = StockLot(shares: 10, pricePerShare: 150)
        XCTAssertEqual(lot.totalCost, 1500)
    }

    func testTotalCostWithFractionalShares() {
        let lot = StockLot(shares: 0.5, pricePerShare: 200)
        XCTAssertEqual(lot.totalCost, 100)
    }

    func testTotalCostZeroShares() {
        let lot = StockLot(shares: 0, pricePerShare: 150)
        XCTAssertEqual(lot.totalCost, 0)
    }

    func testTotalCostLargePosition() {
        let lot = StockLot(shares: 1000, pricePerShare: 500)
        XCTAssertEqual(lot.totalCost, 500_000)
    }

    // MARK: - Identifiable / Hashable

    func testStockLotIdentifiable() {
        let lot1 = StockLot(id: "lot-1", shares: 10, pricePerShare: 150)
        let lot2 = StockLot(id: "lot-2", shares: 10, pricePerShare: 150)

        XCTAssertNotEqual(lot1.id, lot2.id)
    }

    func testStockLotHashable() {
        let lot1 = StockLot(id: "same-id", shares: 10, pricePerShare: 150)
        let lot2 = StockLot(id: "same-id", shares: 10, pricePerShare: 150)

        var set = Set<StockLot>()
        set.insert(lot1)
        set.insert(lot2)
        XCTAssertEqual(set.count, 1)
    }

    // MARK: - Codable

    func testStockLotCodable() throws {
        let date = Date()
        let lot = StockLot(
            id: "encode-test",
            shares: 10,
            pricePerShare: 155.75,
            purchaseDate: date,
            currency: "CAD",
            notes: "Test note"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(lot)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(StockLot.self, from: data)

        XCTAssertEqual(decoded.id, "encode-test")
        XCTAssertEqual(decoded.shares, 10)
        XCTAssertEqual(decoded.pricePerShare, 155.75)
        XCTAssertEqual(decoded.currency, "CAD")
        XCTAssertEqual(decoded.notes, "Test note")
    }

    func testStockLotAPIFieldNames() throws {
        // API uses "price" and "date" field names
        let json = """
        {
            "id": "api-lot",
            "shares": 5,
            "price": 200.50,
            "date": "2026-02-05T00:00:00Z",
            "currency": "USD"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let lot = try decoder.decode(StockLot.self, from: json)

        XCTAssertEqual(lot.id, "api-lot")
        XCTAssertEqual(lot.shares, 5)
        XCTAssertEqual(lot.pricePerShare, 200.50)
        XCTAssertEqual(lot.currency, "USD")
        XCTAssertNil(lot.notes)
    }

    // MARK: - Multiple Lots Aggregation

    func testMultipleLotsTotalShares() {
        let lots = [
            StockLot(shares: 10, pricePerShare: 140),
            StockLot(shares: 5, pricePerShare: 160),
            StockLot(shares: 15, pricePerShare: 155)
        ]

        let totalShares = lots.reduce(0) { $0 + $1.shares }
        XCTAssertEqual(totalShares, 30)
    }

    func testMultipleLotsTotalCost() {
        let lots = [
            StockLot(shares: 10, pricePerShare: 140),
            StockLot(shares: 5, pricePerShare: 160),
            StockLot(shares: 15, pricePerShare: 155)
        ]

        let totalCost = lots.reduce(0) { $0 + $1.totalCost }
        // 10*140 + 5*160 + 15*155 = 1400 + 800 + 2325 = 4525
        XCTAssertEqual(totalCost, 4525)
    }

    func testAverageCostCalculation() {
        let lots = [
            StockLot(shares: 10, pricePerShare: 140),
            StockLot(shares: 10, pricePerShare: 160)
        ]

        let totalCost = lots.reduce(0) { $0 + $1.totalCost }
        let totalShares = lots.reduce(0) { $0 + $1.shares }
        let averageCost = totalShares > 0 ? totalCost / totalShares : 0

        // (1400 + 1600) / 20 = 150
        XCTAssertEqual(averageCost, 150)
    }

    // MARK: - Currency Variants

    func testStockLotCADCurrency() {
        let lot = StockLot(shares: 10, pricePerShare: 200, currency: "CAD")
        XCTAssertEqual(lot.currency, "CAD")
        XCTAssertEqual(lot.totalCost, 2000)
    }
}
