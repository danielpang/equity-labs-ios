import Foundation
import Combine

// MARK: - AuthManager
@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isAuthenticated = false
    @Published var isAuthReady = false  // True when auth is fully initialized and token is set
    @Published var user: User?
    @Published var isLoading = false
    @Published var error: Error?

    private let keychainManager = KeychainManager.shared
    private let apiClient = APIClient.shared
    private let authService = AuthService.shared

    private init() {}

    // MARK: - Check Auth State
    func checkAuthState() async {
        isLoading = true
        isAuthReady = false
        defer {
            isLoading = false
            isAuthReady = true  // Mark auth as ready when complete
        }

        do {
            // Check if user is authenticated via Clerk
            if authService.isAuthenticated {
                let token = try await authService.getSessionToken()
                apiClient.setAuthToken(token)

                AppLogger.authentication.info("🎫 JWT Token set in APIClient")

                // Fetch user data from backend
                await fetchUserData()

                isAuthenticated = true
                AppLogger.authentication.info("✅ User authenticated via Clerk - Ready for API calls")
                return
            }

            // Fallback: Check keychain for existing token (demo mode or previous session)
            let token = try keychainManager.load(forKey: Constants.KeychainKeys.authToken)
            apiClient.setAuthToken(token)

            AppLogger.authentication.info("🎫 JWT Token set from keychain")

            // Try to fetch user data to validate token
            await fetchUserData()

            isAuthenticated = true
            AppLogger.authentication.info("✅ User authenticated via stored token - Ready for API calls")
        } catch KeychainError.itemNotFound {
            isAuthenticated = false
            user = nil
            AppLogger.authentication.debug("No auth token found")
        } catch {
            self.error = error
            isAuthenticated = false
            user = nil
            AppLogger.authentication.error("Auth check failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Fetch User Data
    private func fetchUserData() async {
        do {
            // Fetch user profile from backend
            let response: User = try await apiClient.request(.getUserProfile)
            self.user = response
            AppLogger.authentication.debug("User data fetched successfully")
        } catch {
            // If API call fails, create basic user from Clerk data
            if authService.isAuthenticated {
                let name = authService.getUserName()
                let userId = try? keychainManager.load(forKey: Constants.KeychainKeys.userId)
                self.user = User(
                    id: userId ?? "unknown",
                    email: authService.getUserEmail(),
                    firstName: name.firstName,
                    lastName: name.lastName
                )
                AppLogger.authentication.debug("Created user from Clerk data")
            } else if let userId = try? keychainManager.load(forKey: Constants.KeychainKeys.userId) {
                // Demo mode user
                self.user = User(id: userId)
                AppLogger.authentication.debug("Created demo user")
            }
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

        // Fetch user data from backend
        await fetchUserData()

        isAuthenticated = true
        AppLogger.authentication.info("User signed in successfully")
    }

    // MARK: - Sign Out
    func signOut() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Sign out from Clerk if authenticated
            if authService.isAuthenticated {
                try await authService.signOut()
            }

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
        guard authService.isAuthenticated else {
            throw AuthError.notAuthenticated
        }

        do {
            let newToken = try await authService.refreshToken()
            apiClient.setAuthToken(newToken)
            AppLogger.authentication.info("Token refreshed successfully")
        } catch {
            AppLogger.authentication.error("Token refresh failed: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Token Expiration Check
    /// Check if token needs refresh (call periodically)
    func checkTokenExpiration() async {
        guard isAuthenticated else { return }

        do {
            // Attempt to get a fresh token
            // Clerk SDK caches tokens and only refreshes if needed
            let _ = try await authService.getSessionToken()
        } catch {
            // Token might be expired, try to refresh
            do {
                try await refreshToken()
            } catch {
                // Refresh failed, sign out user
                AppLogger.authentication.warning("Token expired and refresh failed, signing out")
                await signOut()
            }
        }
    }
}

// MARK: - AuthError
enum AuthError: LocalizedError {
    case notAuthenticated
    case tokenExpired
    case invalidCredentials
    case userFetchFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User is not authenticated"
        case .tokenExpired:
            return "Authentication token has expired"
        case .invalidCredentials:
            return "Invalid credentials provided"
        case .userFetchFailed:
            return "Failed to fetch user data"
        }
    }
}
