import SwiftUI

// MARK: - PortfolioSummaryView
struct PortfolioSummaryView: View {
    let summary: PortfolioSummary?
    @ScaledMetric(relativeTo: .largeTitle) private var totalValueSize: CGFloat = 36

    var body: some View {
        VStack(spacing: 16) {
            // Total value
            VStack(spacing: 4) {
                Text("Total Value (\(summary?.currency.rawValue ?? "USD"))")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)

                Text(summary?.totalValue.toCurrency(currency: summary?.currency ?? .usd) ?? "$0.00")
                    .font(.system(size: totalValueSize, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .minimumScaleFactor(0.6)

                if let dayChange = summary?.totalDayChange,
                   let dayChangePercent = summary?.totalDayChangePercentage {
                    HStack(spacing: 4) {
                        Image(systemName: dayChange >= 0 ? "arrow.up" : "arrow.down")
                        Text("\(dayChange.toCurrency(currency: summary?.currency ?? .usd)) (\(dayChangePercent.toPercentage()))")
                    }
                    .font(.subheadline)
                    .foregroundColor(Color.profitLoss(value: dayChange))
                }
            }

            Divider()

            // Summary stats
            HStack(spacing: 32) {
                StatView(
                    title: "Cost",
                    value: summary?.totalCost.toCurrency(currency: summary?.currency ?? .usd, decimals: 0) ?? "$0",
                    color: .textSecondary
                )

                Divider()
                    .frame(height: 40)

                StatView(
                    title: "P/L",
                    value: summary?.totalProfitLoss.toCurrency(currency: summary?.currency ?? .usd, decimals: 0) ?? "$0",
                    valueColor: summary != nil ? Color.profitLoss(value: summary!.totalProfitLoss) : .textPrimary,
                    subtitle: summary?.totalProfitLossPercentage.toPercentage(),
                    color: .textSecondary
                )

                Divider()
                    .frame(height: 40)

                StatView(
                    title: "Stocks",
                    value: "\(summary?.stockCount ?? 0)",
                    color: .textSecondary
                )
            }
        }
        .glassCardStyle()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(summaryAccessibilityLabel)
    }

    private var summaryAccessibilityLabel: String {
        guard let summary else { return "Portfolio summary unavailable" }
        var label = "Total portfolio value \(summary.totalValue.toCurrency(currency: summary.currency))"
        if let dayChange = summary.totalDayChange {
            let direction = dayChange >= 0 ? "up" : "down"
            label += ", \(direction) \(abs(dayChange).toCurrency(currency: summary.currency)) today"
        }
        label += ", total cost \(summary.totalCost.toCurrency(currency: summary.currency))"
        let plDirection = summary.totalProfitLoss >= 0 ? "profit" : "loss"
        label += ", \(plDirection) \(abs(summary.totalProfitLoss).toCurrency(currency: summary.currency))"
        label += ", \(summary.stockCount) stocks"
        return label
    }
}

// MARK: - StatView
private struct StatView: View {
    let title: String
    let value: String
    var valueColor: Color = .textPrimary
    var subtitle: String? = nil
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(color)

            Text(value)
                .font(.headline)
                .foregroundColor(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(valueColor)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview
#Preview {
    let portfolio = Portfolio(stocks: [
        Stock(symbol: "AAPL", name: "Apple Inc.", lots: [
            StockLot(shares: 10, pricePerShare: 140)
        ], currentPrice: 150, previousClose: 148)
    ])
    let summary = PortfolioSummary(portfolio: portfolio)

    PortfolioSummaryView(summary: summary)
        .padding()
        .background(Color.backgroundPrimary)
}
