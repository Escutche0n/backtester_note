import SwiftUI

/// Typography tokens — translation of bn-tokens.css text classes (`.bn-h1/2/3`, `.bn-num`,
/// `.bn-big-num`, `.bn-label`, `.bn-chip`, `.bn-btn`, `.bn-seg`).
///
/// Font family: CSS uses `-apple-system, "SF Pro Display", "SF Pro Text", "PingFang SC"...`.
/// On iOS, `Font.system(...)` already resolves to SF Pro, with Han glyphs falling back to
/// PingFang automatically. Mono uses `Font.system(..., design: .monospaced)` rather than
/// `Font.custom("SF Mono")` — system mono is guaranteed available; SF Mono is not bundled
/// on iOS by default.
///
/// Weight mapping (CSS → SwiftUI):
/// - `590` → `.semibold` (closest; SwiftUI exposes only standard weight steps)
/// - `600` → `.semibold`
/// - `700` → `.bold`
///
/// Dynamic Type: heading tokens (`h1/h2/h3`, body) use SwiftUI text styles where possible
/// so they scale with user accessibility settings. Numeric tokens (`numericBody`, `bigNumber`)
/// use **fixed sizes** with `.monospacedDigit()` because NAV / 占比 columns must stay
/// width-aligned across rows; Dynamic Type would break tabular alignment.
enum BNTypography {

    // MARK: Headings

    /// `.bn-h1 { font-size: 28px; font-weight: 700; letter-spacing: -0.02em }`. Fixed size.
    static let h1 = Font.system(size: 28, weight: .bold)

    /// `.bn-h2 { 20 / 700 / -0.02em }`. Fixed size.
    static let h2 = Font.system(size: 20, weight: .bold)

    /// `.bn-h3 { 15 / 600 / -0.01em }`. Fixed size.
    static let h3 = Font.system(size: 15, weight: .semibold)

    /// Section label — `.bn-label { 11 / 600, uppercase, letter-spacing: 0.08em }`.
    /// Token gives only the base font; callers should apply `.kerning(0.88)` and
    /// `.textCase(.uppercase)` at the view layer.
    static let label = Font.system(size: 11, weight: .semibold)

    // MARK: Body / supplementary

    /// `.bn-btn { 13 / 590 }`. Fixed size.
    static let button = Font.system(size: 13, weight: .semibold)

    /// `.bn-seg > button { 12 / 590 }`. Fixed size.
    static let segmented = Font.system(size: 12, weight: .semibold)

    /// `.bn-chip { 10.5 / 600, letter-spacing: 0.02em, tabular-nums }`. Fixed size.
    static let chip = Font.system(size: 10.5, weight: .semibold).monospacedDigit()

    // MARK: Numerics — mono + tabular (alignment-critical)

    /// `.bn-num { font-family: var(--bn-mono); tabular-nums; letter-spacing: -0.02em }`.
    /// Body-sized monospaced numerics for inline figures.
    static let numericBody = Font.system(size: 15, weight: .regular, design: .monospaced).monospacedDigit()

    /// `.bn-big-num { mono / tabular / 600 / -0.03em }`. Used for large NAV / total figures.
    /// Size 28 chosen to match `.bn-h1` baseline so a label + big-num row reads cleanly.
    static let bigNumber = Font.system(size: 28, weight: .semibold, design: .monospaced).monospacedDigit()
}
