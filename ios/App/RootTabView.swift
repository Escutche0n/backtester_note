import SwiftUI

struct RootTabView: View {
    @StateObject private var portfolioService = PortfolioService()
    @StateObject private var fundNAVService = FundNAVService()

    var body: some View {
        TabView {
            HoldingsView()
                .tabItem {
                    Label("持仓", systemImage: "chart.pie")
                }

            BacktestView()
                .tabItem {
                    Label("回测", systemImage: "chart.line.uptrend.xyaxis")
                }
        }
        .tint(BNTokens.Colors.foregroundPrimary)
        .preferredColorScheme(.dark)
        .environmentObject(portfolioService)
        .environmentObject(fundNAVService)
    }
}

#Preview {
    RootTabView()
}
