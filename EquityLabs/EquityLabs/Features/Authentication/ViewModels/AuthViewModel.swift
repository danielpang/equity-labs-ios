import Foundation
import SwiftUI
import Combine

// MARK: - AuthViewModel
@MainActor
class AuthViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    // MARK: - Validation

    var isEmailValid: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    var isPasswordValid: Bool {
        return password.count >= 8
    }

    var canSubmit: Bool {
        return isEmailValid && isPasswordValid && !isLoading
    }

    // MARK: - Error Handling

    func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
        isLoading = false
        AppLogger.authentication.error("Auth error: \(error.localizedDescription)")
    }

    func clearError() {
        errorMessage = nil
        showError = false
    }

    // MARK: - Form Reset

    func reset() {
        email = ""
        password = ""
        errorMessage = nil
        showError = false
        isLoading = false
    }

    // MARK: - Demo Mode

    func fillDemoCredentials() {
        email = "demo@equitylabs.com"
        password = "demo1234"
    }
}
