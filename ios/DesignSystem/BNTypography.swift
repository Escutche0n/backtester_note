import SwiftUI

/// Typography tokens — translation of bn-tokens.css text classes (`.bn-h1/2/3`, `.bn-num`,
/// `.bn-big-num`, `.bn-label`, `.bn-chip`, `.bn-btn`, `.bn-seg`).
///
/// Font family: Elvis visual override uses SF Pro Display Bold for Latin glyphs and PingFang SC
/// for Chinese glyphs. On iOS, `Font.system(..., weight: .bold)` resolves Latin text to SF Pro
/// and falls back to PingFang for Han glyphs. Numeric text uses the system monospaced family
/// through `Font.system(..., design: .monospaced)`, which is the iOS-safe SF Mono equivalent.
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

    // MARK: Family helpers

    static func text(size: CGFloat) -> Font {
        Font.system(size: size, weight: .bold)
    }

    static func number(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.system(size: size, weight: weight, design: .monospaced).monospacedDigit()
    }

    // MARK: Headings

    /// `.bn-h1 { font-size: 28px; font-weight: 700; letter-spacing: -0.02em }`. Fixed size.
    static let h1 = text(size: 28)

    /// `.bn-h2 { 20 / 700 / -0.02em }`. Fixed size.
    static let h2 = text(size: 20)

    /// `.bn-h3 { 15 / 600 / -0.01em }`. Fixed size.
    static let h3 = text(size: 15)

    /// Section label — `.bn-label { 11 / 600, uppercase, letter-spacing: 0.08em }`.
    /// Token gives only the base font; callers should apply `.kerning(0.88)` and
    /// `.textCase(.uppercase)` at the view layer.
    static let label = text(size: 11)

    // MARK: Body / supplementary

    /// `.bn-btn { 13 / 590 }`. Fixed size.
    static let button = text(size: 13)

    /// `.bn-seg > button { 12 / 590 }`. Fixed size.
    static let segmented = text(size: 12)

    /// `.bn-chip { 10.5 / 600, letter-spacing: 0.02em, tabular-nums }`. Fixed size.
    static let chip = text(size: 10.5).monospacedDigit()

    // MARK: Numerics — mono + tabular (alignment-critical)

    /// `.bn-num { font-family: var(--bn-mono); tabular-nums; letter-spacing: -0.02em }`.
    /// Body-sized monospaced numerics for inline figures.
    static let numericBody = number(size: 15)

    /// `.bn-big-num { mono / tabular / 600 / -0.03em }`. Used for large NAV / total figures.
    /// Size 28 chosen to match `.bn-h1` baseline so a label + big-num row reads cleanly.
    static let bigNumber = number(size: 28, weight: .semibold)
}
