import SwiftUI

// MARK: - StockDetailView
struct StockDetailView: View {
    @StateObject private var viewModel: StockDetailViewModel
    @Environment(\.dismiss) private var dismiss

    init(stock: Stock) {
        _viewModel = StateObject(wrappedValue: StockDetailViewModel(stock: stock))
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Header - Price Info
                    priceHeader

                    // Tab Selector
                    tabSelector

                    // Tab Content
                    tabContent
                }
            }
            .refreshable {
                await viewModel.loadData()
            }

            // Loading Overlay
            if viewModel.isLoading {
                LoadingView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(viewModel.stock.symbol)
                        .font(.headline)
                    Text(viewModel.stock.name)
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task {
                        await viewModel.refreshPrice()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task {
            await viewModel.loadData()
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil), presenting: viewModel.error) { _ in
            Button("OK") {
                viewModel.error = nil
            }
        } message: { error in
            Text(error.localizedDescription)
        }
    }

    // MARK: - Price Header

    private var priceHeader: some View {
        VStack(spacing: 16) {
            // Current Price
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(viewModel.formatPrice(viewModel.currentPrice))
                    .font(.system(size: 36, weight: .bold))

                if let change = viewModel.priceChange,
                   let changePercent = viewModel.priceChangePercent {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.formatPrice(change))
                            .font(.subheadline)
                            .foregroundColor(change >= 0 ? .green : .red)

                        Text(viewModel.formatPercent(changePercent))
                            .font(.caption)
                            .foregroundColor(change >= 0 ? .green : .red)
                    }
                }
            }

            // Portfolio Summary
            HStack(spacing: 20) {
                // Total Value
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Value")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                    Text(viewModel.formatPrice(viewModel.totalValue))
                        .font(.headline)
                }

                Spacer()

                // Gain/Loss
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total Gain/Loss")
                        .font(.caption)
                        .foregroundColor(.textSecondary)

                    HStack(spacing: 8) {
                        Text(viewModel.formatPrice(viewModel.gainLoss))
                            .font(.headline)
                            .foregroundColor(viewModel.gainLoss >= 0 ? .green : .red)

                        Text(viewModel.formatPercent(viewModel.gainLossPercent))
                            .font(.subheadline)
                            .foregroundColor(viewModel.gainLoss >= 0 ? .green : .red)
                    }
                }
            }
            .padding(.horizontal)

            Divider()
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                Button {
                    viewModel.selectedTab = tab
                } label: {
                    VStack(spacing: 8) {
                        Text(tab.rawValue)
                            .font(.subheadline)
                            .fontWeight(viewModel.selectedTab == tab ? .semibold : .regular)
                            .foregroundColor(viewModel.selectedTab == tab ? .accentColor : .textSecondary)

                        Rectangle()
                            .fill(viewModel.selectedTab == tab ? Color.accentColor : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch viewModel.selectedTab {
        case .overview:
            overviewTab
        case .lots:
            lotsTab
        case .news:
            newsTab
        }
    }

    // MARK: - Overview Tab

    private var overviewTab: some View {
        VStack(spacing: 20) {
            // Chart
            StockChartView(
                data: viewModel.historicalData,
                lots: viewModel.stock.lots,
                selectedRange: viewModel.selectedTimeRange,
                onRangeChange: { range in
                    Task {
                        await viewModel.changeTimeRange(range)
                    }
                }
            )

            // Stats Grid
            statsGrid

            Spacer()
        }
        .padding(.top)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            // Total Shares
            StatCardView(
                title: "Total Shares",
                value: viewModel.formatShares(viewModel.totalShares),
                icon: "chart.bar.fill",
                color: .blue
            )

            // Average Cost
            StatCardView(
                title: "Average Cost",
                value: viewModel.formatPrice(viewModel.averageCost),
                icon: "dollarsign.circle.fill",
                color: .orange
            )

            // Total Cost
            StatCardView(
                title: "Total Cost",
                value: viewModel.formatPrice(viewModel.totalCost),
                icon: "banknote.fill",
                color: .purple
            )

            // Number of Lots
            StatCardView(
                title: "Lots",
                value: "\(viewModel.stock.lots.count)",
                icon: "square.stack.3d.up.fill",
                color: .green
            )
        }
        .padding(.horizontal)
    }

    // MARK: - Lots Tab

    private var lotsTab: some View {
        StockLotsListView(
            stock: viewModel.stock,
            onAddLot: { lot in
                Task {
                    await viewModel.addLot(lot)
                }
            },
            onUpdateLot: { lot in
                Task {
                    await viewModel.updateLot(lot)
                }
            },
            onDeleteLot: { lot in
                Task {
                    await viewModel.deleteLot(lot)
                }
            }
        )
    }

    // MARK: - News Tab

    private var newsTab: some View {
        VStack(spacing: 0) {
            if viewModel.isLoadingNews {
                ProgressView()
                    .padding()
            } else if viewModel.newsArticles.isEmpty {
                emptyNewsView
            } else {
                newsListView
            }
        }
    }

    private var emptyNewsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "newspaper")
                .font(.system(size: 50))
                .foregroundColor(.textSecondary)

            Text("No News Available")
                .font(.headline)
                .foregroundColor(.textSecondary)

            Text("Check back later for updates")
                .font(.subheadline)
                .foregroundColor(.textTertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var newsListView: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.newsArticles) { article in
                NewsArticleCard(article: article)
            }
        }
        .padding()
    }
}

