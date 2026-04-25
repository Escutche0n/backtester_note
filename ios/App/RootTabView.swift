import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            Text("持仓占位")
                .tabItem {
                    Label("持仓", systemImage: "chart.pie")
                }

            Text("回测占位")
                .tabItem {
                    Label("回测", systemImage: "chart.line.uptrend.xyaxis")
                }
        }
    }
}

#Preview {
    RootTabView()
}
