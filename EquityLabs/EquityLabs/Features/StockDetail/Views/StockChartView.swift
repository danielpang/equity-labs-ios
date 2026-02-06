import SwiftUI
import Charts

// MARK: - StockChartView
struct StockChartView: View {
    let data: [HistoricalDataPoint]
    let lots: [StockLot]
    let selectedRange: TimeRange
    let onRangeChange: (TimeRange) -> Void

    @State private var selectedPoint: HistoricalDataPoint?

    var body: some View {
        VStack(spacing: 16) {
            // Chart
            if data.isEmpty {
                emptyChartView
            } else {
                chartView
            }

            // Time Range Selector
            timeRangeSelector
        }
        .padding()
    }

    // MARK: - Chart View

    private var chartView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Selected Point Info
            if let point = selectedPoint {
                selectedPointInfo(point)
            }

            // Chart
            Chart {
                // Price Line
                ForEach(data) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Price", point.close)
                    )
                    .foregroundStyle(chartColor)
                    .interpolationMethod(.catmullRom)

                    // Area Fill
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Price", point.close)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [chartColor.opacity(0.3), chartColor.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                }

                // Lot Price Indicators (horizontal lines)
                ForEach(lots) { lot in
                    RuleMark(y: .value("Lot Price", lot.pricePerShare))
                        .foregroundStyle(.orange.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .annotation(position: .trailing, alignment: .center) {
                            Text("$\(lot.pricePerShare, specifier: "%.2f")")
                                .font(.caption2)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(.orange.opacity(0.1))
                                .cornerRadius(4)
                        }
                }

                // Average Cost Line
                if !lots.isEmpty {
                    let avgCost = lots.reduce(0) { $0 + ($1.shares * $1.pricePerShare) } /
                                  lots.reduce(0) { $0 + $1.shares }

                    RuleMark(y: .value("Average Cost", avgCost))
                        .foregroundStyle(.blue.opacity(0.7))
                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [10, 5]))
                        .annotation(position: .trailing, alignment: .center) {
                            Text("Avg: $\(avgCost, specifier: "%.2f")")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(.blue.opacity(0.1))
                                .cornerRadius(6)
                        }
                }

                // Selection Indicator
                if let point = selectedPoint {
                    RuleMark(x: .value("Selected", point.date))
                        .foregroundStyle(.gray.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1))

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Price", point.close)
                    )
                    .foregroundStyle(chartColor)
                    .symbolSize(100)
                }
            }
            .frame(height: 300)
            .chartXAxis {
                AxisMarks(values: .stride(by: xAxisStride)) { _ in
                    AxisValueLabel(format: xAxisFormat)
                    AxisGridLine()
                }
            }
            .chartYAxis {
                AxisMarks(position: .trailing) { value in
                    AxisValueLabel {
                        if let price = value.as(Double.self) {
                            Text("$\(price, specifier: "%.2f")")
                        }
                    }
                    AxisGridLine()
                }
            }
            .chartYScale(domain: yAxisDomain)
            .chartPlotStyle { plotArea in
                plotArea.clipped()
            }
            .chartGesture { chart in
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        updateSelection(at: value.location, chart: chart)
                    }
                    .onEnded { _ in
                        selectedPoint = nil
                    }
            }
        }
    }

    // MARK: - Empty Chart View

    private var emptyChartView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 50))
                .foregroundColor(.textSecondary)

            Text("No Chart Data Available")
                .font(.headline)
                .foregroundColor(.textSecondary)

            Text("Historical data will appear here")
                .font(.subheadline)
                .foregroundColor(.textTertiary)
        }
        .frame(height: 300)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Selected Point Info

    private func selectedPointInfo(_ point: HistoricalDataPoint) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(point.date, style: .date)
                .font(.caption)
                .foregroundColor(.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("$\(point.close, specifier: "%.2f")")
                    .font(.title2)
                    .fontWeight(.bold)

                if let change = priceChange(for: point) {
                    Text(change.formatted)
                        .font(.subheadline)
                        .foregroundColor(change.value >= 0 ? .green : .red)
                }
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Time Range Selector

    private var timeRangeSelector: some View {
        HStack(spacing: 8) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button {
                    onRangeChange(range)
                } label: {
                    Text(range.rawValue)
                        .font(.caption)
                        .fontWeight(selectedRange == range ? .bold : .regular)
                        .foregroundColor(selectedRange == range ? .white : .accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedRange == range ? Color.accentColor : Color.clear)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.accentColor, lineWidth: 1)
                        )
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func updateSelection(at location: CGPoint, chart: ChartProxy) {
        guard let xValue = chart.value(atX: location.x, as: Date.self) else {
            return
        }

        selectedPoint = data.min(by: {
            abs($0.date.timeIntervalSince(xValue)) < abs($1.date.timeIntervalSince(xValue))
        })
    }

    private func priceChange(for point: HistoricalDataPoint) -> (value: Double, formatted: String)? {
        guard let index = data.firstIndex(where: { $0.id == point.id }),
              index > 0 else {
            return nil
        }

        let previousPrice = data[index - 1].close
        let change = point.close - previousPrice
        let changePercent = (change / previousPrice) * 100

        let formatted = String(format: "%+.2f (%+.2f%%)", change, changePercent)
        return (change, formatted)
    }

    // MARK: - Chart Configuration

    private var chartColor: Color {
        guard let first = data.first, let last = data.last else {
            return .accentColor
        }
        return last.close >= first.close ? .green : .red
    }

    private var yAxisDomain: ClosedRange<Double> {
        let prices = data.map { $0.close }
        let lotPrices = lots.map { $0.pricePerShare }
        let allPrices = prices + lotPrices

        guard !allPrices.isEmpty else {
            return 0...100
        }

        let min = allPrices.min() ?? 0
        let max = allPrices.max() ?? 100
        let padding = (max - min) * 0.1

        return (min - padding)...(max + padding)
    }

    private var xAxisStride: Calendar.Component {
        switch selectedRange {
        case .oneDay:
            return .hour
        case .oneWeek:
            return .day
        case .oneMonth:
            return .weekOfYear
        case .threeMonths, .sixMonths:
            return .month
        case .oneYear:
            return .month
        case .fiveYears, .tenYears:
            return .year
        }
    }

    private var xAxisFormat: Date.FormatStyle {
        switch selectedRange {
        case .oneDay:
            return .dateTime.hour()
        case .oneWeek, .oneMonth:
            return .dateTime.month(.abbreviated).day()
        case .threeMonths, .sixMonths, .oneYear, .fiveYears, .tenYears:
            return .dateTime.month(.abbreviated)
        }
    }
}

