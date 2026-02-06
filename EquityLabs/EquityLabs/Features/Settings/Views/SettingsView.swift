import SwiftUI

// MARK: - SettingsView
struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @AppStorage(Constants.UserDefaultsKeys.appearanceMode) private var appearanceMode: String = AppearanceMode.system.rawValue

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
                            // TODO: Show subscription view in Phase 5
                        }
                        .foregroundColor(.blue)
                    }
                }

                // App info section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Constants.App.version)
                            .foregroundColor(.textSecondary)
                    }

                    Link("Privacy Policy", destination: URL(string: Constants.URLs.privacyPolicy)!)
                    Link("Terms of Service", destination: URL(string: Constants.URLs.termsOfService)!)
                    Link("Support", destination: URL(string: Constants.URLs.support)!)
                }

                // Sign out section
                Section {
                    Button("Sign Out") {
                        Task {
                            await authManager.signOut()
                            dismiss()
                        }
                    }
                    .foregroundColor(.red)
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
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
        .environmentObject(AuthManager.shared)
        .environmentObject(SubscriptionManager.shared)
}
