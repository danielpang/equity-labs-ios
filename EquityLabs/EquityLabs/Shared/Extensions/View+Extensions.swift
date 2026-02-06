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
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
        }
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

    // MARK: - Navigation Bar Colors
    func navigationBarColors(backgroundColor: UIColor, titleColor: UIColor) -> some View {
        self.modifier(NavigationBarColorModifier(backgroundColor: backgroundColor, titleColor: titleColor))
    }
}

// MARK: - Navigation Bar Color Modifier
struct NavigationBarColorModifier: ViewModifier {
    let backgroundColor: UIColor
    let titleColor: UIColor

    init(backgroundColor: UIColor, titleColor: UIColor) {
        self.backgroundColor = backgroundColor
        self.titleColor = titleColor

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = backgroundColor
        appearance.titleTextAttributes = [.foregroundColor: titleColor]
        appearance.largeTitleTextAttributes = [.foregroundColor: titleColor]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
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
