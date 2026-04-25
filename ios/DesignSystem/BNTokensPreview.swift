#if DEBUG
import SwiftUI

/// Visual catalog of every token, for hand-checking against bn-tokens.css in Xcode Canvas.
/// Not compiled into Release.
private struct BNTokensCatalog: View {
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: BNTokens.Spacing.l) {
                section("Surfaces") {
                    swatch("background", BNTokens.Colors.background)
                    swatch("backgroundElevated", BNTokens.Colors.backgroundElevated)
                    swatch("surface", BNTokens.Colors.surface)
                    swatch("surfaceElevated", BNTokens.Colors.surfaceElevated)
                }
                section("Borders") {
                    swatch("border", BNTokens.Colors.border)
                    swatch("borderStrong", BNTokens.Colors.borderStrong)
                    swatch("hairline", BNTokens.Colors.hairline)
                }
                section("Foreground") {
                    foregroundRow("foregroundPrimary", BNTokens.Colors.foregroundPrimary)
                    foregroundRow("foregroundSecondary", BNTokens.Colors.foregroundSecondary)
                    foregroundRow("foregroundTertiary", BNTokens.Colors.foregroundTertiary)
                    foregroundRow("foregroundQuaternary", BNTokens.Colors.foregroundQuaternary)
                }
                section("Semantic — CN market") {
                    swatch("up (涨=红)", BNTokens.Colors.up)
                    swatch("upSoft", BNTokens.Colors.upSoft)
                    swatch("upLine", BNTokens.Colors.upLine)
                    swatch("down (跌=绿)", BNTokens.Colors.down)
                    swatch("downSoft", BNTokens.Colors.downSoft)
                    swatch("downLine", BNTokens.Colors.downLine)
                }
                section("Accent / benchmark") {
                    swatch("accent", BNTokens.Colors.accent)
                    swatch("accentDim", BNTokens.Colors.accentDim)
                    swatch("benchmark", BNTokens.Colors.benchmark)
                }
                section("Typography") {
                    Text("h1 — 持仓 28/700").font(BNTokens.Typography.h1)
                    Text("h2 — 持仓 20/700").font(BNTokens.Typography.h2)
                    Text("h3 — 持仓 15/600").font(BNTokens.Typography.h3)
                    Text("LABEL 11/600 UPPER")
                        .font(BNTokens.Typography.label)
                        .kerning(0.88)
                        .textCase(.uppercase)
                    Text("button 13/590").font(BNTokens.Typography.button)
                    Text("segmented 12/590").font(BNTokens.Typography.segmented)
                    Text("chip 10.5/600 +1.23%").font(BNTokens.Typography.chip)
                    Text("numericBody 1,234,567.89").font(BNTokens.Typography.numericBody)
                    Text("¥ 1,234,567.89").font(BNTokens.Typography.bigNumber)
                }
                section("Radius") {
                    radiusSwatch("sm 10", BNTokens.Radius.sm)
                    radiusSwatch("md 14", BNTokens.Radius.md)
                    radiusSwatch("lg 20", BNTokens.Radius.lg)
                    radiusSwatch("xl 28", BNTokens.Radius.xl)
                }
                section("Spacing") {
                    spacingSwatch("xs 4", BNTokens.Spacing.xs)
                    spacingSwatch("s 8", BNTokens.Spacing.s)
                    spacingSwatch("m 12", BNTokens.Spacing.m)
                    spacingSwatch("l 16", BNTokens.Spacing.l)
                    spacingSwatch("xl 24", BNTokens.Spacing.xl)
                }
            }
            .padding(BNTokens.Spacing.l)
        }
        .background(BNTokens.Colors.background.ignoresSafeArea())
        .foregroundStyle(BNTokens.Colors.foregroundPrimary)
    }

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: BNTokens.Spacing.s) {
            Text(title)
                .font(BNTokens.Typography.label)
                .kerning(0.88)
                .textCase(.uppercase)
                .foregroundStyle(BNTokens.Colors.foregroundTertiary)
            content()
        }
    }

    private func swatch(_ name: String, _ color: Color) -> some View {
        HStack(spacing: BNTokens.Spacing.m) {
            RoundedRectangle(cornerRadius: BNTokens.Radius.sm)
                .fill(color)
                .frame(width: 56, height: 32)
                .overlay(
                    RoundedRectangle(cornerRadius: BNTokens.Radius.sm)
                        .stroke(BNTokens.Colors.borderStrong, lineWidth: 0.5)
                )
            Text(name).font(BNTokens.Typography.numericBody)
        }
    }

    private func foregroundRow(_ name: String, _ color: Color) -> some View {
        Text(name)
            .font(BNTokens.Typography.h3)
            .foregroundStyle(color)
    }

    private func radiusSwatch(_ name: String, _ radius: CGFloat) -> some View {
        HStack(spacing: BNTokens.Spacing.m) {
            RoundedRectangle(cornerRadius: radius)
                .fill(BNTokens.Colors.surfaceElevated)
                .frame(width: 64, height: 40)
            Text(name).font(BNTokens.Typography.numericBody)
        }
    }

    private func spacingSwatch(_ name: String, _ value: CGFloat) -> some View {
        HStack(spacing: BNTokens.Spacing.m) {
            Rectangle()
                .fill(BNTokens.Colors.accent)
                .frame(width: value, height: 16)
            Text(name).font(BNTokens.Typography.numericBody)
        }
    }
}

#Preview("BNTokens catalog") {
    BNTokensCatalog()
        .preferredColorScheme(.dark)
}
#endif
