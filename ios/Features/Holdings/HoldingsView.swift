import SwiftUI

struct HoldingsView: View {
    @EnvironmentObject private var portfolioService: PortfolioService
    @State private var settingsPresented = false

    private var displayData: HoldingsDisplayData {
        if let account = portfolioService.currentAccount,
           let data = HoldingsDisplayData(account: account) {
            return data
        }
        return .mock
    }

    var body: some View {
        let data = displayData

        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                TotalHeader(overview: data.overview) {
                    settingsPresented = true
                }

                OverviewPanel(overview: data.overview)
                NavCard()
                RadarCard()

                HoldingsList(
                    funds: data.funds,
                    totalValue: data.overview.totalValue
                )
            }
        }
        .background(BNAmbientBackground())
        .sheet(isPresented: $settingsPresented) {
            SettingsSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

#Preview {
    HoldingsView()
        .environmentObject(PortfolioService(store: PortfolioFileStore(fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("holdings-preview.json"))))
        .preferredColorScheme(.dark)
}

private struct HoldingsDisplayData {
    let overview: HoldingsOverview
    let funds: [HoldingFund]

    init(overview: HoldingsOverview, funds: [HoldingFund]) {
        self.overview = overview
        self.funds = funds
    }

    static let mock = HoldingsDisplayData(
        overview: HoldingsMockData.overview,
        funds: HoldingsMockData.funds
    )

    init?(account: PortfolioAccount) {
        guard let latest = account.snapshots.sorted(by: { $0.date < $1.date }).last,
              let baseline = account.snapshots.first(where: \.isBaseline)
        else {
            return nil
        }

        let totalValue = latest.holdings.reduce(0) { $0 + $1.value }
        let baselineValue = baseline.holdings.reduce(0) { $0 + $1.value }
        let netInput = account.flows.reduce(0) { partial, flow in
            partial + Self.netInput(for: flow)
        }
        let costBasis = baselineValue + netInput
        let holdPnl = totalValue - costBasis
        let holdPct = costBasis > 0 ? holdPnl / costBasis * 100 : 0

        overview = HoldingsOverview(
            totalValue: totalValue,
            unitNAV: baselineValue > 0 ? totalValue / baselineValue : 1,
            dayPnl: 0,
            dayPct: 0,
            dayDrawdown: 0,
            holdPnl: holdPnl,
            holdPct: holdPct,
            xirr: 0,
            excess: 0,
            maxDrawdown6M: 0,
            sharpe: 0,
            calmar: 0,
            unbalance: 0
        )

        funds = latest.holdings.map { holding in
            let baselineHolding = baseline.holdings.first(where: { $0.code == holding.code })
            let cost = baselineHolding?.value ?? holding.value
            let holdPct = cost > 0 ? (holding.value - cost) / cost * 100 : 0

            return HoldingFund(
                id: holding.code,
                code: holding.code,
                name: holding.name,
                type: "持仓",
                targetWeight: totalValue > 0 ? holding.value / totalValue : 0,
                value: holding.value,
                cost: cost,
                shares: holding.shares,
                dayPct: 0,
                holdPct: holdPct,
                sparkline: HoldingsMockData.makeSeries(days: 30, seed: Self.sparklineSeed(for: holding.code), volatility: 0.004, drift: 0)
            )
        }
    }

    private static func netInput(for flow: PortfolioFlow) -> Double {
        switch flow.type {
        case .buy, .transferIn:
            flow.amount
        case .sell, .transferOut:
            -flow.amount
        case .dividend:
            flow.shares == 0 ? -flow.amount : 0
        }
    }

    private static func sparklineSeed(for code: String) -> UInt64 {
        code.unicodeScalars.reduce(0) { partial, scalar in
            partial &* 31 &+ UInt64(scalar.value)
        }
    }
}
