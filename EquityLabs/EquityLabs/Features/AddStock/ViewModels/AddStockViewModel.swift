import Foundation
import SwiftUI
import Combine

// MARK: - AddStockViewModel
@MainActor
class AddStockViewModel: ObservableObject {
    // MARK: - Published Properties

    // Search
    @Published var searchQuery = ""
    @Published var searchResults: [StockSearchResult] = []
    @Published var isSearching = false
    @Published var selectedStock: StockSearchResult?

    // Lot Form
    @Published var shares: String = ""
    @Published var pricePerShare: String = ""
    @Published var purchaseDate = Date()
    @Published var selectedCurrency: Currency = .usd
    @Published var notes = ""

    // State
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var showSuccess = false

    // MARK: - Services

    private let stockService: StockService
    private let portfolioService: PortfolioService
    private var cancellables = Set<AnyCancellable>()
    private var searchCancellable: AnyCancellable?

    init(stockService: StockService = StockService.shared,
         portfolioService: PortfolioService = PortfolioService.shared) {
        self.stockService = stockService
        self.portfolioService = portfolioService

        setupSearchDebouncing()
    }

    // MARK: - Search

    private func setupSearchDebouncing() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                Task {
                    await self?.performSearch(query: query)
                }
            }
            .store(in: &cancellables)
    }

    private func performSearch(query: String) async {
        guard !query.isEmpty, query.count >= 1 else {
            searchResults = []
            return
        }

        isSearching = true
        defer { isSearching = false }

        do {
            let results = try await stockService.searchStocks(query: query)
            self.searchResults = results
            AppLogger.portfolio.debug("Found \(results.count) results for '\(query)'")
        } catch {
            AppLogger.portfolio.error("Search failed: \(error.localizedDescription)")
            searchResults = []
        }
    }

    func selectStock(_ stock: StockSearchResult) {
        selectedStock = stock
        searchQuery = stock.symbol
        searchResults = []

        // Currency will default to USD
        selectedCurrency = .usd
    }

    func clearSelection() {
        selectedStock = nil
        searchQuery = ""
        searchResults = []
    }

    // MARK: - Form Validation

    var sharesValue: Double? {
        Double(shares.replacingOccurrences(of: ",", with: ""))
    }

    var priceValue: Double? {
        Double(pricePerShare.replacingOccurrences(of: ",", with: ""))
    }

    var isFormValid: Bool {
        guard selectedStock != nil,
              let sharesVal = sharesValue,
              let priceVal = priceValue,
              sharesVal > 0,
              priceVal > 0 else {
            return false
        }
        return true
    }

    var validationMessage: String? {
        if selectedStock == nil {
            return "Please search and select a stock"
        }
        if shares.isEmpty {
            return "Please enter number of shares"
        }
        if sharesValue == nil || sharesValue! <= 0 {
            return "Shares must be greater than 0"
        }
        if pricePerShare.isEmpty {
            return "Please enter price per share"
        }
        if priceValue == nil || priceValue! <= 0 {
            return "Price must be greater than 0"
        }
        return nil
    }

    // MARK: - Computed Properties

    var totalCost: Double {
        guard let sharesVal = sharesValue,
              let priceVal = priceValue else {
            return 0
        }
        return sharesVal * priceVal
    }

    var formattedTotalCost: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = selectedCurrency.rawValue
        return formatter.string(from: NSNumber(value: totalCost)) ?? "$0.00"
    }

    // MARK: - Submit

    func addStock() async -> Bool {
        guard isFormValid,
              let stock = selectedStock,
              let sharesVal = sharesValue,
              let priceVal = priceValue else {
            errorMessage = validationMessage ?? "Invalid form data"
            showError = true
            return false
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Create lot
            let lot = StockLot(
                id: UUID().uuidString,
                shares: sharesVal,
                pricePerShare: priceVal,
                purchaseDate: purchaseDate,
                currency: selectedCurrency.rawValue,
                notes: notes.isEmpty ? nil : notes
            )

            // Create stock with lot
            let newStock = Stock(
                symbol: stock.symbol,
                name: stock.name,
                lots: [lot],
                currency: selectedCurrency.rawValue
            )

            // Add to portfolio
            try await portfolioService.addStock(newStock)

            AppLogger.portfolio.info("Added \(sharesVal) shares of \(stock.symbol) at \(selectedCurrency.symbol)\(priceVal)")

            showSuccess = true
            resetForm()
            return true
        } catch {
            errorMessage = "Failed to add stock: \(error.localizedDescription)"
            showError = true
            AppLogger.portfolio.error("Failed to add stock: \(error.localizedDescription)")
            return false
        }
    }

    // MARK: - Form Reset

    func resetForm() {
        selectedStock = nil
        searchQuery = ""
        searchResults = []
        shares = ""
        pricePerShare = ""
        purchaseDate = Date()
        notes = ""
        errorMessage = nil
    }

    // MARK: - Helper Methods

    func formatNumber(_ value: String) -> String {
        // Remove non-numeric characters except decimal point
        let filtered = value.filter { $0.isNumber || $0 == "." }

        // Ensure only one decimal point
        let components = filtered.components(separatedBy: ".")
        if components.count > 2 {
            return components[0] + "." + components[1]
        }

        return filtered
    }

    func dismissError() {
        showError = false
        errorMessage = nil
    }

    func dismissSuccess() {
        showSuccess = false
    }
}
