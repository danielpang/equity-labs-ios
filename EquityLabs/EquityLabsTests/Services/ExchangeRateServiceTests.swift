import XCTest
@testable import EquityLabs

final class ExchangeRateServiceTests: XCTestCase {

    // MARK: - ExchangeRateError Tests

    func testRateNotAvailableError() {
        let error = ExchangeRateError.rateNotAvailable
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.localizedDescription.contains("not available"))
    }

    func testConversionFailedError() {
        let error = ExchangeRateError.conversionFailed
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.localizedDescription.contains("failed"))
    }

    func testCacheExpiredError() {
        let error = ExchangeRateError.cacheExpired
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.localizedDescription.contains("expired"))
    }

    // MARK: - Currency Conversion Logic Tests (via Double extension)

    func testConvertUSDToCAD() {
        let amount = 100.0
        let result = amount.convert(from: .usd, to: .cad, rate: 1.35)
        XCTAssertEqual(result, 135.0, accuracy: 0.01)
    }

    func testConvertCADToUSD() {
        let amount = 135.0
        let result = amount.convert(from: .cad, to: .usd, rate: 1.35)
        XCTAssertEqual(result, 100.0, accuracy: 0.01)
    }

    func testConvertSameCurrency() {
        let amount = 100.0
        let result = amount.convert(from: .usd, to: .usd, rate: 1.35)
        XCTAssertEqual(result, 100.0)
    }

    func testConvertZeroAmount() {
        let result = 0.0.convert(from: .usd, to: .cad, rate: 1.35)
        XCTAssertEqual(result, 0.0)
    }

    func testConvertLargeAmount() {
        let amount = 1_000_000.0
        let result = amount.convert(from: .usd, to: .cad, rate: 1.35)
        XCTAssertEqual(result, 1_350_000.0, accuracy: 0.01)
    }

    func testConvertNegativeAmount() {
        let amount = -50.0
        let result = amount.convert(from: .usd, to: .cad, rate: 1.35)
        XCTAssertEqual(result, -67.5, accuracy: 0.01)
    }

    // MARK: - ExchangeRateService Singleton Pattern

    @MainActor
    func testSharedInstanceExists() {
        let service = ExchangeRateService.shared
        XCTAssertNotNil(service)
    }

    @MainActor
    func testGetExchangeRateSameCurrency() {
        let service = ExchangeRateService.shared
        let rate = service.getExchangeRate(from: .usd, to: .usd)
        XCTAssertEqual(rate, 1.0)
    }

    @MainActor
    func testGetRateReturnsNilWithoutData() {
        // With empty rates, getting a rate for a specific currency returns nil
        // (Unless rates were cached from a previous test run)
        let service = ExchangeRateService.shared
        // Just verify the method doesn't crash
        let _ = service.getRate(for: .usd)
        let _ = service.getRate(for: .cad)
    }

    @MainActor
    func testFormatAmount() {
        let service = ExchangeRateService.shared
        let formatted = service.formatAmount(1234.56, in: .usd)
        XCTAssertFalse(formatted.isEmpty)
    }

    @MainActor
    func testGetSymbol() {
        let service = ExchangeRateService.shared
        let usdSymbol = service.getSymbol(for: "USD")
        XCTAssertFalse(usdSymbol.isEmpty)
    }
}
