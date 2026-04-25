import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            Text("持仓占位")
                .font(BNTokens.Typography.h1)
                .foregroundStyle(BNTokens.Colors.foregroundPrimary)
                .tabItem {
                    Label("持仓", systemImage: "chart.pie")
                }

            Text("回测占位")
                .font(BNTokens.Typography.h1)
                .foregroundStyle(BNTokens.Colors.foregroundPrimary)
                .tabItem {
                    Label("回测", systemImage: "chart.line.uptrend.xyaxis")
                }
        }
    }
}

#Preview {
    RootTabView()
}
