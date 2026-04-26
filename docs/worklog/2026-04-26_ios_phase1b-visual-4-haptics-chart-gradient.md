# 2026-04-26 · ios · phase1b-visual-4-haptics-chart-gradient

**Agent**: Claude / Opus
**Role**: Dev (Elvis 当面指派)
**Scope**: 1b-visual 系列第 4 刀 —— 加基础 haptic 反馈 + `MockLineChart` 改成 vertical gradient 渲染（Peak watch 风格），让当前 UI 不那么"硬"。不动 PRD §7.1 的红涨绿跌色规则，只换图表渲染层。

## What changed

- `ios/DesignSystem/BNHaptics.swift`（new）
  - 三档 helper：`tap()` light impact、`emphasis()` medium impact、`success()` notification success。
  - 直接用 `UIImpactFeedbackGenerator` / `UINotificationFeedbackGenerator`，按用即建即丢，不持有实例（轻量调用足够，不需要 prepare）。
- 接入点（按"用户每次能感到、且语义清晰"的原则）：
  - `TotalHeader.swift` → 设置齿轮 → `BNHaptics.tap()`
  - `HoldingsList.swift` → 排序 Picker → `.sensoryFeedback(.selection, trigger: sortKey)`
  - `NavCard.swift` → 范围 Picker → `.sensoryFeedback(.selection, trigger: selectedRange)`
  - `RadarCard.swift` → 快照 Picker → `.sensoryFeedback(.selection, trigger: selectedKey)`
  - `BacktestView.swift` → 「新建」按钮 + 模式 Picker → `tap()` + `.sensoryFeedback(.selection, trigger: mode)`
  - `BacktestConfigCard.swift` → portfolio pill / 频率 Picker / 启用再平衡 Toggle / 「开始回测」CTA → `tap()` x2 + `.sensoryFeedback(.selection, ...)` x2 + `success()`
  - `BacktestHistoryList.swift` → 「对比」按钮 → `tap()`
  - `SettingsSheet.swift` → 「选择 JSON 文件」按钮 → `tap()`（系统 fileImporter / alert 自带反馈，不重复触发）
  - `ImportPreviewView` 「确认写入」按钮当前 `.disabled(true)`，等 1d Persistence 接入再加 `success()`。
- `ios/Features/Shared/MockLineChart.swift`
  - stroke 从 `color` 改成 `LinearGradient([color, color.opacity(0.45)], top → bottom)`。
  - fill 从 `color.opacity(0.12)` 改成 `LinearGradient([color.opacity(0.32), color.opacity(0)], top → bottom)`，顶亮底淡，符合 Peak watch heart-rate 那种参考的视觉。
  - 不改 pnl color 来源（`HoldingsFormatters.pnlColor`），PRD §7.1 红涨绿跌规则不动。

**未触动**：`docs/prd/`、`docs/design/`、`docs/contracts/`、`docs/algorithms/`、权限声明、Widgets target、各业务数据 / 算法。

## Contract change

无。

## Algorithm drift

无。纯 UI 层（haptic + 渲染）。

## Verification

工作目录 `ios/`：

```
$ xcodegen generate
Created project at /Users/elvischen/Developer/backtester_note/ios/BacktesterNote.xcodeproj

$ xcodebuild -project BacktesterNote.xcodeproj -scheme BacktesterNote \
    -destination 'platform=iOS Simulator,name=iPhone 17' \
    -configuration Debug build CODE_SIGNING_ALLOWED=NO
** BUILD SUCCEEDED **
```

`swift test` 不动算法层，没必要重跑（上一 commit 已绿）。Haptic 真机才能感觉到，模拟器静默；待 Elvis 真机确认手感是否合适。

代码文件行数：新增 `BNHaptics.swift` 14 行；改动文件全部仍 < 250 行，远低于 450 红线。

## Review

⏳ 等 Elvis 真机过手 + Codex review。重点看：

- haptic 接入点是否过密（用户每滑一次 segmented 就震一下，有的人觉得烦）。如果觉得过密，建议裁掉 NavCard / RadarCard 这两个 Picker 的 selection 反馈，只留 Button 上的 tap。
- 图表 gradient 强度是否合适（顶 0.32 / 底 0.0 fill；顶 1.0 / 底 0.45 stroke 是第一组取值，很容易调）。
- 「开始回测」用 `success()` 是当前没真正回测的占位映射，1f 真实接入时应改成"提交后等结果回来再 success / error"。

## Conflict

无。

## Questions for Elvis

- 真机过手后觉得哪些点过密 / 缺反馈？（具体到哪个控件）
- gradient 顶 / 底的 opacity 比例要不要调整？（建议直接给截图，我按你眼睛改数值）

## Ideas

- Phase 1h 对照线落地时，影线和实线在同一 chart 内，可能需要让影线用 dashed + 同色更淡的 gradient（比如顶 0.5 / 底 0.0），区分主次。
- 长按 / 拖拽 chart 出 tooltip 时可以加 `selection()` 步进反馈（Apple Health 风格）。等 NavCard 上对照线落了再考虑。
- `success()` notification 上"开始回测"是占位语义。Phase 1f 真实回测引擎落地后，应改成提交动作 = `tap()`，结果回调 = `success()` / 错误 = `UINotificationFeedbackGenerator().notificationOccurred(.error)`，需在 `BNHaptics` 加一个 `error()`。
- `BNHaptics` 当前是即用即丢，按性能没问题；如果未来 chart 拖拽出 tooltip 之类高频场景，可以引入 `prepare()` 路径，但不要现在做。

## Next

- [ ] Elvis 真机过手 + 给反馈（感觉过密 / 不够 / gradient 太浅 / 太重）。
- [ ] 按反馈微调或 close。
- [ ] 进入下一小单元（按 Elvis 排期：1c 写入 / 1b 视觉 QA / 其他）。
