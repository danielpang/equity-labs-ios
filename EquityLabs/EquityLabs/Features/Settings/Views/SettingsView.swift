import SwiftUI

// MARK: - SettingsView
struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @ObservedObject var viewModel: SettingsViewModel
    @AppStorage(Constants.UserDefaultsKeys.appearanceMode) private var appearanceMode: String = AppearanceMode.system.rawValue
    @State private var showSubscription = false
    @State private var showSignOutConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                // Appearance section
                Section("Appearance") {
                    Picker("Theme", selection: $appearanceMode) {
                        ForEach(AppearanceMode.allCases, id: \.rawValue) { mode in
                            Text(mode.displayName).tag(mode.rawValue)
                        }
                    }
                }

                // Preferences section
                Section("Preferences") {
                    // Currency
                    Picker("Currency", selection: Binding(
                        get: { viewModel.preferences.currency },
                        set: { viewModel.setCurrency($0) }
                    )) {
                        ForEach(Currency.allCases, id: \.self) { currency in
                            Text("\(currency.symbol) \(currency.name)").tag(currency)
                        }
                    }

                    // Sort order
                    Picker("Sort Stocks By", selection: Binding(
                        get: { viewModel.preferences.sortBy },
                        set: { viewModel.setSortBy($0) }
                    )) {
                        ForEach(SortBy.allCases, id: \.self) { sort in
                            Text(sort.displayName).tag(sort)
                        }
                    }

                    // Default chart time range
                    Picker("Default Chart Range", selection: Binding(
                        get: { viewModel.preferences.chartDefaultTimeRange },
                        set: { viewModel.setChartTimeRange($0) }
                    )) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }

                    // Notifications
                    Toggle("Notifications", isOn: Binding(
                        get: { viewModel.preferences.enableNotifications },
                        set: { viewModel.setNotifications($0) }
                    ))

                    // Background refresh
                    Toggle("Background Refresh", isOn: Binding(
                        get: { viewModel.preferences.enableBackgroundRefresh },
                        set: { viewModel.setBackgroundRefresh($0) }
                    ))
                }

                // Subscription section
                Section("Subscription") {
                    HStack {
                        Text("Current Plan")
                        Spacer()
                        Text(subscriptionManager.subscriptionState.tier.displayName)
                            .foregroundColor(.textSecondary)
                    }

                    if subscriptionManager.subscriptionState.tier == .free {
                        Button("Upgrade to Premium") {
                            showSubscription = true
                        }
                        .foregroundColor(.blue)
                    } else {
                        Button("Manage Subscription") {
                            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                UIApplication.shared.open(url)
                            }
                        }
                        .foregroundColor(.blue)
                    }
                }

                // App info section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("\(Constants.App.version) (\(Constants.App.build))")
                            .foregroundColor(.textSecondary)
                    }

                    Link("Privacy Policy", destination: URL(string: Constants.URLs.privacyPolicy)!)
                    Link("Terms of Service", destination: URL(string: Constants.URLs.termsOfService)!)
                    Link("Support", destination: URL(string: Constants.URLs.support)!)
                }

                // Sign out section
                Section {
                    Button("Sign Out") {
                        HapticManager.impact(.medium)
                        showSignOutConfirmation = true
                    }
                    .foregroundColor(.red)
                    .accessibilityLabel("Sign out")
                    .accessibilityHint("Signs you out of your account")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showSubscription) {
                SubscriptionView()
            }
            .confirmationDialog("Sign Out", isPresented: $showSignOutConfirmation, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        await viewModel.signOut()
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .task {
                await viewModel.loadPreferences()
                await viewModel.replayOfflineUpdates()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsView(viewModel: SettingsViewModel())
        .environmentObject(AuthManager.shared)
        .environmentObject(SubscriptionManager.shared)
}
