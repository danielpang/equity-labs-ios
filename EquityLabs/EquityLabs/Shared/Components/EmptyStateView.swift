import SwiftUI

// MARK: - EmptyStateView
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(icon: String = "tray",
         title: String,
         message: String,
         actionTitle: String? = nil,
         action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.textTertiary)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundColor(.textPrimary)

                Text(message)
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if let actionTitle = actionTitle, let action = action {
                Button {
                    action()
                } label: {
                    Text(actionTitle)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .glassEffect(.regular.interactive(), in: Capsule())
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(title). \(message)")
    }
}

// MARK: - Preview
#Preview {
    EmptyStateView(
        icon: "chart.line.uptrend.xyaxis",
        title: "No Stocks Yet",
        message: "Start tracking your investments by adding your first stock",
        actionTitle: "Add Stock"
    ) {
        print("Add stock tapped")
    }
}
