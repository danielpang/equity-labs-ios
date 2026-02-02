import Foundation

// MARK: - Double Currency Extensions
extension Double {
    func toCurrency(currency: Currency = .usd, showSymbol: Bool = true, decimals: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals
        formatter.groupingSeparator = ","

        guard let formattedNumber = formatter.string(from: NSNumber(value: self)) else {
            return "\(currency.symbol)0.00"
        }

        if showSymbol {
            return "\(currency.symbol)\(formattedNumber)"
        } else {
            return formattedNumber
        }
    }

    func toPercentage(decimals: Int = 2, showSign: Bool = true) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals

        guard let formattedNumber = formatter.string(from: NSNumber(value: abs(self))) else {
            return "0.00%"
        }

        let sign = showSign && self > 0 ? "+" : ""
        let negativeSign = self < 0 ? "-" : ""

        return "\(negativeSign)\(sign)\(formattedNumber)%"
    }

    func toShortCurrency(currency: Currency = .usd) -> String {
        let absValue = abs(self)
        let sign = self < 0 ? "-" : ""

        if absValue >= 1_000_000_000 {
            return "\(sign)\(currency.symbol)\(String(format: "%.1fB", absValue / 1_000_000_000))"
        } else if absValue >= 1_000_000 {
            return "\(sign)\(currency.symbol)\(String(format: "%.1fM", absValue / 1_000_000))"
        } else if absValue >= 1_000 {
            return "\(sign)\(currency.symbol)\(String(format: "%.1fK", absValue / 1_000))"
        } else {
            return toCurrency(currency: currency)
        }
    }

    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

// MARK: - Currency Conversion
extension Double {
    func convert(from: Currency, to: Currency, rate: Double) -> Double {
        if from == to {
            return self
        }

        if from == .usd && to == .cad {
            return self * rate
        } else if from == .cad && to == .usd {
            return self / rate
        }

        return self
    }
}

// MARK: - Optional Double Extensions
extension Optional where Wrapped == Double {
    func toCurrency(currency: Currency = .usd, showSymbol: Bool = true, decimals: Int = 2) -> String {
        guard let value = self else {
            return "--"
        }
        return value.toCurrency(currency: currency, showSymbol: showSymbol, decimals: decimals)
    }

    func toPercentage(decimals: Int = 2, showSign: Bool = true) -> String {
        guard let value = self else {
            return "--"
        }
        return value.toPercentage(decimals: decimals, showSign: showSign)
    }
}
