import SwiftUI

struct HoldingCard: View {
    let fund: HoldingFund
    let totalValue: Double

    private var actualWeight: Double {
        fund.value / totalValue
    }

    private var weightDelta: Double {
        actualWeight - fund.targetWeight
    }

    var body: some View {
        VStack(spacing: 12) {
            topRow
            middleRow
            weightBar
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: BNTokens.Radius.md, style: .continuous)
                .fill(BNTokens.Colors.surface)
        }
        .clipShape(RoundedRectangle(cornerRadius: BNTokens.Radius.md, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: BNTokens.Radius.md, style: .continuous)
                .stroke(BNTokens.Colors.border, lineWidth: 0.5)
        }
    }

    private var topRow: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(fund.type)
                .font(BNTokens.Typography.text(size: 10))
                .foregroundStyle(BNTokens.Colors.foregroundSecondary)
                .frame(width: 32, height: 32)
                .background(BNTokens.Colors.foregroundPrimary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(BNTokens.Colors.border, lineWidth: 0.5)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(fund.name)
                    .font(BNTokens.Typography.text(size: 14))
                    .foregroundStyle(BNTokens.Colors.foregroundPrimary)
                    .lineLimit(1)

                Text("\(fund.code) · \(HoldingsFormatters.money0(fund.shares)) 份")
                    .bnNumeric(10.5)
                    .foregroundStyle(BNTokens.Colors.foregroundTertiary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text("¥\(HoldingsFormatters.money(fund.value))")
                    .bnNumeric(14, weight: .semibold)
                    .foregroundStyle(BNTokens.Colors.foregroundPrimary)

                Text("\(HoldingsFormatters.percent(fund.dayPct)) 今日")
                    .bnNumeric(10.5, weight: .semibold)
                    .foregroundStyle(HoldingsFormatters.pnlColor(fund.dayPct))
            }
        }
    }

    private var middleRow: some View {
        HStack(alignment: .center) {
            HStack(spacing: 14) {
                miniMetric("持有收益", HoldingsFormatters.percent(fund.holdPct), color: HoldingsFormatters.pnlColor(fund.holdPct))
                miniMetric("成本 / 份", "¥\(String(format: "%.4f", fund.cost / fund.shares))", color: BNTokens.Colors.foregroundSecondary)
            }

            Spacer()

            MockLineChart(
                series: fund.sparkline,
                benchmark: [],
                color: HoldingsFormatters.pnlColor(fund.holdPct),
                showFill: false
            )
            .frame(width: 72, height: 22)
        }
    }

    private var weightBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("仓位")
                    .font(BNTokens.Typography.text(size: 10))
                    .foregroundStyle(BNTokens.Colors.foregroundTertiary)

                Spacer()

                Text("实际 \(String(format: "%.1f", actualWeight * 100))% / 目标 \(String(format: "%.0f", fund.targetWeight * 100))%")
                    .bnNumeric(10)
                    .foregroundStyle(BNTokens.Colors.foregroundSecondary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.05))

                    Capsule()
                        .fill(abs(weightDelta) > 0.03 ? BNTokens.Colors.accent : BNTokens.Colors.foregroundSecondary)
                        .frame(width: max(2, proxy.size.width * min(actualWeight, 1)))

                    Rectangle()
                        .fill(BNTokens.Colors.foregroundPrimary)
                        .frame(width: 1, height: 8)
                        .offset(x: proxy.size.width * min(fund.targetWeight, 1))
                }
            }
            .frame(height: 4)

            if abs(weightDelta) > 0.02 {
                Text("\(weightDelta > 0 ? "超配" : "低配") \(String(format: "%.1f", abs(weightDelta) * 100))pp")
                    .bnNumeric(9.5, weight: .medium)
                    .foregroundStyle(weightDelta > 0 ? BNTokens.Colors.accent : BNTokens.Colors.benchmark)
            }
        }
    }

    private func miniMetric(_ label: String, _ value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(BNTokens.Typography.text(size: 9.5))
                .foregroundStyle(BNTokens.Colors.foregroundTertiary)

            Text(value)
                .bnNumeric(12, weight: .semibold)
                .foregroundStyle(color)
        }
    }
}
