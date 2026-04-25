import SwiftUI

struct RadarCard: View {
    @State private var selectedKey = "current"

    private var selectedSnapshot: RadarSnapshot {
        HoldingsMockData.radarSnapshots.first { $0.key == selectedKey }
            ?? HoldingsMockData.radarSnapshots.last!
    }

    private var visibleSnapshots: [RadarSnapshot] {
        guard let index = HoldingsMockData.radarSnapshots.firstIndex(where: { $0.key == selectedKey }) else {
            return HoldingsMockData.radarSnapshots
        }
        return Array(HoldingsMockData.radarSnapshots.prefix(index + 1))
    }

    var body: some View {
        BNGlassCard(radius: 18) {
            VStack(alignment: .leading, spacing: 10) {
                header

                HStack(spacing: 4) {
                    MockRadarChart(
                        dimensions: HoldingsMockData.radarDimensions,
                        snapshots: visibleSnapshots
                    )
                    .frame(width: 206, height: 206)
                    .offset(x: -8)

                    scorePanel
                }
            }
            .padding(14)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("趋势雷达")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(BNTokens.Colors.foregroundSecondary)

                Text("六维度投资复盘评分")
                    .font(.system(size: 10.5))
                    .foregroundStyle(BNTokens.Colors.foregroundTertiary)
            }

            Spacer()

            Picker("快照", selection: $selectedKey) {
                ForEach(HoldingsMockData.radarSnapshots.reversed(), id: \.key) { snapshot in
                    Text(snapshot.title).tag(snapshot.key)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 136)
        }
    }

    private var scorePanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("总分")
                    .font(.system(size: 10.5, weight: .semibold))
                    .kerning(0.63)
                    .foregroundStyle(BNTokens.Colors.foregroundTertiary)

                Text(String(format: "%.1f", selectedSnapshot.score))
                    .bnNumeric(28, weight: .semibold)
                    .foregroundStyle(BNTokens.Colors.foregroundPrimary)

                if selectedKey == "current" {
                    Text("↑ 2.2 vs 上周")
                        .bnNumeric(10.5, weight: .semibold)
                        .foregroundStyle(BNTokens.Colors.up)
                }
            }

            VStack(spacing: 4) {
                ForEach(Array(HoldingsMockData.radarDimensions.enumerated()), id: \.offset) { index, dimension in
                    HStack(spacing: 6) {
                        Text(dimension)
                            .font(.system(size: 10.5))
                            .foregroundStyle(BNTokens.Colors.foregroundSecondary)
                            .lineLimit(1)

                        Spacer(minLength: 2)

                        Text(String(format: "%.0f", selectedSnapshot.values[index]))
                            .bnNumeric(10.5, weight: .semibold)
                            .foregroundStyle(BNTokens.Colors.foregroundPrimary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