// MARK: - Preview
#Preview {
    let sampleData = [
        HistoricalDataPoint(date: Date().addingTimeInterval(-86400 * 30), open: 150, high: 155, low: 148, close: 152, volume: 1000000),
        HistoricalDataPoint(date: Date().addingTimeInterval(-86400 * 25), open: 152, high: 158, low: 150, close: 156, volume: 1100000),
        HistoricalDataPoint(date: Date().addingTimeInterval(-86400 * 20), open: 156, high: 160, low: 154, close: 158, volume: 1200000),
        HistoricalDataPoint(date: Date().addingTimeInterval(-86400 * 15), open: 158, high: 162, low: 156, close: 160, volume: 1300000),
        HistoricalDataPoint(date: Date().addingTimeInterval(-86400 * 10), open: 160, high: 165, low: 158, close: 163, volume: 1400000),
        HistoricalDataPoint(date: Date().addingTimeInterval(-86400 * 5), open: 163, high: 168, low: 161, close: 165, volume: 1500000),
        HistoricalDataPoint(date: Date(), open: 165, high: 170, low: 163, close: 168, volume: 1600000)
    ]

    let sampleLots = [
        StockLot(id: UUID().uuidString, shares: 10, pricePerShare: 155, purchaseDate: Date().addingTimeInterval(-86400 * 20), currency: "USD", notes: nil)
    ]

    StockChartView(
        data: sampleData,
        lots: sampleLots,
        selectedRange: .oneMonth,
        onRangeChange: { _ in }
    )
}
