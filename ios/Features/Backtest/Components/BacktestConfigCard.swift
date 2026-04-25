import SwiftUI

struct BacktestConfigCard: View {
    let mode: BacktestMode
    @State private var selectedPortfolioID = "p1"
    @State private var frequency = "周定投"
    @State private var rebalanceEnabled = true

    private var selectedPortfolio: BacktestPortfolio {
        BacktestMockData.portfolios.first { $0.id == selectedPortfolioID }
            ?? BacktestMockData.portfolios[0]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if mode == .single {
                FieldRow(title: "标的基金", value: "沪深300ETF", detail: "510300 · 宽基")
            } else {
                portfolioPicker
                compositionPanel
            }

            Text("回测区间")
                .font(BNTokens.Typography.label)
                .kerning(0.88)
                .foregroundStyle(BNTokens.Colors.foregroundTertiary)
                .padding(.top, 6)

            HStack(spacing: 8) {
                FieldRow(title: "起始", value: "2020-01-01")
                FieldRow(title: "截止", value: "2025-12-31")
            }

            quickRanges

            if mode != .single {
                sipRulePanel
            }

            Button("开始回测") {}
                .font(BNTokens.Typography.text(size: 14))
                .foregroundStyle(BNTokens.Colors.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(BNTokens.Colors.foregroundPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.top, 6)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
    }

    private var portfolioPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("组合 · 来自收藏")
                .font(BNTokens.Typography.label)
                .kerning(0.88)
                .foregroundStyle(BNTokens.Colors.foregroundTertiary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(BacktestMockData.portfolios) { portfolio in
                        PortfolioPill(
                            portfolio: portfolio,
                            selected: portfolio.id == selectedPortfolioID
                        ) {
                            selectedPortfolioID = portfolio.id
                        }
                    }
                }
            }
        }
    }

    private var compositionPanel: some View {
        BNGlassCard(radius: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("组合构成")
                    .font(BNTokens.Typography.text(size: 10.5))
                    .foregroundStyle(BNTokens.Colors.foregroundTertiary)

                ForEach(Array(selectedPortfolio.fundCodes.enumerated()), id: \.offset) { index, code in
                    HStack {
                        Text(fundName(code))
                            .font(BNTokens.Typography.text(size: 12))
                            .foregroundStyle(BNTokens.Colors.foregroundPrimary)
                        Spacer()
                        Text("\(String(format: "%.0f", selectedPortfolio.weights[index] * 100))%")
                            .bnNumeric(12)
                            .foregroundStyle(BNTokens.Colors.foregroundSecondary)
                    }
                }
            }
            .padding(12)
        }
    }

    private var quickRanges: some View {
        HStack(spacing: 6) {
            ForEach(["1Y", "3Y", "5Y", "成立起"], id: \.self) { range in
                Text(range)
                    .font(BNTokens.Typography.text(size: 11))
                    .foregroundStyle(BNTokens.Colors.foregroundPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(BNTokens.Colors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(BNTokens.Colors.borderStrong, lineWidth: 0.5)
                    }
            }
        }
    }

    private var sipRulePanel: some View {
        BNGlassCard(radius: 12) {
            VStack(alignment: .leading, spacing: 10) {
                Text("定投规则")
                    .font(BNTokens.Typography.label)
                    .kerning(0.88)
                    .foregroundStyle(BNTokens.Colors.foregroundTertiary)

                Picker("频率", selection: $frequency) {
                    Text("周定投").tag("周定投")
                    Text("双周").tag("双周")
                    Text("月定投").tag("月定投")
                }
                .pickerStyle(.segmented)

                HStack {
                    miniInfo("扣款日", frequency == "月定投" ? "每月 15 日" : "周一")
                    Spacer()
                    miniInfo("首笔 / 每期", "¥5,000 / ¥1,000")
                }

                if mode == .portfolio {
                    Toggle("启用再平衡", isOn: $rebalanceEnabled)
                        .font(BNTokens.Typography.text(size: 12))
                        .tint(BNTokens.Colors.up)

                    if rebalanceEnabled {
                        HStack {
                            Text("偏离阈值")
                            Spacer()
                            Text("5%").bnNumeric(12, weight: .semibold)
                        }
                        .font(BNTokens.Typography.text(size: 11.5))
                        .foregroundStyle(BNTokens.Colors.foregroundSecondary)
                    }
                }
            }
            .padding(12)
        }
    }

    private func miniInfo(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(BNTokens.Typography.text(size: 10.5))
                .foregroundStyle(BNTokens.Colors.foregroundTertiary)
            Text(value)
                .bnNumeric(13, weight: .semibold)
                .foregroundStyle(BNTokens.Colors.foregroundPrimary)
        }
    }

    private func fundName(_ code: String) -> String {
        BacktestMockData.funds.first { $0.code == code }?.name ?? code
    }
}

private struct PortfolioPill: View {
    let portfolio: BacktestPortfolio
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 3) {
                Text(portfolio.name)
                    .font(BNTokens.Typography.text(size: 13))
                Text("\(portfolio.fundCodes.count) 只 · \(portfolio.weights.map { String(format: "%.0f", $0 * 100) }.joined(separator: "/"))%")
                    .bnNumeric(10.5)
                Text(portfolio.note)
                    .font(BNTokens.Typography.text(size: 9.5))
                    .lineLimit(1)
            }
            .foregroundStyle(selected ? BNTokens.Colors.accent : BNTokens.Colors.foregroundPrimary)
            .frame(width: 150, alignment: .leading)
            .padding(10)
            .background(selected ? BNTokens.Colors.accentDim : BNTokens.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(selected ? BNTokens.Colors.accent : BNTokens.Colors.border, lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct FieldRow: View {
    let title: String
    let value: String
    var detail: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(BNTokens.Typography.text(size: 10.5))
                .foregroundStyle(BNTokens.Colors.foregroundTertiary)
            Text(value)
                .font(BNTokens.Typography.text(size: 14))
                .foregroundStyle(BNTokens.Colors.foregroundPrimary)
            if let detail {
                Text(detail)
                    .bnNumeric(10.5)
                    .foregroundStyle(BNTokens.Colors.foregroundSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(BNTokens.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(BNTokens.Colors.border, lineWidth: 0.5)
        }
    }
}
