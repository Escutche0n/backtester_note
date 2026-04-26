import SwiftUI

struct BacktestView: View {
    @State private var mode: BacktestMode = .portfolio

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                header
                modePicker

                if mode == .history {
                    BacktestHistoryList(items: BacktestMockData.history)
                } else {
                    BacktestConfigCard(mode: mode)
                    BacktestResultPreview()
                    Spacer(minLength: 100)
                }
            }
        }
        .background(BNAmbientBackground())
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Backtest")
                    .font(BNTokens.Typography.label)
                    .kerning(0.88)
                    .foregroundStyle(BNTokens.Colors.foregroundTertiary)

                Text("回测")
                    .font(BNTokens.Typography.text(size: 26))
                    .foregroundStyle(BNTokens.Colors.foregroundPrimary)
            }

            Spacer()

            Button {
                BNHaptics.tap()
                // TODO 1f: prefill ConfigCard from current holdings (PRD §7.3)
            } label: {
                Label("新建", systemImage: "plus")
                    .font(BNTokens.Typography.text(size: 11))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
            }
            .buttonStyle(.bordered)
            .tint(BNTokens.Colors.foregroundSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 6)
    }

    private var modePicker: some View {
        Picker("回测模式", selection: $mode) {
            ForEach(BacktestMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .sensoryFeedback(.selection, trigger: mode)
    }
}

#Preview {
    BacktestView()
        .preferredColorScheme(.dark)
}
