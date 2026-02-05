import SwiftUI
import Clerk

// MARK: - SignInView
struct SignInView: View {
    @Environment(\.clerk) private var clerk
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var authManager: AuthManager
    @State private var showAuthSheet = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Logo and title
                VStack(spacing: 16) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 80))
                        .foregroundColor(.white)

                    Text("EquityLabs")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)

                    Text("Track your portfolio with confidence")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.9))
                }

                Spacer()

                // Sign in button
                VStack(spacing: 16) {
                    // Status indicator
                    if !authService.isInitialized {
                        HStack {
                            ProgressView()
                                .tint(.white)
                            Text("Initializing Clerk...")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding()
                    }

                    if let error = authService.error {
                        Text("⚠️ \(error.localizedDescription)")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(8)
                            .padding(.horizontal, 32)
                    }

                    Button {
                        if !authService.isInitialized {
                            errorMessage = "Clerk is not initialized. Please check your CLERK_PUBLISHABLE_KEY configuration."
                            showError = true
                            return
                        }
                        showAuthSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "person.badge.key.fill")
                            Text("Sign In with Clerk")
                                .font(.headline)
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 32)
                    .disabled(!authService.isInitialized)

                    Button {
                        // Demo mode for testing
                        Task {
                            try? await authManager.signIn(
                                token: "demo_token",
                                userId: "demo_user"
                            )
                        }
                    } label: {
                        Text("Continue as Demo")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }

                    Text("Secure authentication powered by Clerk")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 48)
            }
        }
        .loading(authManager.isLoading)
        .sheet(isPresented: $showAuthSheet) {
            NavigationView {
                AuthView()
                    .navigationTitle("Sign In")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showAuthSheet = false
                            }
                        }
                    }
            }
            .onDisappear {
                // After Clerk authentication completes
                Task {
                    if clerk.user != nil {
                        do {
                            let token = try await authService.getSessionToken()
                            guard let userId = try? keychainManager.load(forKey: Constants.KeychainKeys.userId) else {
                                throw AuthError.userFetchFailed
                            }
                            try await authManager.signIn(token: token, userId: userId)
                            AppLogger.authentication.info("User authenticated via Clerk")
                        } catch {
                            errorMessage = "Sign in failed: \(error.localizedDescription)"
                            showError = true
                            AppLogger.authentication.error("Clerk auth completion failed: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
        .alert("Authentication Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private let keychainManager = KeychainManager.shared
}

// MARK: - Preview
#Preview {
    SignInView()
        .environmentObject(AuthManager.shared)
}
