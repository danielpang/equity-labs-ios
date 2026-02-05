import SwiftUI
import Clerk

@main
struct EquityLabsApp: App {
    @State private var clerk = Clerk.shared
    @StateObject private var authService = AuthService.shared
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
                if authManager.isAuthReady && authService.isAuthenticated {
                    // Show dashboard only after auth is fully initialized
                    DashboardView()
                        .environment(\.managedObjectContext, persistenceController.viewContext)
                        .environment(\.clerk, clerk)
                        .environmentObject(authService)
                        .environmentObject(authManager)
                        .environmentObject(subscriptionManager)
                } else if authManager.isAuthReady {
                    // Auth is ready but user is not authenticated
                    SignInView()
                        .environment(\.clerk, clerk)
                        .environmentObject(authService)
                        .environmentObject(authManager)
                } else {
                    // Loading state while auth is initializing
                    LoadingView(message: "Initializing...")
                }
            }
            .task {
                // Initialize Clerk and authentication
                do {
                    AppLogger.authentication.info("🚀 Starting app initialization...")
                    try await authService.configure()
                    AppLogger.authentication.info("✅ Clerk configured")

                    await authManager.checkAuthState()
                    AppLogger.authentication.info("✅ Auth state checked")

                    if authService.isAuthenticated {
                        await subscriptionManager.loadSubscriptionState()
                        AppLogger.authentication.info("✅ Subscription state loaded")
                    }

                    AppLogger.authentication.info("🎉 App initialization complete - Ready for API calls")
                } catch {
                    AppLogger.authentication.error("❌ App initialization failed: \(error.localizedDescription)")
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
