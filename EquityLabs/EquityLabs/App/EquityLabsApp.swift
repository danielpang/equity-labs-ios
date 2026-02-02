import SwiftUI

@main
struct EquityLabsApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var subscriptionManager = SubscriptionManager.shared

    let persistenceController = PersistenceController.shared

    init() {
        // Configure appearance
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated {
                    DashboardView()
                        .environment(\.managedObjectContext, persistenceController.viewContext)
                        .environmentObject(authManager)
                        .environmentObject(subscriptionManager)
                } else {
                    SignInView()
                        .environmentObject(authManager)
                }
            }
            .onAppear {
                Task {
                    await authManager.checkAuthState()
                    if authManager.isAuthenticated {
                        await subscriptionManager.loadSubscriptionState()
                    }
                }
            }
        }
    }

    private func configureAppearance() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance

        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}
