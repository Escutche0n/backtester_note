import SwiftUI

struct BacktestHistoryList: View {
    let items: [BacktestHistoryItem]

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("历史回测 · \(items.count)")
                    .font(BNTokens.Typography.text(size: 12))
                    .foregroundStyle(BNTokens.Colors.foregroundSecondary)

                Spacer()

                Button("对比") {}
                    .font(BNTokens.Typography.text(size: 11))
                    .buttonStyle(.bordered)
                    .tint(BNTokens.Colors.foregroundSecondary)
            }

            ForEach(items) { item in
                historyCard(item)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 110)
    }

    private func historyCard(_ item: BacktestHistoryItem) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 6) {
                    Text(item.type)
                        .font(BNTokens.Typography.chip)
                        .foregroundStyle(BNTokens.Colors.foregroundSecondary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(BNTokens.Colors.foregroundPrimary.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                    Text(item.savedAt)
                        .font(BNTokens.Typography.text(size: 9.5))
                        .foregroundStyle(BNTokens.Colors.foregroundTertiary)
                }

                Text(item.name)
                    .font(BNTokens.Typography.text(size: 13))
                    .foregroundStyle(BNTokens.Colors.foregroundPrimary)
                    .lineLimit(1)

                Text(item.period)
                    .bnNumeric(10.5)
                    .foregroundStyle(BNTokens.Colors.foregroundTertiary)

                HStack(spacing: 12) {
                    metric("CAGR", HoldingsFormatters.percent(item.cagr, fractionDigits: 1), HoldingsFormatters.pnlColor(item.cagr))
                    metric("最大回撤", "\(String(format: "%.1f", item.maxDrawdown))%", BNTokens.Colors.foregroundSecondary)
                    metric("夏普", String(format: "%.2f", item.sharpe), BNTokens.Colors.foregroundPrimary)
                }
            }

            Spacer(minLength: 8)

            MockLineChart(
                series: item.series,
                benchmark: [],
                color: HoldingsFormatters.pnlColor(item.cagr)
            )
            .frame(width: 82, height: 48)
        }
        .padding(12)
        .background(BNTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(BNTokens.Colors.border, lineWidth: 0.5)
        }
    }

    private func metric(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(BNTokens.Typography.text(size: 9))
                .foregroundStyle(BNTokens.Colors.foregroundTertiary)
            Text(value)
                .bnNumeric(12, weight: .semibold)
                .foregroundStyle(color)
        }
    }
}
