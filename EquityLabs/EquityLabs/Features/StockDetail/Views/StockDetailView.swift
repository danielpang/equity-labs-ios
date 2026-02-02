import SwiftUI

// MARK: - StockDetailView
struct StockDetailView: View {
    let stock: Stock

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text(stock.symbol)
                        .font(.title.bold())

                    Text(stock.name)
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)

                    if let price = stock.currentPrice {
                        Text(price.toCurrency(currency: Currency(rawValue: stock.currency) ?? .usd))
                            .font(.title2.bold())
                    }
                }
                .padding()

                Text("Stock detail will be implemented in Phase 4")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .padding()

                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        StockDetailView(stock: Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            lots: [StockLot(shares: 10, pricePerShare: 140)],
            currentPrice: 150,
            previousClose: 148
        ))
    }
}
