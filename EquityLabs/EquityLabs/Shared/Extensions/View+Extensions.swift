import SwiftUI
import UIKit

// MARK: - View Extensions
extension View {
    // MARK: - Card Styling
    func cardStyle() -> some View {
        self
            .padding(Constants.Layout.cardPadding)
            .background(Color.backgroundSecondary)
            .cornerRadius(Constants.Layout.cornerRadius)
    }

    // MARK: - Conditional Modifiers
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    // MARK: - Loading Overlay
    func loading(_ isLoading: Bool) -> some View {
        self.overlay {
            if isLoading {
                LoadingView()
            }
        }
    }

    // MARK: - Error Alert
    func errorAlert(_ error: Binding<Error?>) -> some View {
        self.alert("Error", isPresented: .constant(error.wrappedValue != nil)) {
            Button("OK") {
                error.wrappedValue = nil
            }
        } message: {
            if let error = error.wrappedValue {
                Text(error.localizedDescription)
            }
        }
    }

    // MARK: - Haptic Feedback
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.onTapGesture {
            HapticManager.impact(style)
        }
    }

    // MARK: - Shimmer / Skeleton Loading
    func shimmer(isActive: Bool = true) -> some View {
        self.modifier(ShimmerModifier(isActive: isActive))
    }

    // MARK: - Hidden Modifier
    @ViewBuilder
    func hidden(_ shouldHide: Bool) -> some View {
        if shouldHide {
            self.hidden()
        } else {
            self
        }
    }

    // MARK: - Glass Styling
    func glassCardStyle() -> some View {
        self
            .padding(Constants.Layout.cardPadding)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: Constants.Layout.glassCornerRadius))
    }

    func glassTabStyle() -> some View {
        self
            .padding(Constants.Layout.cardPadding)
            .glassEffect(.regular.interactive(), in: Capsule())
    }

    // MARK: - Navigation Bar Colors (Deprecated)
    @available(*, deprecated, message: "No longer needed — iOS 26 glass nav bars are automatic")
    func navigationBarColors(backgroundColor: UIColor, titleColor: UIColor) -> some View {
        self.modifier(NavigationBarColorModifier(backgroundColor: backgroundColor, titleColor: titleColor))
    }
}

// MARK: - Navigation Bar Color Modifier (Deprecated)
@available(*, deprecated, message: "No longer needed — iOS 26 glass nav bars are automatic")
struct NavigationBarColorModifier: ViewModifier {
    let backgroundColor: UIColor
    let titleColor: UIColor

    init(backgroundColor: UIColor, titleColor: UIColor) {
        self.backgroundColor = backgroundColor
        self.titleColor = titleColor
    }

    func body(content: Content) -> some View {
        content
    }
}

// MARK: - Keyboard Dismiss
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    func dismissKeyboardOnTap() -> some View {
        self.onTapGesture {
            hideKeyboard()
        }
    }
}

// MARK: - Async Button
struct AsyncButton<Label: View>: View {
    var action: () async -> Void
    @ViewBuilder var label: () -> Label

    @State private var isLoading = false

    var body: some View {
        Button {
            Task {
                isLoading = true
                await action()
                isLoading = false
            }
        } label: {
            ZStack {
                label().opacity(isLoading ? 0 : 1)
                if isLoading {
                    ProgressView()
                }
            }
        }
        .disabled(isLoading)
    }
}

// MARK: - Haptic Manager
enum HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }

    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Shimmer Modifier
struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        if isActive {
            content
                .overlay(
                    GeometryReader { geometry in
                        LinearGradient(
                            colors: [
                                .clear,
                                Color.white.opacity(0.4),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 0.6)
                        .offset(x: -geometry.size.width * 0.3 + phase * (geometry.size.width * 1.6))
                    }
                    .clipped()
                )
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
        } else {
            content
        }
    }
}

// MARK: - Skeleton View
struct SkeletonView: View {
    var height: CGFloat = 16
    var cornerRadius: CGFloat = 8

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.gray.opacity(0.2))
            .frame(height: height)
            .shimmer()
    }
}

// MARK: - Stock Card Skeleton
struct StockCardSkeleton: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 50, height: 50)
                .shimmer()

            VStack(alignment: .leading, spacing: 8) {
                SkeletonView(height: 16)
                    .frame(width: 80)
                SkeletonView(height: 12)
                    .frame(width: 140)
                SkeletonView(height: 10)
                    .frame(width: 100)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                SkeletonView(height: 16)
                    .frame(width: 70)
                SkeletonView(height: 12)
                    .frame(width: 50)
                SkeletonView(height: 10)
                    .frame(width: 80)
            }
        }
        .padding()
        .background(Color.backgroundSecondary)
        .cornerRadius(Constants.Layout.cornerRadius)
        .accessibilityLabel("Loading stock data")
    }
}

// MARK: - News Skeleton
struct NewsArticleSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SkeletonView(height: 10)
                    .frame(width: 80)
                Spacer()
                SkeletonView(height: 10)
                    .frame(width: 60)
            }
            SkeletonView(height: 16)
            SkeletonView(height: 12)
                .frame(width: 250)
            SkeletonView(height: 24, cornerRadius: 12)
                .frame(width: 100)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .accessibilityLabel("Loading news article")
    }
}
