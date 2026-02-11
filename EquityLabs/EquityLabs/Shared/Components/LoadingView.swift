import SwiftUI

// MARK: - LoadingView
struct LoadingView: View {
    var message: String? = nil

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            if let message = message {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(24)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Constants.Layout.glassCornerRadius))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Preview
#Preview {
    LoadingView(message: "Loading portfolio...")
}
