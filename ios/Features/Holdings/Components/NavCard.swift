import SwiftUI

struct NavCard: View {
    private let ranges = ["1M", "3M", "6M", "1Y", "自定义"]
    @State private var selectedRange = "3M"

    var body: some View {
        let effectiveRange = selectedRange == "自定义" ? "1Y" : selectedRange
        let series = HoldingsMockData.navSeries[effectiveRange] ?? HoldingsMockData.navSeries["3M"]!
        let lastAccount = series.account.last?.value ?? 0
        let lastBenchmark = series.benchmark.last?.value ?? 0
        let chartColor = HoldingsFormatters.pnlColor(lastAccount)

        BNGlassCard(radius: 18) {
            VStack(spacing: 10) {
                header(lastAccount: lastAccount, lastBenchmark: lastBenchmark)

                MockLineChart(
                    series: series.account,
                    benchmark: series.benchmark,
                    color: chartColor
                )
                .frame(height: 140)

                footer(chartColor: chartColor)
            }
            .padding(.top, 14)
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
    }

    private func header(lastAccount: Double, lastBenchmark: Double) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("净值曲线")
                    .font(BNTokens.Typography.text(size: 12))
                    .foregroundStyle(BNTokens.Colors.foregroundSecondary)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(HoldingsFormatters.percent(lastAccount))
                        .bnNumeric(22, weight: .semibold)
                        .foregroundStyle(HoldingsFormatters.pnlColor(lastAccount))

                    Text("账户 · 从起始日")
                        .bnNumeric(11)
                        .foregroundStyle(BNTokens.Colors.foregroundSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(HoldingsFormatters.percent(lastBenchmark)) 沪深300")
                    .bnNumeric(12, weight: .medium)
                    .foregroundStyle(BNTokens.Colors.benchmark)

                Text("超额 \(HoldingsFormatters.percent(lastAccount - lastBenchmark))")
                    .bnNumeric(11, weight: .semibold)
                    .foregroundStyle(HoldingsFormatters.pnlColor(lastAccount - lastBenchmark))
            }
        }
    }

    private func footer(chartColor: Color) -> some View {
        HStack {
            Picker("范围", selection: $selectedRange) {
                ForEach(ranges, id: \.self) { range in
                    Text(range).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 232)

            Spacer()

            HStack(spacing: 8) {
                LegendItem(color: chartColor, title: "账户")
                LegendItem(color: BNTokens.Colors.benchmark, title: "基准", dashed: true)
            }
        }
    }
}

private struct LegendItem: View {
    let color: Color
    let title: String
    var dashed = false

    var body: some View {
        HStack(spacing: 4) {
            Rectangle()
                .fill(dashed ? Color.clear : color)
                .overlay {
                    if dashed {
                        Rectangle()
                            .stroke(color, style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
                    }
                }
                .frame(width: 8, height: 2)

            Text(title)
                .font(BNTokens.Typography.text(size: 10))
                .foregroundStyle(BNTokens.Colors.foregroundTertiary)
        }
    }
}
