# 2026-04-26 · ios · font-background-tuning

**Agent**: GPT
**Role**: Dev
**Scope**: Elvis 指派继续 1b 视觉微调：中文走 PingFang SC，英文走 SF Pro Display Bold，数字走 SF Mono 同族，纯色底色改为 `#1E1E20`。

## What changed

- `ios/DesignSystem/BNColors.swift`
  - 页面纯色背景 `background` 改为 `#1E1E20`。
  - `backgroundElevated` 同步贴近同一底色，避免 sheet / 二级背景继续偏黑。
- `ios/DesignSystem/BNTypography.swift`
  - 新增 `BNTypography.text(size:)`，统一非数字文本用 bold 系统字体；iOS 下拉丁字形走 SF Pro Display / system display，中文 glyph fallback 走 PingFang SC。
  - 新增 `BNTypography.number(size:weight:)`，统一数字使用 iOS system monospaced / SF Mono 同族并保留 tabular digit。
  - h1 / h2 / h3 / label / button / segmented / chip 改走该 helper。
- `ios/Features/**`
  - 将主要非数字 `.font(.system(...))` 调用改为 `BNTokens.Typography.text(size:)`。
  - `bnNumeric` 改为调用 `BNTokens.Typography.number(size:weight:)`，避免金额、百分比、NAV 列宽抖动。
- `ios/App/Assets.xcassets/AppIcon.appiconset/*.png`
  - AppIcon 外层纯色底同步改为 `#1E1E20`。

**未触动**：`docs/prd/`、`docs/design/`、`docs/contracts/`、`docs/algorithms/`、权限声明、网络代码、Widgets 业务代码。

## Contract change

无。只改 iOS 视觉实现与图标资源，不改 API / JSON / 算法契约。

## Algorithm drift

无。只改 UI 字体、颜色与图标资源，不改 NAV / XIRR / 雷达 / 回测算法。

## Verification

工作目录 `ios/`：

```
$ swift test
✔ Test run with 13 tests in 4 suites passed after 0.001 seconds.

$ xcodebuild -project BacktesterNote.xcodeproj -scheme BacktesterNote \
    -destination 'platform=iOS Simulator,name=iPhone 17' \
    -configuration Debug build CODE_SIGNING_ALLOWED=NO
** BUILD SUCCEEDED **
```

额外核对：

- 权限声明无 diff：`BacktesterNote.entitlements` / `BacktesterNoteWidgets.entitlements` 未变。
- 手写 Swift 文件行数已核对，最大文件 `Radar.swift` 286 行，均 ≤ 450 行。

## Review

⏳ 等另一方 review，重点看：

- `#1E1E20` 作为背景色后，卡片层级与文字对比是否仍清楚。
- 非数字文本加粗后，信息密度是否仍符合当前 mock UI。
- 数字使用 SF Mono 同族后是否符合投资工具的对齐需求。

## Conflict

无。

## Questions for Elvis

无。

## Ideas

- 若这套字体 / 底色定稿，后续应由 Claude Design 同步更新 `docs/design/project/lib/bn-tokens.css`，避免设计源和 Swift token 长期分叉。

## Next

- [ ] Review 本 worklog 与视觉实现。
- [ ] 回到 Phase 1c 下一刀：最小 Persistence / PortfolioService，接入“确认写入”。
