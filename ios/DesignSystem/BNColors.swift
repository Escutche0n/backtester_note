import SwiftUI

/// Color tokens — Swift translation of `docs/design/project/lib/bn-tokens.css` `:root`,
/// plus Elvis-approved visual overrides captured in worklog.
///
/// Strategy: the design is a dark-only "PeakWatch-inspired dark dashboard". We do NOT split
/// Light/Dark; both modes use the same dark hex values. Design-source drift is captured in
/// worklog until `docs/design/` is deliberately refreshed.
/// If Light-mode adaptation is ever requested, switch to Asset Catalog with dual values.
///
/// CN market convention: `up = red (#F6465D)`, `down = green (#2EBD85)`.
enum BNColors {

    // MARK: Surfaces — warm near-black

    /// Elvis visual override: solid page background `#1E1E20`.
    static let background = Color(red: 0x1E / 255, green: 0x1E / 255, blue: 0x20 / 255)
    /// Elevated background, kept close to the solid page base.
    static let backgroundElevated = Color(red: 0x1E / 255, green: 0x1E / 255, blue: 0x20 / 255)
    /// `--bn-surface #17171C`
    static let surface = Color(red: 0x17 / 255, green: 0x17 / 255, blue: 0x1C / 255)
    /// `--bn-surface-2 #1E1E24`
    static let surfaceElevated = Color(red: 0x1E / 255, green: 0x1E / 255, blue: 0x24 / 255)

    /// `--bn-border rgba(255,255,255,0.06)`
    static let border = Color.white.opacity(0.06)
    /// `--bn-border-strong rgba(255,255,255,0.10)`
    static let borderStrong = Color.white.opacity(0.10)
    /// `--bn-hairline rgba(255,255,255,0.04)`
    static let hairline = Color.white.opacity(0.04)

    // MARK: Foreground / text

    /// `--bn-fg #F2F2F5`
    static let foregroundPrimary = Color(red: 0xF2 / 255, green: 0xF2 / 255, blue: 0xF5 / 255)
    /// `--bn-fg-dim α=0.62`
    static let foregroundSecondary = foregroundPrimary.opacity(0.62)
    /// `--bn-fg-mute α=0.38`
    static let foregroundTertiary = foregroundPrimary.opacity(0.38)
    /// `--bn-fg-faint α=0.22`
    static let foregroundQuaternary = foregroundPrimary.opacity(0.22)

    // MARK: Semantic — CN market (red up, green down)

    /// `--bn-up #F6465D` — 涨 = 红
    static let up = Color(red: 0xF6 / 255, green: 0x46 / 255, blue: 0x5D / 255)
    /// `--bn-up-soft rgba(246,70,93,0.14)`
    static let upSoft = up.opacity(0.14)
    /// `--bn-up-line rgba(246,70,93,0.9)`
    static let upLine = up.opacity(0.9)

    /// `--bn-down #2EBD85` — 跌 = 绿
    static let down = Color(red: 0x2E / 255, green: 0xBD / 255, blue: 0x85 / 255)
    /// `--bn-down-soft rgba(46,189,133,0.14)`
    static let downSoft = down.opacity(0.14)
    /// `--bn-down-line rgba(46,189,133,0.9)`
    static let downLine = down.opacity(0.9)

    // MARK: Accent

    /// `--bn-accent #E3B15C`
    static let accent = Color(red: 0xE3 / 255, green: 0xB1 / 255, blue: 0x5C / 255)
    /// `--bn-accent-dim rgba(227,177,92,0.18)`
    static let accentDim = accent.opacity(0.18)

    /// `--bn-benchmark #7A8AA8` — 沪深300 ref line
    static let benchmark = Color(red: 0x7A / 255, green: 0x8A / 255, blue: 0xA8 / 255)
}
