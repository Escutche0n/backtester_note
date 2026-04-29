import SwiftUI

struct NavCard: View {
    @EnvironmentObject private var portfolioService: PortfolioService
    @EnvironmentObject private var fundNAVService: FundNAVService

    private let ranges = ["1M", "3M", "6M", "1Y", "自定义"]
    @State private var selectedRange = "3M"

    var body: some View {
        let effectiveRange = selectedRange == "自定义" ? "1Y" : selectedRange
        let realSeries = portfolioService.currentAccount.map {
            NAVService.accountSeries(for: $0, fundNAVRecords: fundNAVService.records)
        }
        let display = makeDisplaySeries(effectiveRange: effectiveRange, realSeries: realSeries)
        let lastAccount = display.account.last?.value
        let lastBenchmark = display.benchmark.last?.value
        let chartColor = HoldingsFormatters.pnlColor(lastAccount ?? 0)

        BNGlassCard(radius: 18) {
            VStack(spacing: 10) {
                header(lastAccount: lastAccount, lastBenchmark: lastBenchmark, isReal: display.isReal)

                if display.account.isEmpty {
                    emptyState(message: display.emptyMessage)
                        .frame(height: 140)
                } else {
                    MockLineChart(
                        series: display.account,
                        benchmark: display.benchmark,
                        color: chartColor,
                        showFill: display.gapCount == 0
                    )
                    .frame(height: 140)
                }

                footer(chartColor: chartColor, display: display)
            }
            .padding(.top, 14)
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
    }

    private func header(lastAccount: Double?, lastBenchmark: Double?, isReal: Bool) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text("净值曲线")
                    .font(BNTokens.Typography.text(size: 12))
                    .foregroundStyle(BNTokens.Colors.foregroundSecondary)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(lastAccount.map { HoldingsFormatters.percent($0) } ?? "待录入")
                        .bnNumeric(22, weight: .semibold)
                        .foregroundStyle(lastAccount.map(HoldingsFormatters.pnlColor) ?? BNTokens.Colors.foregroundPrimary)

                    Text(isReal ? "账户 · 本地日净值" : "账户 · mock")
                        .bnNumeric(11)
                        .foregroundStyle(BNTokens.Colors.foregroundSecondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(lastBenchmark.map { "\(HoldingsFormatters.percent($0)) 沪深300" } ?? "基准待接入")
                    .bnNumeric(12, weight: .medium)
                    .foregroundStyle(BNTokens.Colors.benchmark)

                Text(excessText(lastAccount: lastAccount, lastBenchmark: lastBenchmark))
                    .bnNumeric(11, weight: .semibold)
                    .foregroundStyle(excessColor(lastAccount: lastAccount, lastBenchmark: lastBenchmark))
            }
        }
    }

    private func footer(chartColor: Color, display: NAVDisplaySeries) -> some View {
        HStack {
            Picker("范围", selection: $selectedRange) {
                ForEach(ranges, id: \.self) { range in
                    Text(range).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 232)
            .sensoryFeedback(.selection, trigger: selectedRange)

            Spacer()

            HStack(spacing: 8) {
                LegendItem(color: chartColor, title: "账户")
                if !display.benchmark.isEmpty {
                    LegendItem(color: BNTokens.Colors.benchmark, title: "基准", dashed: true)
                }
                if let statusText = display.statusText {
                    Text(statusText)
                        .font(BNTokens.Typography.text(size: 10))
                        .foregroundStyle(BNTokens.Colors.accent)
                }
            }
        }
    }

    private func emptyState(message: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: "chart.xyaxis.line")
                .font(BNTokens.Typography.text(size: 20))
                .foregroundStyle(BNTokens.Colors.foregroundTertiary)
            Text(message)
                .font(BNTokens.Typography.text(size: 13))
                .foregroundStyle(BNTokens.Colors.foregroundSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(BNTokens.Colors.surface.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func makeDisplaySeries(effectiveRange: String, realSeries: AccountNAVSeries?) -> NAVDisplaySeries {
        guard let realSeries else {
            let mock = HoldingsMockData.navSeries[effectiveRange] ?? HoldingsMockData.navSeries["3M"]!
            return NAVDisplaySeries(
                account: mock.account,
                benchmark: mock.benchmark,
                isReal: false,
                gapCount: 0,
                statusText: nil,
                emptyMessage: "暂无账户数据"
            )
        }

        let filtered = filter(realSeries.points, range: effectiveRange)
        let points = chartPoints(from: filtered, missingDateKeys: realSeries.missingValuationDateKeys)
        let statusText = statusText(for: realSeries, visiblePoints: filtered)
        return NAVDisplaySeries(
            account: points,
            benchmark: [],
            isReal: true,
            gapCount: realSeries.missingValuationDateKeys.count,
            statusText: statusText,
            emptyMessage: realSeries.flowOnlyDateKeys.isEmpty ? "录入日净值后生成曲线" : "流水日缺净值，后续待对账"
        )
    }

    private func filter(_ points: [AccountNAVPoint], range: String) -> [AccountNAVPoint] {
        guard let lastDate = points.last?.date else { return [] }
        let days: Int
        switch range {
        case "1M": days = 30
        case "3M": days = 90
        case "6M": days = 180
        default: days = 365
        }
        let start = ImportDateFormatter.calendar.date(byAdding: .day, value: -days, to: lastDate) ?? lastDate
        return points.filter { $0.date >= start }
    }

    private func chartPoints(from points: [AccountNAVPoint], missingDateKeys: [String]) -> [ChartPoint] {
        guard let firstDate = points.first?.date else { return [] }
        let missingDates = Set(missingDateKeys.compactMap(ImportDateFormatter.parseDay))
        var index = 0
        var previousDate = firstDate
        return points.enumerated().map { offset, point in
            if offset > 0 {
                let hasMissingBetween = missingDates.contains { missing in
                    missing > previousDate && missing < point.date
                }
                index += hasMissingBetween ? 2 : 1
                previousDate = point.date
            }
            return ChartPoint(index: index, value: point.returnPercent)
        }
    }

    private func statusText(for series: AccountNAVSeries, visiblePoints: [AccountNAVPoint]) -> String? {
        var parts: [String] = []
        if visiblePoints.contains(where: { $0.credibility == .snapshotOnly }) {
            parts.append("含快照")
        }
        if !series.missingValuationDateKeys.isEmpty {
            parts.append("缺净值 \(series.missingValuationDateKeys.count) 天")
        }
        if !series.flowOnlyDateKeys.isEmpty {
            parts.append("仅流水 \(series.flowOnlyDateKeys.count) 天")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private func excessText(lastAccount: Double?, lastBenchmark: Double?) -> String {
        guard let lastAccount, let lastBenchmark else { return "超额 待算" }
        return "超额 \(HoldingsFormatters.percent(lastAccount - lastBenchmark))"
    }

    private func excessColor(lastAccount: Double?, lastBenchmark: Double?) -> Color {
        guard let lastAccount, let lastBenchmark else { return BNTokens.Colors.foregroundTertiary }
        return HoldingsFormatters.pnlColor(lastAccount - lastBenchmark)
    }
}

private struct NAVDisplaySeries {
    let account: [ChartPoint]
    let benchmark: [ChartPoint]
    let isReal: Bool
    let gapCount: Int
    let statusText: String?
    let emptyMessage: String
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
