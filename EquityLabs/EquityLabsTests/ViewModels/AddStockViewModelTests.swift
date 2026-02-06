import XCTest
@testable import EquityLabs

final class AddStockViewModelTests: XCTestCase {

    // MARK: - Initial State

    @MainActor
    func testInitialState() {
        let vm = AddStockViewModel()
        XCTAssertEqual(vm.searchQuery, "")
        XCTAssertTrue(vm.searchResults.isEmpty)
        XCTAssertFalse(vm.isSearching)
        XCTAssertNil(vm.selectedStock)
        XCTAssertEqual(vm.shares, "")
        XCTAssertEqual(vm.pricePerShare, "")
        XCTAssertEqual(vm.selectedCurrency, .usd)
        XCTAssertEqual(vm.notes, "")
        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
        XCTAssertFalse(vm.showError)
        XCTAssertFalse(vm.showSuccess)
    }

    // MARK: - Form Validation

    @MainActor
    func testFormInvalidNoStock() {
        let vm = AddStockViewModel()
        vm.shares = "10"
        vm.pricePerShare = "150"
        XCTAssertFalse(vm.isFormValid)
    }

    @MainActor
    func testFormInvalidNoShares() {
        let vm = AddStockViewModel()
        vm.selectedStock = StockSearchResult(symbol: "AAPL", name: "Apple", exchange: nil, type: nil)
        vm.pricePerShare = "150"
        XCTAssertFalse(vm.isFormValid)
    }

    @MainActor
    func testFormInvalidNoPrice() {
        let vm = AddStockViewModel()
        vm.selectedStock = StockSearchResult(symbol: "AAPL", name: "Apple", exchange: nil, type: nil)
        vm.shares = "10"
        XCTAssertFalse(vm.isFormValid)
    }

    @MainActor
    func testFormInvalidZeroShares() {
        let vm = AddStockViewModel()
        vm.selectedStock = StockSearchResult(symbol: "AAPL", name: "Apple", exchange: nil, type: nil)
        vm.shares = "0"
        vm.pricePerShare = "150"
        XCTAssertFalse(vm.isFormValid)
    }

    @MainActor
    func testFormInvalidZeroPrice() {
        let vm = AddStockViewModel()
        vm.selectedStock = StockSearchResult(symbol: "AAPL", name: "Apple", exchange: nil, type: nil)
        vm.shares = "10"
        vm.pricePerShare = "0"
        XCTAssertFalse(vm.isFormValid)
    }

    @MainActor
    func testFormValid() {
        let vm = AddStockViewModel()
        vm.selectedStock = StockSearchResult(symbol: "AAPL", name: "Apple", exchange: nil, type: nil)
        vm.shares = "10"
        vm.pricePerShare = "150"
        XCTAssertTrue(vm.isFormValid)
    }

    @MainActor
    func testFormInvalidNonNumericShares() {
        let vm = AddStockViewModel()
        vm.selectedStock = StockSearchResult(symbol: "AAPL", name: "Apple", exchange: nil, type: nil)
        vm.shares = "abc"
        vm.pricePerShare = "150"
        XCTAssertFalse(vm.isFormValid)
    }

    // MARK: - Validation Messages

    @MainActor
    func testValidationMessageNoStock() {
        let vm = AddStockViewModel()
        XCTAssertEqual(vm.validationMessage, "Please search and select a stock")
    }

    @MainActor
    func testValidationMessageNoShares() {
        let vm = AddStockViewModel()
        vm.selectedStock = StockSearchResult(symbol: "AAPL", name: "Apple", exchange: nil, type: nil)
        XCTAssertEqual(vm.validationMessage, "Please enter number of shares")
    }

    @MainActor
    func testValidationMessageInvalidShares() {
        let vm = AddStockViewModel()
        vm.selectedStock = StockSearchResult(symbol: "AAPL", name: "Apple", exchange: nil, type: nil)
        vm.shares = "-1"
        XCTAssertNotNil(vm.validationMessage)
    }

    @MainActor
    func testValidationMessageNoPrice() {
        let vm = AddStockViewModel()
        vm.selectedStock = StockSearchResult(symbol: "AAPL", name: "Apple", exchange: nil, type: nil)
        vm.shares = "10"
        XCTAssertEqual(vm.validationMessage, "Please enter price per share")
    }

    @MainActor
    func testValidationMessageNilWhenValid() {
        let vm = AddStockViewModel()
        vm.selectedStock = StockSearchResult(symbol: "AAPL", name: "Apple", exchange: nil, type: nil)
        vm.shares = "10"
        vm.pricePerShare = "150"
        XCTAssertNil(vm.validationMessage)
    }

    // MARK: - Computed Values

    @MainActor
    func testSharesValue() {
        let vm = AddStockViewModel()
        vm.shares = "10.5"
        XCTAssertEqual(vm.sharesValue, 10.5)
    }

