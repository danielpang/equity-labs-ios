import SwiftUI

// MARK: - SignInView
struct SignInView: View {
    @EnvironmentObject var authManager: AuthManager

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
                    Button {
                        Task {
                            // TODO: Integrate Clerk authentication in Phase 2
                            // For now, simulate sign in
                            try? await authManager.signIn(
                                token: "demo_token",
                                userId: "demo_user"
                            )
                        }
                    } label: {
                        Text("Sign In with Clerk")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 32)

                    Text("Secure authentication powered by Clerk")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 48)
            }
        }
        .loading(authManager.isLoading)
    }
}

// MARK: - Preview
#Preview {
    SignInView()
        .environmentObject(AuthManager.shared)
}
