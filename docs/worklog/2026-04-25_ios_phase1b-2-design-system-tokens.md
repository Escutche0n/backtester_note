# 2026-04-25 · ios · phase1b-2-design-system-tokens

**Agent**: Opus
**Role**: Dev
**Scope**: Phase 1b commit C — 把 `docs/design/project/lib/bn-tokens.css` 翻译成 SwiftUI token 层（仅 token，不做组件、不画 UI），让后续 view 有统一的 color / typography / spacing 入口。

## What changed

新增 `ios/DesignSystem/`（4 个 token 文件 + 1 个 Preview，全部由 BacktesterNote app target 编译，未被 Widgets target 引用）：

- `ios/DesignSystem/BNColors.swift`：18 条语义色（surfaces / borders / foreground / up-down / accent / benchmark），dark-only，直接用 `Color(red:green:blue:)` 写常量，不进 Asset Catalog（避免双权威）。
- `ios/DesignSystem/BNTypography.swift`：10 条字体 token（h1/h2/h3/label/button/segmented/chip/numericBody/bigNumber + body 隐含），mono 用 `Font.system(..., design: .monospaced).monospacedDigit()`，强对齐数字用固定 size（注释说明为何不上 Dynamic Type）。
- `ios/DesignSystem/BNSpacing.swift`：`BNRadius`（sm/md/lg/xl，直接对应 CSS 数值）+ `BNSpacing`（xs/s/m/l/xl 五档，4/8/12/16/24，CSS 没显式声明，按 padding 实际值归纳）+ `BNShadow`（仅单层 base drop shadow，多层 glass 留给 commit D 组件级）。
- `ios/DesignSystem/BNTokens.swift`：统一 namespace，`enum BNTokens { typealias Colors / Typography / Spacing / Radius / Shadow }`，对外只暴露这一个入口。
- `ios/DesignSystem/BNTokensPreview.swift`：`#if DEBUG` 整个文件包裹，`#Preview` 用 ScrollView/LazyVStack 列出每个 token 的色块 / 文本 / 半径 / 间距样例，dark scheme。Release 不打包。

修改：

- `ios/project.yml`：`BacktesterNote` target 的 `sources` 追加 `- path: DesignSystem`。**Widgets target 未触动**（widgets 用 token 是后续 commit 的事）。
- `ios/App/RootTabView.swift`：两个 Tab 文案各加 `.font(BNTokens.Typography.h1).foregroundStyle(BNTokens.Colors.foregroundPrimary)`，证明 token 链路通。其余结构不变。

**未触动**（commit gate 守住）：`docs/contracts/` `docs/algorithms/` `docs/prd/` `docs/design/` `docs/architecture/` `ios/Sources/` `ios/Tests/` `ios/Package.swift` `ios/Widgets/` `ios/App/Entitlements/` `ios/App/Info.plist` `ios/App/BacktesterNoteApp.swift`。

## Contract change

无。

## Algorithm drift

无。

## CSS → Swift 映射表（数字级对照）

### Color（`:root` 部分）

| CSS token | CSS 值 | Swift 常量 |
|---|---|---|
| `--bn-bg` | `#0B0B0D` | `BNTokens.Colors.background` |
| `--bn-bg-elev` | `#141418` | `BNTokens.Colors.backgroundElevated` |
| `--bn-surface` | `#17171C` | `BNTokens.Colors.surface` |
| `--bn-surface-2` | `#1E1E24` | `BNTokens.Colors.surfaceElevated` |
| `--bn-border` | `rgba(255,255,255,0.06)` | `BNTokens.Colors.border` |
| `--bn-border-strong` | `rgba(255,255,255,0.10)` | `BNTokens.Colors.borderStrong` |
| `--bn-hairline` | `rgba(255,255,255,0.04)` | `BNTokens.Colors.hairline` |
| `--bn-fg` | `#F2F2F5` | `BNTokens.Colors.foregroundPrimary` |
| `--bn-fg-dim` | `rgba(242,242,245,0.62)` | `BNTokens.Colors.foregroundSecondary` |
| `--bn-fg-mute` | `rgba(242,242,245,0.38)` | `BNTokens.Colors.foregroundTertiary` |
| `--bn-fg-faint` | `rgba(242,242,245,0.22)` | `BNTokens.Colors.foregroundQuaternary` |
| `--bn-up` | `#F6465D` | `BNTokens.Colors.up`（CN: 涨=红） |
| `--bn-up-soft` | `rgba(246,70,93,0.14)` | `BNTokens.Colors.upSoft` |
| `--bn-up-line` | `rgba(246,70,93,0.9)` | `BNTokens.Colors.upLine` |
| `--bn-down` | `#2EBD85` | `BNTokens.Colors.down`（CN: 跌=绿） |
| `--bn-down-soft` | `rgba(46,189,133,0.14)` | `BNTokens.Colors.downSoft` |
| `--bn-down-line` | `rgba(46,189,133,0.9)` | `BNTokens.Colors.downLine` |
| `--bn-accent` | `#E3B15C` | `BNTokens.Colors.accent` |
| `--bn-accent-dim` | `rgba(227,177,92,0.18)` | `BNTokens.Colors.accentDim` |
| `--bn-benchmark` | `#7A8AA8` | `BNTokens.Colors.benchmark` |

