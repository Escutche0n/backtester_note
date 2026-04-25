# 2026-04-26 · ios · solid-theme-app-icon

**Agent**: GPT
**Role**: Dev
**Scope**: Elvis 指派做 1b 视觉微调：补 App 图标，并把当前 UI 从渐变 / 玻璃感调整为截图参考的纯色暗色面。

## What changed

- `ios/App/Assets.xcassets/AppIcon.appiconset/`
  - 新增 iPhone AppIcon asset catalog，含 20 / 29 / 40 / 60pt 与 1024 marketing icon。
  - 图标采用纯深色底、金色手记卡片轮廓、净值折线与基准线，和当前 App 的 dark dashboard / amber accent 统一。
- `ios/project.yml`
  - `BacktesterNote` target 新增 `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon`。
- `ios/DesignSystem/BNBackground.swift`
  - `BNAmbientBackground` 从双径向 ambient gradient 改为单一 `BNTokens.Colors.background` 纯色背景。
- `ios/Features/Holdings/Components/BNGlassCard.swift`
  - 通用卡片从 Material + LinearGradient 改为 `surfaceElevated` 固定色块。
- `ios/Features/Holdings/Components/HoldingCard.swift`
  - 持仓基金卡从 ultraThinMaterial + LinearGradient 改为 `surface` 固定色块。
- `ios/Features/Shared/MockLineChart.swift`
  - 曲线填充从上下渐隐 LinearGradient 改为单色透明填充。
- `ios/DesignSystem/BNSpacing.swift`
  - 更新注释，避免继续描述已移除的 Material 组合方式。

**未触动**：`docs/prd/`、`docs/design/`、`docs/contracts/`、`docs/algorithms/`、权限声明、网络代码、Widgets 业务代码。

## Contract change

无。只改 iOS 视觉实现与 AppIcon 配置，不改 API / JSON / 算法契约。

## Algorithm drift

无。只改 UI 绘制与图标资源，不改 NAV / XIRR / 雷达 / 回测算法。

## Verification

工作目录 `ios/`：

```
$ xcodegen generate
Created project at /Users/elvischen/Developer/backtester_note/ios/BacktesterNote.xcodeproj

$ swift test
✔ Test run with 13 tests in 4 suites passed after 0.001 seconds.

$ xcodebuild -project BacktesterNote.xcodeproj -scheme BacktesterNote \
    -destination 'platform=iOS Simulator,name=iPhone 17' \
    -configuration Debug build CODE_SIGNING_ALLOWED=NO
** BUILD SUCCEEDED **
```

额外核对：

- `rg "LinearGradient|RadialGradient|regularMaterial|ultraThinMaterial|gradient|Gradient" ios --glob '!**/.build/**'` 无实际代码命中。
- 权限声明无 diff：`BacktesterNote.entitlements` / `BacktesterNoteWidgets.entitlements` 未变。
- 手写 Swift 文件行数已核对，最大文件 `Radar.swift` 286 行，均 ≤ 450 行。

## Review

⏳ 等另一方 review，重点看：

- 纯色暗色面是否符合 Elvis 给的截图方向。
- AppIcon 是否足够表达“回测手记 / 投资复盘”而不过度复杂。
- 去掉 Material / gradient 后是否仍然保留足够层级感。

## Conflict

无。

## Questions for Elvis

无。

## Ideas

- 如果后续确认彻底转向截图这种纯色 PeakWatch 风格，可以由 Claude Design 更新 `docs/design/project/lib/bn-tokens.css`，让设计源文件也从 Liquid Glass gradient 改为纯色版本；本次按红线不修改 `docs/design/`。

## Next

- [ ] Review 本 worklog 与视觉实现。
- [ ] 回到 Phase 1c 下一刀：最小 Persistence / PortfolioService，接入“确认写入”。
