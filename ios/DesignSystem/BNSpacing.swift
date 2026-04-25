import SwiftUI

/// Spacing, radius, and shadow tokens.
///
/// Radius: direct map from `--bn-r-{sm,md,lg,xl}` in bn-tokens.css.
///
/// Spacing: bn-tokens.css does not declare a spacing scale; spacing values are inlined
/// in component padding (e.g. `.bn-btn padding: 8px 14px`, `.bn-chip padding: 2px 7px`).
/// We synthesize a 5-step scale (4 / 8 / 12 / 16 / 24) covering the common multiples seen
/// in the design. Component-specific paddings (button / chip) are intentionally NOT exposed
/// here — they belong to component implementations in a later commit.
///
/// Shadow: bn-tokens.css uses multi-layer inset highlights + drop shadows + `backdrop-filter`
/// for `.bn-glass` and `.bn-tabbar`. SwiftUI has no inset-shadow primitive, so the full glass
/// effect must be reconstructed at the **component level** (Card / TabBar) using
/// `.background(.ultraThinMaterial)` + `.overlay(stroke)` + `.shadow(...)` in stack.
/// At the token layer we expose only a single-layer base drop shadow used as the outermost
/// element of those stacks. Multi-layer composition is a commit-D concern.
enum BNRadius {
    /// `--bn-r-sm 10px`
    static let sm: CGFloat = 10
    /// `--bn-r-md 14px`
    static let md: CGFloat = 14
    /// `--bn-r-lg 20px`
    static let lg: CGFloat = 20
    /// `--bn-r-xl 28px`
    static let xl: CGFloat = 28
}

enum BNSpacing {
    /// 4pt — hairline gap (icon ↔ label, chip internal).
    static let xs: CGFloat = 4
    /// 8pt — small gap (row internal, button vertical padding).
    static let s: CGFloat = 8
    /// 12pt — default content gap.
    static let m: CGFloat = 12
    /// 16pt — section / card edge inset.
    static let l: CGFloat = 16
    /// 24pt — large section break.
    static let xl: CGFloat = 24
}

/// Single-layer drop shadow base. For `.bn-glass` / `.bn-tabbar` style multi-layer
/// effects, compose at component level — do NOT chain multiple `BNShadow.*` here.
enum BNShadow {
    /// `box-shadow: 0 1px 2px rgba(0,0,0,0.25)` — base subtle elevation.
    static let baseColor = Color.black.opacity(0.25)
    static let baseRadius: CGFloat = 2
    static let baseOffsetY: CGFloat = 1
}
