import SwiftUI

struct BNAmbientBackground: View {
    var body: some View {
        ZStack {
            BNTokens.Colors.background

            RadialGradient(
                colors: [BNTokens.Colors.accent.opacity(0.08), .clear],
                center: .topLeading,
                startRadius: 20,
                endRadius: 360
            )

            RadialGradient(
                colors: [BNTokens.Colors.benchmark.opacity(0.08), .clear],
                center: .bottomTrailing,
                startRadius: 20,
                endRadius: 340
            )
        }
        .ignoresSafeArea()
    }
}