// MARK: - StatCardView
struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
                Spacer()
            }

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - NewsArticleCard
struct NewsArticleCard: View {
    let article: NewsArticle

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Source and Date
            HStack {
                Text(article.source)
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                Spacer()

                Text(article.publishedAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.textTertiary)
            }

            // Title
            Text(article.title)
                .font(.headline)
                .lineLimit(3)

            // Summary (if available)
            if let summary = article.summary {
                Text(summary)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .lineLimit(2)
            }

            // Sentiment (if available)
            if let sentiment = article.sentiment {
                HStack(spacing: 4) {
                    Text(sentiment.label.emoji)
                    Text(sentiment.label.displayName)
                        .font(.caption)
                        .foregroundColor(sentimentColor(for: sentiment.label))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(sentimentColor(for: sentiment.label).opacity(0.1))
                .cornerRadius(8)
            }

            // Link
            Link(destination: URL(string: article.url)!) {
                HStack {
                    Text("Read More")
                        .font(.subheadline)
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func sentimentColor(for label: SentimentLabel) -> Color {
        switch label {
        case .positive:
            return .green
        case .neutral:
            return .gray
        case .negative:
            return .red
        }
    }
}

// MARK: - Preview
#Preview("With Data") {
    NavigationStack {
        StockDetailView(stock: Stock(
            id: "1",
            symbol: "AAPL",
            name: "Apple Inc.",
            lots: [
                StockLot(
                    id: UUID().uuidString,
                    shares: 10,
                    pricePerShare: 140.00,
                    purchaseDate: Date().addingTimeInterval(-86400 * 60),
                    currency: "USD",
                    notes: "Initial purchase"
                ),
                StockLot(
                    id: UUID().uuidString,
                    shares: 5,
                    pricePerShare: 150.00,
                    purchaseDate: Date().addingTimeInterval(-86400 * 30),
                    currency: "USD",
                    notes: nil
                )
            ],
            currentPrice: 165.00,
            previousClose: 163.00,
            currency: "USD",
            lastUpdated: Date()
        ))
    }
}

#Preview("Empty Lots") {
    NavigationStack {
        StockDetailView(stock: Stock(
            id: "1",
            symbol: "TSLA",
            name: "Tesla, Inc.",
            lots: [],
            currentPrice: 250.00,
            previousClose: 245.00,
            currency: "USD",
            lastUpdated: Date()
        ))
    }
}
