import SwiftUI

enum HoldingsFormatters {
    static func money(_ value: Double, fractionDigits: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func money0(_ value: Double) -> String {
        money(value, fractionDigits: 0)
    }

    static func signed(_ value: Double, fractionDigits: Int = 2) -> String {
        "\(value >= 0 ? "+" : "")\(String(format: "%.\(fractionDigits)f", value))"
    }

    static func percent(_ value: Double, fractionDigits: Int = 2) -> String {
        "\(signed(value, fractionDigits: fractionDigits))%"
    }

    static func optionalSigned(_ value: Double?, fractionDigits: Int = 2, placeholder: String = "待算") -> String {
        guard let value else { return placeholder }
        return signed(value, fractionDigits: fractionDigits)
    }

    static func optionalPercent(_ value: Double?, fractionDigits: Int = 2, placeholder: String = "待算") -> String {
        guard let value else { return placeholder }
        return percent(value, fractionDigits: fractionDigits)
    }

    static func optionalAbsPercent(_ value: Double?, fractionDigits: Int = 2, placeholder: String = "待算") -> String {
        guard let value else { return placeholder }
        return absPercent(value, fractionDigits: fractionDigits)
    }

    static func absPercent(_ value: Double, fractionDigits: Int = 2) -> String {
        "\(String(format: "%.\(fractionDigits)f", value))%"
    }

    static func pnlColor(_ value: Double?) -> Color {
        guard let value else {
            return BNTokens.Colors.foregroundTertiary
        }
        return pnlColor(value)
    }

    static func pnlColor(_ value: Double) -> Color {
        if value > 0 {
            return BNTokens.Colors.up
        }
        if value < 0 {
            return BNTokens.Colors.down
        }
        return BNTokens.Colors.foregroundSecondary
    }
}

extension View {
    func bnNumeric(_ size: CGFloat = 15, weight: Font.Weight = .regular) -> some View {
        font(BNTokens.Typography.number(size: size, weight: weight))
    }
}
