import Foundation
import Combine

// MARK: - AuthManager
@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isAuthenticated = false
    @Published var user: User?
    @Published var isLoading = false
    @Published var error: Error?

    private let keychainManager = KeychainManager.shared
    private let apiClient = APIClient.shared

    private init() {}

    // MARK: - Check Auth State
    func checkAuthState() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let token = try keychainManager.load(forKey: Constants.KeychainKeys.authToken)
            apiClient.setAuthToken(token)

            // TODO: Validate token with backend or Clerk
            // For now, assume token is valid if it exists
            isAuthenticated = true

            AppLogger.authentication.info("User authenticated")
        } catch KeychainError.itemNotFound {
            isAuthenticated = false
            AppLogger.authentication.debug("No auth token found")
        } catch {
            self.error = error
            isAuthenticated = false
            AppLogger.authentication.error("Auth check failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Sign In
    func signIn(token: String, userId: String) async throws {
        isLoading = true
        defer { isLoading = false }

        // Save token to keychain
        try keychainManager.save(token, forKey: Constants.KeychainKeys.authToken)
        try keychainManager.save(userId, forKey: Constants.KeychainKeys.userId)

        // Set token in API client
        apiClient.setAuthToken(token)

        // Load user data
        // TODO: Fetch user data from backend
        user = User(id: userId)

        isAuthenticated = true
        AppLogger.authentication.info("User signed in successfully")
    }

    // MARK: - Sign Out
    func signOut() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Clear keychain
            try keychainManager.deleteAll()

            // Clear API client token
            apiClient.setAuthToken(nil)

            // Clear user data
            user = nil
            isAuthenticated = false

            AppLogger.authentication.info("User signed out")
        } catch {
            self.error = error
            AppLogger.authentication.error("Sign out failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Get Current Token
    var currentToken: String? {
        get async throws {
            try keychainManager.load(forKey: Constants.KeychainKeys.authToken)
        }
    }

    // MARK: - Refresh Token
    func refreshToken() async throws {
        // TODO: Implement token refresh with Clerk
        AppLogger.authentication.debug("Token refresh not yet implemented")
    }
}
