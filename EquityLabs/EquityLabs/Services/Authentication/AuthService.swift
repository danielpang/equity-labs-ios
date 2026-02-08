import Foundation
import Combine
import Clerk

// MARK: - AuthService
/// Service layer for Clerk authentication integration
@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()

    private let clerk = Clerk.shared
    private let keychainManager = KeychainManager.shared

    @Published var isInitialized = false
    @Published var isAuthenticated = false
    @Published var error: AuthServiceError?

    private init() {}

    // MARK: - Initialization

    /// Configure Clerk with publishable key
    func configure() async throws {
        guard let publishableKey = Constants.Clerk.publishableKey else {
            throw AuthServiceError.missingPublishableKey
        }

        clerk.configure(publishableKey: publishableKey)

        do {
            try await clerk.load()
            isInitialized = true
            isAuthenticated = (clerk.user != nil)

            // Save session token to keychain if user is authenticated
            if clerk.user != nil, let userId = getClerkUserId() {
                try await saveSessionToken(userId: userId)
            }

            AppLogger.authentication.info("Clerk initialized successfully")
        } catch {
            AppLogger.authentication.error("Clerk initialization failed: \(error.localizedDescription)")
            throw AuthServiceError.initializationFailed(error)
        }
    }

    // MARK: - User Info Helpers

    func getClerkUserId() -> String? {
        guard let user = clerk.user else { return nil }
        return Mirror(reflecting: user).children.first(where: { $0.label == "id" })?.value as? String
    }

    func getUserEmail() -> String? {
        guard let user = clerk.user else { return nil }
        if let emailAddresses = Mirror(reflecting: user).children.first(where: { $0.label == "emailAddresses" })?.value as? [Any],
           let firstEmail = emailAddresses.first {
            return Mirror(reflecting: firstEmail).children.first(where: { $0.label == "emailAddress" })?.value as? String
        }
        return nil
    }

    func getUserName() -> (firstName: String?, lastName: String?) {
        guard let user = clerk.user else { return (nil, nil) }
        let mirror = Mirror(reflecting: user)
        let firstName = mirror.children.first(where: { $0.label == "firstName" })?.value as? String
        let lastName = mirror.children.first(where: { $0.label == "lastName" })?.value as? String
        return (firstName, lastName)
    }

    // MARK: - Token Management

    /// Get current session token (JWT)
    func getSessionToken() async throws -> String {
        guard let session = clerk.session else {
            throw AuthServiceError.noActiveSession
        }

        guard let token = try await session.getToken() else {
            throw AuthServiceError.tokenRetrievalFailed
        }

        return token.jwt
    }

    /// Save session token to keychain for API client usage
    private func saveSessionToken(userId: String) async throws {
        do {
            let token = try await getSessionToken()
            try keychainManager.save(token, forKey: Constants.KeychainKeys.authToken)
            try keychainManager.save(userId, forKey: Constants.KeychainKeys.userId)
            AppLogger.authentication.debug("Session token saved to keychain")
        } catch {
            AppLogger.authentication.error("Failed to save session token: \(error.localizedDescription)")
            throw error
        }
    }

    /// Refresh session token
    func refreshToken() async throws -> String {
        guard let session = clerk.session else {
            throw AuthServiceError.noActiveSession
        }

        // Force fresh token by skipping cache
        let options = Session.GetTokenOptions(skipCache: true)

        guard let token = try await session.getToken(options) else {
            throw AuthServiceError.tokenRetrievalFailed
        }

        // Update keychain with new token
        try keychainManager.save(token.jwt, forKey: Constants.KeychainKeys.authToken)

        AppLogger.authentication.debug("Session token refreshed")
        return token.jwt
    }

    // MARK: - User Management

    /// Check if user is currently signed in
    func checkAuthentication() {
        isAuthenticated = (clerk.user != nil)
    }

    // MARK: - Sign Out

    /// Sign out current user
    func signOut() async throws {
        do {
            try await clerk.signOut()

            // Clear keychain
            try keychainManager.deleteAll()

            isAuthenticated = false

            AppLogger.authentication.info("User signed out successfully")
        } catch {
            AppLogger.authentication.error("Sign out failed: \(error.localizedDescription)")
            throw AuthServiceError.signOutFailed(error)
        }
    }

    // MARK: - Post-Login Setup

    /// Call after Clerk authentication completes to save session and update state.
    func handlePostLogin() async throws {
        guard clerk.user != nil else { return }

        isAuthenticated = true

        if let userId = getClerkUserId() {
            try await saveSessionToken(userId: userId)
        }
    }
}

// MARK: - AuthServiceError

enum AuthServiceError: LocalizedError {
    case missingPublishableKey
    case initializationFailed(Error)
    case noActiveSession
    case tokenRetrievalFailed
    case signOutFailed(Error)

    var errorDescription: String? {
        switch self {
        case .missingPublishableKey:
            return "Clerk publishable key not configured"
        case .initializationFailed(let error):
            return "Failed to initialize Clerk: \(error.localizedDescription)"
        case .noActiveSession:
            return "No active session found"
        case .tokenRetrievalFailed:
            return "Failed to retrieve session token"
        case .signOutFailed(let error):
            return "Sign out failed: \(error.localizedDescription)"
        }
    }
}
