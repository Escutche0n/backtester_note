import SwiftUI

/// Unified entry point for design tokens. Callers should reference tokens through this
/// namespace (`BNTokens.Colors.foregroundPrimary`, `BNTokens.Typography.h1`, etc.) rather
/// than the underlying `BNColors` / `BNTypography` / `BNSpacing` enums directly. This keeps
/// the public surface stable if we later reorganize the token internals.
///
/// Source of truth: `docs/design/project/lib/bn-tokens.css`. Do not introduce token values
/// here that are not present in the CSS — extend the CSS first (Design's job) then mirror.
enum BNTokens {
    typealias Colors = BNColors
    typealias Typography = BNTypography
    typealias Spacing = BNSpacing
    typealias Radius = BNRadius
    typealias Shadow = BNShadow
}
