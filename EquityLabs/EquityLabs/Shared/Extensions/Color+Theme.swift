import SwiftUI
import UIKit

// MARK: - Color Theme
extension Color {
    // MARK: - Brand Colors
    static let brandPrimary = Color("BrandPrimary", bundle: nil)
    static let brandSecondary = Color("BrandSecondary", bundle: nil)

    // MARK: - Background Colors
    static let backgroundPrimary = Color(uiColor: .systemBackground)
    static let backgroundSecondary = Color(uiColor: .secondarySystemBackground)
    static let backgroundTertiary = Color(uiColor: .tertiarySystemBackground)

    // MARK: - Text Colors
    static let textPrimary = Color(uiColor: .label)
    static let textSecondary = Color(uiColor: .secondaryLabel)
    static let textTertiary = Color(uiColor: .tertiaryLabel)

    // MARK: - Stock Colors
    static let stockGreen = Color(red: 0.0, green: 0.7, blue: 0.3)
    static let stockRed = Color(red: 0.9, green: 0.2, blue: 0.2)

    // MARK: - Sentiment Colors
    static let sentimentPositive = Color.green
    static let sentimentNeutral = Color.gray
    static let sentimentNegative = Color.red

    // MARK: - Chart Colors
    static let chartLine = Color.blue
    static let chartFill = Color.blue.opacity(0.2)
    static let chartGrid = Color.gray.opacity(0.2)
    static let chartLotIndicator = Color.orange

    // MARK: - Helpers
    func toUIColor() -> UIColor {
        UIColor(self)
    }

    static func profitLoss(value: Double) -> Color {
        value >= 0 ? .stockGreen : .stockRed
    }

    static func sentiment(_ label: SentimentLabel) -> Color {
        switch label {
        case .positive: return .sentimentPositive
        case .neutral: return .sentimentNeutral
        case .negative: return .sentimentNegative
        }
    }
}