### Radius

| CSS token | CSS 值 | Swift 常量 |
|---|---|---|
| `--bn-r-sm` | `10px` | `BNTokens.Radius.sm` (10) |
| `--bn-r-md` | `14px` | `BNTokens.Radius.md` (14) |
| `--bn-r-lg` | `20px` | `BNTokens.Radius.lg` (20) |
| `--bn-r-xl` | `28px` | `BNTokens.Radius.xl` (28) |

### Typography

| CSS class | CSS 值 | Swift 常量 | 备注 |
|---|---|---|---|
| `.bn-h1` | 28 / 700 / -0.02em | `Typography.h1` (size 28, .bold) | letter-spacing 在 SwiftUI 由 `.tracking` 在视图层补；token 只给 font |
| `.bn-h2` | 20 / 700 / -0.02em | `Typography.h2` | 同上 |
| `.bn-h3` | 15 / 600 / -0.01em | `Typography.h3` | 同上 |
| `.bn-label` | 11 / 600 / 0.08em / uppercase | `Typography.label` | 视图侧再 `.kerning(0.88).textCase(.uppercase)` |
| `.bn-btn` | 13 / 590 | `Typography.button` | 590 → SwiftUI `.semibold` |
| `.bn-seg > button` | 12 / 590 | `Typography.segmented` | |
| `.bn-chip` | 10.5 / 600 / 0.02em / tabular | `Typography.chip` | `.monospacedDigit()` 已包 |
| `.bn-num` | mono / tabular / -0.02em | `Typography.numericBody` (size 15) | size 15 是 body 默认；CSS 该 class 不指定 size，由父级继承 |
| `.bn-big-num` | mono / tabular / 600 / -0.03em | `Typography.bigNumber` (size 28) | size 28 与 `.bn-h1` 同高，让 label + big-num 行对齐 |

### Spacing（CSS 没显式声明，按 padding 出现频率归纳）

| Swift 常量 | 值 | 出处推测 |
|---|---|---|
| `Spacing.xs` | 4 | `.bn-chip gap: 4px` |
| `Spacing.s` | 8 | `.bn-btn padding: 8px ...` |
| `Spacing.m` | 12 | 通用内容间距 |
| `Spacing.l` | 16 | section / card 边距 |
| `Spacing.xl` | 24 | 大段落分隔 |

### Shadow（仅 base 单层）

| 常量 | 值 | 备注 |
|---|---|---|
| `Shadow.baseColor` | `Color.black.opacity(0.25)` | 对应 `0 1px 2px rgba(0,0,0,0.25)` |
| `Shadow.baseRadius` | 2 | |
| `Shadow.baseOffsetY` | 1 | |

`.bn-glass` / `.bn-tabbar` 多层叠加 + inset highlight + backdrop-filter **不在 token 层翻译** —— SwiftUI 没有 inset shadow 原语，需要 commit D 在 Card / TabBar 组件用 `Material` + `overlay(stroke)` + `shadow` 在视图层重组。

## Verification

工作目录 `ios/`：

```
$ xcodegen generate
⚙️  Generating plists...
⚙️  Generating project...
⚙️  Writing project...
Created project at /Users/elvischen/Developer/backtester_note/ios/BacktesterNote.xcodeproj

$ xcodebuild -project BacktesterNote.xcodeproj -scheme BacktesterNote \
    -destination 'platform=iOS Simulator,name=iPhone 17' \
    -configuration Debug build CODE_SIGNING_ALLOWED=NO
... (App + Widgets 全部链接)
** BUILD SUCCEEDED **

$ swift test
✔ Test run with 10 tests in 4 suites passed after 0.001 seconds.
```

`git status` 仅含本 commit 范围内文件（未触动 forbidden 路径，已核对）。

**待 Elvis 人工跑**：在 Xcode 打开 `ios/BacktesterNote.xcodeproj`，

