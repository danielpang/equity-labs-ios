import SwiftUI

// MARK: - DashboardView
struct DashboardView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @StateObject private var viewModel = DashboardViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    @State private var showSubscription = false

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.isLoading && viewModel.stocks.isEmpty {
                    LoadingView(message: "Loading portfolio...")
                        .transition(.opacity)
                } else if let error = viewModel.error, viewModel.stocks.isEmpty {
                    ErrorView(error: error) {
                        Task {
                            await viewModel.loadPortfolio()
                        }
                    }
                    .transition(.opacity)
                } else if viewModel.stocks.isEmpty {
                    EmptyStateView(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "No Stocks Yet",
                        message: "Start tracking your investments by adding your first stock",
                        actionTitle: "Add Stock"
                    ) {
                        viewModel.showAddStock = true
                    }
                    .transition(.opacity)
                } else {
                    portfolioContent
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: Constants.Animation.standard), value: viewModel.isLoading)
            .animation(.easeInOut(duration: Constants.Animation.standard), value: viewModel.stocks.isEmpty)
            .navigationTitle("EquityLabs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticManager.impact(.light)
                        if canAddStock {
                            viewModel.showAddStock = true
                        } else {
                            showSubscription = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                    .accessibilityLabel("Add stock")
                    .accessibilityHint(canAddStock ? "Opens the add stock form" : "Opens subscription options")
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        HapticManager.impact(.light)
                        viewModel.showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $viewModel.showAddStock) {
                AddStockView()
            }
            .sheet(isPresented: $viewModel.showSettings, onDismiss: {
                Task {
                    await viewModel.reloadPreferences()
                    await settingsViewModel.awaitPendingSync()
                    await viewModel.loadPortfolio()
                }
            }) {
                SettingsView(viewModel: settingsViewModel)
            }
            .sheet(isPresented: $showSubscription) {
                SubscriptionView()
            }
            .task {
                if viewModel.stocks.isEmpty {
                    await viewModel.loadPortfolio()
                }
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
                    ForEach(viewModel.sortedStocks) { stock in
                        NavigationLink(destination: StockDetailView(stock: stock)) {
                            StockCardView(stock: stock)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .trailing)),
                            removal: .opacity.combined(with: .move(edge: .leading))
                        ))
                    }
                }
                .animation(.easeInOut(duration: Constants.Animation.standard), value: viewModel.sortedStocks.map(\.id))
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .refreshable {
            await viewModel.refreshPrices()
            HapticManager.notification(.success)
        }
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
