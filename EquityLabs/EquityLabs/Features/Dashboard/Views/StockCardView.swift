import SwiftUI

// MARK: - StockCardView
struct StockCardView: View {
    let stock: Stock

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Symbol circle
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)

                Text(stock.symbol.prefix(2))
                    .font(.headline.bold())
                    .foregroundColor(.blue)
            }

            // Stock info
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.symbol)
                    .font(.headline)
                    .foregroundColor(.textPrimary)

                Text(stock.name)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text("\(stock.totalShares, specifier: "%.2f") shares")
                        .font(.caption)
                        .foregroundColor(.textTertiary)

                    Text("•")
                        .foregroundColor(.textTertiary)

                    Text("Avg \(stock.averageCost.toCurrency())")
                        .font(.caption)
                        .foregroundColor(.textTertiary)
                }
            }

            Spacer()

            // Price info
            VStack(alignment: .trailing, spacing: 4) {
                if let price = stock.currentPrice {
                    Text(price.toCurrency(currency: Currency(rawValue: stock.currency) ?? .usd))
                        .font(.headline)
                        .foregroundColor(.textPrimary)
                } else {
                    Text("--")
                        .font(.headline)
                        .foregroundColor(.textSecondary)
                }

                if let dayChange = stock.dayChange,
                   let dayChangePercent = stock.dayChangePercentage {
                    HStack(spacing: 4) {
                        Image(systemName: dayChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.caption2)

                        Text(dayChangePercent.toPercentage(decimals: 2, showSign: false))
                            .font(.caption)
                    }
                    .foregroundColor(Color.profitLoss(value: dayChange))
                }

                // P/L
                HStack(spacing: 4) {
                    Text(stock.profitLoss.toCurrency(currency: Currency(rawValue: stock.currency) ?? .usd, showSymbol: false))
                    Text("(\(stock.profitLossPercentage.toPercentage(showSign: false)))")
                }
                .font(.caption2)
                .foregroundColor(Color.profitLoss(value: stock.profitLoss))
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(Constants.Layout.cornerRadius)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(stockAccessibilityLabel)
    }

    private var stockAccessibilityLabel: String {
        var label = "\(stock.name), \(stock.symbol)"
        if let price = stock.currentPrice {
            label += ", current price \(price.toCurrency(currency: Currency(rawValue: stock.currency) ?? .usd))"
        }
        label += ", \(stock.totalShares) shares"
        let plDirection = stock.profitLoss >= 0 ? "gain" : "loss"
        label += ", \(plDirection) \(abs(stock.profitLoss).toCurrency(currency: Currency(rawValue: stock.currency) ?? .usd))"
        return label
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 12) {
        StockCardView(stock: Stock(
            symbol: "AAPL",
            name: "Apple Inc.",
            lots: [StockLot(shares: 10, pricePerShare: 140)],
            currentPrice: 150,
            previousClose: 148
        ))

        StockCardView(stock: Stock(
            symbol: "GOOGL",
            name: "Alphabet Inc.",
            lots: [StockLot(shares: 5, pricePerShare: 2800)],
            currentPrice: 2750,
            previousClose: 2760
        ))
    }
    .padding()
    .background(Color.backgroundPrimary)
}
