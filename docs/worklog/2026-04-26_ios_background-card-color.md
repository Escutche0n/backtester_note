# 2026-04-26 · ios · background-card-color

**Agent**: GPT
**Role**: Dev
**Scope**: Elvis 指派继续 1b 视觉微调：页面背景改纯黑，卡片底色固定为 `rgb(28, 28, 30)`。

## What changed

- `ios/DesignSystem/BNColors.swift`
  - `background` / `backgroundElevated` 改为纯黑 `#000000`。
  - `surface` / `surfaceElevated` 统一为 `rgb(28, 28, 30)` / `#1C1C1E`。
  - 卡片层级继续靠边框、间距和内容组织表达，不再用不同 fill 色制造层级。

**未触动**：`docs/prd/`、`docs/design/`、`docs/contracts/`、`docs/algorithms/`、权限声明、网络代码、Widgets 业务代码。

## Contract change

无。只改 iOS 视觉 token，不改 API / JSON / 算法契约。

## Algorithm drift

无。只改 UI 颜色，不改 NAV / XIRR / 雷达 / 回测算法。

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

- 纯黑背景和 `rgb(28, 28, 30)` 卡片之间的层级是否足够清晰。
- Settings / Import preview 等 sheet 背景改纯黑后是否符合整体视觉。

## Conflict

无。

## Questions for Elvis

无。

## Ideas

- 如果这组颜色定稿，后续应由 Claude Design 同步更新 `docs/design/project/lib/bn-tokens.css`。

## Next

- [ ] Review 本 worklog 与视觉实现。
- [ ] 回到 Phase 1c 下一刀：最小 Persistence / PortfolioService，接入“确认写入”。
