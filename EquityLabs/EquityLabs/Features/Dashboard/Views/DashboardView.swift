import SwiftUI

// MARK: - DashboardView
struct DashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showSubscription = false

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading {
                    LoadingView(message: "Loading portfolio...")
                } else if let error = viewModel.error {
                    ErrorView(error: error) {
                        Task {
                            await viewModel.loadPortfolio()
                        }
                    }
                } else if viewModel.stocks.isEmpty {
                    EmptyStateView(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "No Stocks Yet",
                        message: "Start tracking your investments by adding your first stock",
                        actionTitle: "Add Stock"
                    ) {
                        viewModel.showAddStock = true
                    }
                } else {
                    portfolioContent
                }
            }
            .navigationTitle("Portfolio")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if canAddStock {
                            viewModel.showAddStock = true
                        } else {
                            showSubscription = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showAddStock) {
                AddStockView()
            }
            .sheet(isPresented: $viewModel.showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showSubscription) {
                SubscriptionView()
            }
            .refreshable {
                await viewModel.refreshPrices()
            }
            .task {
                await viewModel.loadPortfolio()
            }
        }
    }

    private var portfolioContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Portfolio summary
                PortfolioSummaryView(summary: viewModel.summary)
                    .padding(.horizontal)

                // Stock list
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.stocks) { stock in
                        NavigationLink(destination: StockDetailView(stock: stock)) {
                            StockCardView(stock: stock)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color.backgroundPrimary)
    }

    private var canAddStock: Bool {
        subscriptionManager.canAddStock(currentCount: viewModel.stocks.count)
    }
}

// MARK: - Preview
#Preview {
    DashboardView()
        .environmentObject(AuthManager.shared)
        .environmentObject(SubscriptionManager.shared)
        .environment(\.managedObjectContext, PersistenceController.preview.viewContext)
}
