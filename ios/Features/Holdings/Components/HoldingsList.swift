import SwiftUI

struct HoldingsList: View {
    let funds: [HoldingFund]
    let totalValue: Double

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("持仓基金 · \(funds.count)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(BNTokens.Colors.foregroundSecondary)

                Spacer()

                Picker("排序", selection: .constant("按市值")) {
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
