import Foundation
import Combine

// MARK: - ExchangeRateService
/// Service for fetching and managing currency exchange rates
@MainActor
class ExchangeRateService: ObservableObject {
    static let shared = ExchangeRateService()

    private let apiClient = APIClient.shared
    private let cacheKey = "exchange_rates_cache"
    private let cacheExpirationKey = "exchange_rates_expiration"

    @Published var rates: [String: Double] = [:]
    @Published var isLoading = false
    @Published var error: Error?
    @Published var lastUpdated: Date?

    private init() {
        loadCachedRates()
    }

    // MARK: - Fetch Rates

    /// Fetch latest exchange rates from API
    func fetchExchangeRates(baseCurrency: Currency = .usd) async throws {
        // Check if cached rates are still valid
        if let cachedRates = loadCachedRates(), !isCacheExpired() {
            AppLogger.portfolio.debug("Using cached exchange rates")
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let response: ExchangeRateResponse = try await apiClient.request(.exchangeRate)

            // API returns a single USD→CAD rate. Build rates dict with USD as base.
            let ratesDict: [String: Double] = [
                Currency.usd.rawValue: 1.0,
                Currency.cad.rawValue: response.rate
            ]

            self.rates = ratesDict
            self.lastUpdated = Date()

            cacheRates(ratesDict)
            AppLogger.portfolio.info("Fetched exchange rate: USD→CAD = \(response.rate)")
        } catch {
            AppLogger.portfolio.error("Failed to fetch exchange rates: \(error.localizedDescription)")
            self.error = error
            throw error
        }
    }

    // MARK: - Currency Conversion

    /// Convert amount from one currency to another
    func convert(amount: Double, from: Currency, to: Currency) async throws -> Double {
        // If same currency, no conversion needed
        if from == to {
            return amount
        }

        // Ensure we have fresh rates
        if rates.isEmpty || isCacheExpired() {
            try await fetchExchangeRates()
        }

        // Get exchange rate
        guard let fromRate = getRate(for: from),
              let toRate = getRate(for: to) else {
            throw ExchangeRateError.rateNotAvailable
        }

        // Convert through USD as base
        let amountInUSD = amount / fromRate
        let convertedAmount = amountInUSD * toRate

        AppLogger.portfolio.debug("Converted \(amount) \(from.rawValue) to \(convertedAmount) \(to.rawValue)")
        return convertedAmount
    }

    /// Convert multiple amounts in bulk
    func convertBatch(_ items: [(amount: Double, from: Currency)], to: Currency) async throws -> [Double] {
        // Ensure we have fresh rates
        if rates.isEmpty || isCacheExpired() {
            try await fetchExchangeRates()
        }

        return items.map { item in
            guard item.from != to else { return item.amount }

            if let fromRate = getRate(for: item.from),
               let toRate = getRate(for: to) {
                let amountInUSD = item.amount / fromRate
                return amountInUSD * toRate
            }
            return item.amount // Return original if conversion fails
        }
    }

    /// Get exchange rate for a specific currency
    func getRate(for currency: Currency) -> Double? {
        return rates[currency.rawValue]
    }

    /// Get exchange rate between two currencies
    func getExchangeRate(from: Currency, to: Currency) -> Double? {
        guard from != to else { return 1.0 }

        guard let fromRate = getRate(for: from),
              let toRate = getRate(for: to) else {
            return nil
        }

        // Calculate cross rate through USD
        return toRate / fromRate
    }

    // MARK: - Caching

    @discardableResult
    private func loadCachedRates() -> [String: Double]? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let cached = try? JSONDecoder().decode([String: Double].self, from: data) else {
            return nil
        }

        self.rates = cached

        if let expirationDate = UserDefaults.standard.object(forKey: cacheExpirationKey) as? Date {
            self.lastUpdated = expirationDate
        }

        return cached
    }

    private func cacheRates(_ rates: [String: Double]) {
        if let data = try? JSONEncoder().encode(rates) {
            UserDefaults.standard.set(data, forKey: cacheKey)

            let expirationDate = Date().addingTimeInterval(Constants.Cache.priceCacheDuration)
            UserDefaults.standard.set(expirationDate, forKey: cacheExpirationKey)
        }
    }

    private func isCacheExpired() -> Bool {
        guard let expirationDate = UserDefaults.standard.object(forKey: cacheExpirationKey) as? Date else {
            return true
        }
        return Date() > expirationDate
    }

    /// Clear cached rates (force refresh on next request)
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: cacheKey)
        UserDefaults.standard.removeObject(forKey: cacheExpirationKey)
        rates = [:]
        lastUpdated = nil
        AppLogger.portfolio.debug("Cleared exchange rate cache")
    }

    // MARK: - Helpers

    /// Format amount in target currency
    func formatAmount(_ amount: Double, in currency: Currency, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency.rawValue
        formatter.locale = locale
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }

    /// Get currency symbol
    func getSymbol(for currencyCode: String) -> String {
        let locale = Locale(identifier: "en_US")
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = locale
        return formatter.currencySymbol ?? currencyCode
    }
}

// MARK: - Exchange Rate Response

private struct ExchangeRateResponse: Codable {
    let rate: Double
}

// MARK: - ExchangeRateError

enum ExchangeRateError: LocalizedError {
    case rateNotAvailable
    case conversionFailed
    case cacheExpired

    var errorDescription: String? {
        switch self {
        case .rateNotAvailable:
            return "Exchange rate not available for the requested currency"
        case .conversionFailed:
            return "Currency conversion failed"
        case .cacheExpired:
            return "Exchange rate cache has expired"
        }
    }
}