1. 选 iPhone 17 模拟器 Run，两个 Tab 文案应为 28pt bold + 浅灰 `#F2F2F5`（颜色已切到 token，与 commit B 系统默认 17pt 区别明显）。
2. 在 Project navigator 里点开 `DesignSystem/BNTokensPreview.swift`，按 Cmd+Option+Enter 打开 Canvas，肉眼比对色块 / 字号 / 半径 / 间距是否与 [docs/design/project/lib/bn-tokens.css](../../docs/design/project/lib/bn-tokens.css) 一致。

## Review

✅ 通过（GPT Review，2026-04-25）。

审查范围：
- 已按 Elvis 指令先读 `AGENTS.md`，再读本 worklog 与 commit `3a38419` 改动文件。
- 对照实际设计源 `docs/design/project/lib/bn-tokens.css` 复核 `BNColors` / `BNTypography` / `BNSpacing` / `BNTokens` / `BNTokensPreview` / `RootTabView` / `project.yml`。
- 额外核对 `docs/prd/Backtester_Note_PRD_v2.md` §7.1 的设计 token 映射要求。

结论：
- CSS → Swift 数值映射通过：surface / border / foreground / up-down / accent / benchmark / radius / typography 主值与 `bn-tokens.css` 一致；`up = red`、`down = green` 与 CN market 注释一致，未反。
- `BNSpacing` 的 4 / 8 / 12 / 16 / 24 属于 CSS 未声明 spacing scale 下的实现归纳；worklog 已明示来源与边界，且未把 button/chip 组件 padding 提前做成 token，符合本 commit "token only" 范围。
- `.bn-glass` / `.bn-tabbar` / `.bn-frost` 多层视觉推迟到组件级是合理的：当前只落 base shadow，不提前写 component modifier，未越过 commit D 的组件实现边界。
- 未触动 `docs/prd/`、`docs/design/`、`docs/contracts/`、权限声明、算法口径或 Widgets target；无 contract change、无 algorithm drift。
- 单代码文件均低于 450 行：本次相关 Swift 文件最大 `BNTokensPreview.swift` 128 行。

验证：
- `swift test`：通过，10 tests / 4 suites。
- `xcodebuild -project BacktesterNote.xcodeproj -scheme BacktesterNote -destination 'platform=iOS Simulator,name=iPhone 17' -configuration Debug build CODE_SIGNING_ALLOWED=NO`：通过，`** BUILD SUCCEEDED **`。

非阻塞备注：
- 当前仓库实际设计路径是 `docs/design/project/lib/bn-tokens.css`；部分文档仍写 `docs/design/backtester-note/...`。本 commit 使用了实际存在的设计源，未造成实现偏差。

## Questions for Elvis

以下三条本 commit **没有强行决断**，等 Elvis 答复后下个 commit 一并补；不阻塞本次提交：

1. **Light mode 是否要支持？** 当前策略是 dark-only（color 直接写常量，Light/Dark 都用同一组 hex），跟设计稿 "PeakWatch-inspired dark dashboard" 一致。如果你要 Light 适配，下个 commit 把 `BNColors` 迁到 Asset Catalog 双值。
2. **`.bn-root` 上的 ambient radial gradient**（CSS `.bn-root` 第二段：`radial-gradient(90% 60% at 0% 0%, rgba(227,177,92,0.06)...)`）是 token 还是组件级背景？我倾向**组件级**（在 RootTabView 的 ZStack 底层画一次），不进 token 命名空间。等你裁定。
3. **雷达六维各自的色阶**：bn-tokens.css 只给 `accent / up / down / benchmark`，没有专门给雷达六维（盈利能力 / 质量 / 估值 / 成长 / 风控 / 策略执行）各一色。等你给方向（用 accent 单色 + 透明度梯度？还是六色调色板？），雷达图绘制（commit 之后某个）再落色 token。

## Ideas

- 后续可以加 `BNTokensSnapshotTests`（用 `swift-snapshot-testing` 或纯 hash 比对）让 CSS 与 Swift token 数值漂移会被 CI catch，而不是靠肉眼。**不在本 commit 范围**，写进这里备忘。
- `Color(red:green:blue:)` 用 sRGB；如果以后接 WideColor 显示，可改 `Color(.sRGB, red:..., green:..., blue:..., opacity:1)` 显式声明色彩空间，避免 P3 屏幕上轻微偏色。

## Next

- [ ] GPT review 本 worklog（CSS→Swift 数值对照）。
- [ ] Elvis 回答 `Questions for Elvis` 三条。
- [ ] Opus 下一个 session：commit D — Holdings mock UI（用 token 画 Card / Chip / Row 第一片）。
