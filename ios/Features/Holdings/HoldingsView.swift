import SwiftUI

struct HoldingsView: View {
    @State private var settingsPresented = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                TotalHeader(overview: HoldingsMockData.overview) {
                    settingsPresented = true
                }

                OverviewPanel(overview: HoldingsMockData.overview)
                NavCard()
                RadarCard()

                HoldingsList(
                    funds: HoldingsMockData.funds,
                    totalValue: HoldingsMockData.overview.totalValue
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
        .preferredColorScheme(.dark)
}
