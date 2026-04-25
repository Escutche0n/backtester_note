import SwiftUI

struct BacktestResultPreview: View {
    var body: some View {
        let account = BacktestMockData.previewSeries
        let benchmark = BacktestMockData.benchmarkSeries
        let last = account.last?.value ?? 0
        let benchmarkLast = benchmark.last?.value ?? 0
        let color = HoldingsFormatters.pnlColor(last)

        BNGlassCard(radius: 18) {
            VStack(spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("上次回测")
                            .font(.system(size: 11, weight: .semibold))
                            .kerning(0.66)
                            .foregroundStyle(BNTokens.Colors.foregroundTertiary)
                        Text("核心-卫星 · 月定投")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(BNTokens.Colors.foregroundPrimary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(HoldingsFormatters.percent(last))
                            .bnNumeric(16, weight: .semibold)
                            .foregroundStyle(color)
                        Text("2020 · 01 → 2025 · 12")
                            .bnNumeric(10.5)
                            .foregroundStyle(BNTokens.Colors.foregroundTertiary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)

                MockLineChart(
                    series: account,
                    benchmark: benchmark,
                    color: color
                )
                .frame(height: 120)
                .padding(.horizontal, 8)

                metrics(excess: last - benchmarkLast)
            }
            .padding(.bottom, 10)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
    }

    private func metrics(excess: Double) -> some View {
        HStack(spacing: 0) {
            ResultMetric(label: "CAGR", value: "+11.8%", color: BNTokens.Colors.up)
            ResultMetric(label: "XIRR", value: "+12.1%", color: BNTokens.Colors.up)
            ResultMetric(label: "最大回撤", value: "-18.2%", color: BNTokens.Colors.foregroundSecondary)
            ResultMetric(label: "夏普", value: "1.23", color: BNTokens.Colors.foregroundPrimary)
            ResultMetric(label: "超额", value: HoldingsFormatters.percent(excess), color: HoldingsFormatters.pnlColor(excess))
        }
        .padding(.horizontal, 6)
        .padding(.top, 8)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(BNTokens.Colors.border)
                .frame(height: 0.5)
        }
    }
}

private struct ResultMetric: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(BNTokens.Colors.foregroundTertiary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(value)
                .bnNumeric(13, weight: .semibold)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }
}
