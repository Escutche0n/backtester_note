import SwiftUI

struct TotalHeader: View {
    let overview: HoldingsOverview
    let onSettings: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("总市值 · CNY")
                    .font(BNTokens.Typography.label)
                    .kerning(0.88)
                    .foregroundStyle(BNTokens.Colors.foregroundTertiary)

                Text("¥\(HoldingsFormatters.money(overview.totalValue))")
                    .bnNumeric(34, weight: .semibold)
                    .foregroundStyle(BNTokens.Colors.foregroundPrimary)

                HStack(spacing: 8) {
                    Text("\(HoldingsFormatters.signed(overview.dayPnl)) · \(HoldingsFormatters.percent(overview.dayPct))")
                        .bnNumeric(13, weight: .semibold)
                        .foregroundStyle(HoldingsFormatters.pnlColor(overview.dayPnl))

                    Text("今日")
                        .font(BNTokens.Typography.text(size: 11))
                        .foregroundStyle(BNTokens.Colors.foregroundTertiary)

                    Circle()
                        .fill(BNTokens.Colors.foregroundQuaternary)
                        .frame(width: 3, height: 3)

                    Text("单位净值 \(String(format: "%.4f", overview.unitNAV))")
                        .bnNumeric(11)
                        .foregroundStyle(BNTokens.Colors.foregroundSecondary)
                }
            }

            Spacer()

            Button(action: onSettings) {
                Image(systemName: "gearshape")
                    .font(BNTokens.Typography.text(size: 15))
                    .foregroundStyle(BNTokens.Colors.foregroundSecondary)
                    .frame(width: 34, height: 34)
                    .background(BNTokens.Colors.foregroundPrimary.opacity(0.06))
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(BNTokens.Colors.border, lineWidth: 0.5)
                    }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}
