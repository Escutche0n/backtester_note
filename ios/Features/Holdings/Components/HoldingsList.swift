import SwiftUI

struct HoldingsList: View {
    let funds: [HoldingFund]
    let totalValue: Double
    @State private var sortKey = "按市值"

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("持仓基金 · \(funds.count)")
                    .font(BNTokens.Typography.text(size: 12))
                    .foregroundStyle(BNTokens.Colors.foregroundSecondary)

                Spacer()

                // mock: 排序逻辑留给真实数据接入（1d）
                Picker("排序", selection: $sortKey) {
                    Text("按市值").tag("按市值")
                    Text("按收益").tag("按收益")
                    Text("按失衡").tag("按失衡")
                }
                .pickerStyle(.segmented)
                .frame(width: 164)
            }

            ForEach(funds) { fund in
                HoldingCard(fund: fund, totalValue: totalValue)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 104)
    }
}