    @MainActor
    func testSharesValueWithComma() {
        let vm = AddStockViewModel()
        vm.shares = "1,000"
        XCTAssertEqual(vm.sharesValue, 1000)
    }

    @MainActor
    func testPriceValue() {
        let vm = AddStockViewModel()
        vm.pricePerShare = "150.75"
        XCTAssertEqual(vm.priceValue, 150.75)
    }

    @MainActor
    func testTotalCost() {
        let vm = AddStockViewModel()
        vm.shares = "10"
        vm.pricePerShare = "150"
        XCTAssertEqual(vm.totalCost, 1500)
    }

    @MainActor
    func testTotalCostInvalid() {
        let vm = AddStockViewModel()
        vm.shares = ""
        vm.pricePerShare = ""
        XCTAssertEqual(vm.totalCost, 0)
    }

    @MainActor
    func testFormattedTotalCost() {
        let vm = AddStockViewModel()
        vm.shares = "10"
        vm.pricePerShare = "150"
        let formatted = vm.formattedTotalCost
        XCTAssertFalse(formatted.isEmpty)
    }

    // MARK: - formatNumber

    @MainActor
    func testFormatNumberBasic() {
        let vm = AddStockViewModel()
        XCTAssertEqual(vm.formatNumber("123.45"), "123.45")
    }

    @MainActor
    func testFormatNumberStripsInvalid() {
        let vm = AddStockViewModel()
        XCTAssertEqual(vm.formatNumber("$1,234.56"), "1234.56")
    }

    @MainActor
    func testFormatNumberMultipleDecimals() {
        let vm = AddStockViewModel()
        let result = vm.formatNumber("12.34.56")
        // Should keep only first decimal
        XCTAssertEqual(result, "12.34")
    }

    @MainActor
    func testFormatNumberLetters() {
        let vm = AddStockViewModel()
        XCTAssertEqual(vm.formatNumber("abc"), "")
    }

    @MainActor
    func testFormatNumberEmpty() {
        let vm = AddStockViewModel()
        XCTAssertEqual(vm.formatNumber(""), "")
    }

    // MARK: - Select Stock

    @MainActor
    func testSelectStock() {
        let vm = AddStockViewModel()
        let result = StockSearchResult(symbol: "AAPL", name: "Apple Inc.", exchange: "NASDAQ", type: "stock")

        vm.selectStock(result)

        XCTAssertEqual(vm.selectedStock?.symbol, "AAPL")
        XCTAssertEqual(vm.searchQuery, "AAPL")
        XCTAssertTrue(vm.searchResults.isEmpty)
        XCTAssertEqual(vm.selectedCurrency, .usd)
    }

    // MARK: - Clear Selection

    @MainActor
    func testClearSelection() {
        let vm = AddStockViewModel()
        let result = StockSearchResult(symbol: "AAPL", name: "Apple Inc.", exchange: nil, type: nil)
        vm.selectStock(result)

        vm.clearSelection()

        XCTAssertNil(vm.selectedStock)
        XCTAssertEqual(vm.searchQuery, "")
        XCTAssertTrue(vm.searchResults.isEmpty)
    }

    // MARK: - Reset Form

    @MainActor
    func testResetForm() {
        let vm = AddStockViewModel()
        vm.selectedStock = StockSearchResult(symbol: "AAPL", name: "Apple", exchange: nil, type: nil)
        vm.searchQuery = "AAPL"
        vm.shares = "10"
        vm.pricePerShare = "150"
        vm.notes = "Test note"
        vm.errorMessage = "Some error"

        vm.resetForm()

        XCTAssertNil(vm.selectedStock)
        XCTAssertEqual(vm.searchQuery, "")
        XCTAssertTrue(vm.searchResults.isEmpty)
        XCTAssertEqual(vm.shares, "")
        XCTAssertEqual(vm.pricePerShare, "")
        XCTAssertEqual(vm.notes, "")
        XCTAssertNil(vm.errorMessage)
    }

    // MARK: - Dismiss Helpers

    @MainActor
    func testDismissError() {
        let vm = AddStockViewModel()
        vm.showError = true
        vm.errorMessage = "Test error"

        vm.dismissError()

        XCTAssertFalse(vm.showError)
        XCTAssertNil(vm.errorMessage)
    }

    @MainActor
    func testDismissSuccess() {
        let vm = AddStockViewModel()
        vm.showSuccess = true

        vm.dismissSuccess()

        XCTAssertFalse(vm.showSuccess)
    }

    // MARK: - Add Stock Without Selection

    @MainActor
    func testAddStockFailsWithoutSelection() async {
        let vm = AddStockViewModel()
        vm.shares = "10"
        vm.pricePerShare = "150"

        let result = await vm.addStock()

        XCTAssertFalse(result)
        XCTAssertTrue(vm.showError)
        XCTAssertNotNil(vm.errorMessage)
    }
}
