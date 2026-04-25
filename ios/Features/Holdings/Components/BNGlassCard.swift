import SwiftUI

struct BNGlassCard<Content: View>: View {
    private let radius: CGFloat
    private let content: Content

    init(radius: CGFloat = BNTokens.Radius.lg, @ViewBuilder content: () -> Content) {
        self.radius = radius
        self.content = content()
    }

    var body: some View {
        content
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(BNTokens.Colors.surfaceElevated)
            }
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(BNTokens.Colors.borderStrong, lineWidth: 0.5)
            }
            .shadow(
                color: BNTokens.Shadow.baseColor,
                radius: BNTokens.Shadow.baseRadius,
                y: BNTokens.Shadow.baseOffsetY
            )
    }
}
