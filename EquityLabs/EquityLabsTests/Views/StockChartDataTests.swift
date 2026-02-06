import XCTest
@testable import EquityLabs

final class StockChartDataTests: XCTestCase {

    // MARK: - HistoricalDataPoint Creation

    func testHistoricalDataPointCreation() {
        let date = Date()
        let point = HistoricalDataPoint(
            date: date,
            open: 150.0,
            high: 155.0,
            low: 148.0,
            close: 153.0,
            volume: 1_000_000
        )

        XCTAssertEqual(point.date, date)
        XCTAssertEqual(point.open, 150.0)
        XCTAssertEqual(point.high, 155.0)
        XCTAssertEqual(point.low, 148.0)
        XCTAssertEqual(point.close, 153.0)
        XCTAssertEqual(point.volume, 1_000_000)
        XCTAssertFalse(point.id.isEmpty)
    }

    func testHistoricalDataPointWithCustomId() {
        let point = HistoricalDataPoint(
            id: "custom-id",
            date: Date(),
            open: 100,
            high: 110,
            low: 95,
            close: 105,
            volume: 500_000
        )

        XCTAssertEqual(point.id, "custom-id")
    }

    func testHistoricalDataPointIdentifiable() {
        let point1 = HistoricalDataPoint(
            id: "point-1",
            date: Date(),
            open: 100, high: 110, low: 95, close: 105, volume: 500_000
        )
        let point2 = HistoricalDataPoint(
            id: "point-2",
            date: Date(),
            open: 100, high: 110, low: 95, close: 105, volume: 500_000
        )

        XCTAssertNotEqual(point1.id, point2.id)
    }

    func testHistoricalDataPointHashable() {
        let point1 = HistoricalDataPoint(
            id: "same-id",
            date: Date(),
            open: 100, high: 110, low: 95, close: 105, volume: 500_000
        )
        let point2 = HistoricalDataPoint(
            id: "same-id",
            date: Date(),
            open: 100, high: 110, low: 95, close: 105, volume: 500_000
        )

        var set = Set<HistoricalDataPoint>()
        set.insert(point1)
        set.insert(point2)
        XCTAssertEqual(set.count, 1)
    }

    // MARK: - Chart Color Logic

    func testChartColorLogicUptrend() {
        let data = [
            HistoricalDataPoint(date: Date().addingTimeInterval(-86400), open: 100, high: 105, low: 98, close: 100, volume: 1000),
            HistoricalDataPoint(date: Date(), open: 100, high: 115, low: 100, close: 110, volume: 1000)
        ]

        // Chart is green when last.close >= first.close
        guard let first = data.first, let last = data.last else {
            XCTFail("Data should not be empty")
            return
        }
        XCTAssertTrue(last.close >= first.close, "Last close should be >= first close for uptrend")
    }

    func testChartColorLogicDowntrend() {
        let data = [
            HistoricalDataPoint(date: Date().addingTimeInterval(-86400), open: 110, high: 115, low: 108, close: 110, volume: 1000),
            HistoricalDataPoint(date: Date(), open: 110, high: 112, low: 95, close: 100, volume: 1000)
        ]

        guard let first = data.first, let last = data.last else {
            XCTFail("Data should not be empty")
            return
        }
        XCTAssertTrue(last.close < first.close, "Last close should be < first close for downtrend")
    }

    func testChartColorLogicFlat() {
        let data = [
            HistoricalDataPoint(date: Date().addingTimeInterval(-86400), open: 100, high: 105, low: 98, close: 100, volume: 1000),
            HistoricalDataPoint(date: Date(), open: 100, high: 102, low: 98, close: 100, volume: 1000)
        ]

        guard let first = data.first, let last = data.last else {
            XCTFail("Data should not be empty")
            return
        }
        XCTAssertTrue(last.close >= first.close, "Equal close values should show green (>=)")
    }

    // MARK: - HistoricalDataPoint Codable

    func testHistoricalDataPointCodable() throws {
        let date = Date()
        let point = HistoricalDataPoint(
            id: "encode-test",
            date: date,
            open: 150.0,
            high: 155.0,
            low: 148.0,
            close: 153.0,
            volume: 1_000_000
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(point)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(HistoricalDataPoint.self, from: data)

        XCTAssertEqual(decoded.id, "encode-test")
        XCTAssertEqual(decoded.open, 150.0)
        XCTAssertEqual(decoded.high, 155.0)
        XCTAssertEqual(decoded.low, 148.0)
        XCTAssertEqual(decoded.close, 153.0)
        XCTAssertEqual(decoded.volume, 1_000_000)
    }

    // MARK: - TimeRange Properties

    func testTimeRangeDays() {
        XCTAssertEqual(TimeRange.oneDay.days, 1)
        XCTAssertEqual(TimeRange.oneWeek.days, 7)
        XCTAssertEqual(TimeRange.oneMonth.days, 30)
        XCTAssertEqual(TimeRange.threeMonths.days, 90)
        XCTAssertEqual(TimeRange.sixMonths.days, 180)
        XCTAssertEqual(TimeRange.oneYear.days, 365)
        XCTAssertEqual(TimeRange.fiveYears.days, 1825)
        XCTAssertEqual(TimeRange.tenYears.days, 3650)
    }

    func testTimeRangeCodable() throws {
        let range = TimeRange.threeMonths

        let encoder = JSONEncoder()
        let data = try encoder.encode(range)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(TimeRange.self, from: data)

        XCTAssertEqual(decoded, range)
    }
}
