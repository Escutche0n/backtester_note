import SwiftUI

struct OverviewPanel: View {
    let overview: HoldingsOverview

    private var rows: [[OverviewMetric]] {
        [
            [
                .init(label: "当日盈亏", value: HoldingsFormatters.optionalSigned(overview.dayPnl), color: HoldingsFormatters.pnlColor(overview.dayPnl)),
                .init(label: "当日收益率", value: HoldingsFormatters.optionalPercent(overview.dayPct), color: HoldingsFormatters.pnlColor(overview.dayPct)),
                .init(label: "当日回撤", value: HoldingsFormatters.optionalAbsPercent(overview.dayDrawdown), color: BNTokens.Colors.foregroundSecondary)
            ],
            [
                .init(label: "持有收益", value: HoldingsFormatters.signed(overview.holdPnl, fractionDigits: 0), color: HoldingsFormatters.pnlColor(overview.holdPnl)),
                .init(label: "持有收益率", value: HoldingsFormatters.percent(overview.holdPct), color: HoldingsFormatters.pnlColor(overview.holdPct)),
                .init(label: "XIRR", value: HoldingsFormatters.optionalPercent(overview.xirr), color: HoldingsFormatters.pnlColor(overview.xirr))
            ],
            [
                .init(label: "超额 vs 沪深300", value: HoldingsFormatters.optionalPercent(overview.excess), color: HoldingsFormatters.pnlColor(overview.excess)),
                .init(label: "近半年最大回撤", value: HoldingsFormatters.optionalAbsPercent(overview.maxDrawdown6M), color: BNTokens.Colors.foregroundSecondary),
                .init(label: "夏普 / 卡尔马", value: ratioText(overview.sharpe, overview.calmar), color: BNTokens.Colors.foregroundPrimary)
            ]
        ]
    }

    var body: some View {
        BNGlassCard(radius: 18) {
            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)

                ForEach(Array(rows.enumerated()), id: \.offset) { _, metrics in
                    metricRow(metrics)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("总览")
                .font(BNTokens.Typography.text(size: 12))
                .foregroundStyle(BNTokens.Colors.foregroundSecondary)

            Spacer()

            Text("失衡")
                .font(BNTokens.Typography.text(size: 10.5))
                .foregroundStyle(BNTokens.Colors.foregroundTertiary)

            Text(unbalanceText)
                .bnNumeric(11, weight: .semibold)
                .foregroundStyle((overview.unbalance ?? 0) > 0.1 ? BNTokens.Colors.accent : BNTokens.Colors.foregroundSecondary)

            ProgressView(value: min(1, (overview.unbalance ?? 0) * 3))
                .tint((overview.unbalance ?? 0) > 0.1 ? BNTokens.Colors.accent : BNTokens.Colors.foregroundSecondary)
                .frame(width: 44)
                .scaleEffect(x: 1, y: 0.45, anchor: .center)
                .opacity(overview.unbalance == nil ? 0.35 : 1)
        }
    }

    private var unbalanceText: String {
        guard let unbalance = overview.unbalance else {
            return "待算"
        }
        return "\(String(format: "%.1f", unbalance * 100))%"
    }

    private func ratioText(_ sharpe: Double?, _ calmar: Double?) -> String {
        guard let sharpe, let calmar else {
            return "待算"
        }
        return "\(String(format: "%.2f", sharpe)) · \(String(format: "%.2f", calmar))"
    }

    private func metricRow(_ metrics: [OverviewMetric]) -> some View {
        HStack(spacing: 0) {
            ForEach(metrics) { metric in
                VStack(alignment: .leading, spacing: 4) {
                    Text(metric.label)
                        .font(BNTokens.Typography.text(size: 10))
                        .foregroundStyle(BNTokens.Colors.foregroundTertiary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(metric.value)
                        .bnNumeric(14, weight: .semibold)
                        .foregroundStyle(metric.color)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)

                if metric.id != metrics.last?.id {
                    Rectangle()
                        .fill(BNTokens.Colors.border)
                        .frame(width: 0.5)
                }
            }
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(BNTokens.Colors.border)
                .frame(height: 0.5)
        }
    }
}

private struct OverviewMetric: Identifiable {
    let id = UUID()
    let label: String
    let value: String
    let color: Color
}
