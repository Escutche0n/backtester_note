# 2026-04-25 · ios · phase1b-4-settings-backtest-shell

**Agent**: GPT
**Role**: Dev
**Scope**: Elvis 临时指派 GPT 接手 iOS Phase 1b-4，落地 Settings sheet 壳 + 回测 Tab 第一屏 mock UI。

## What changed

- `ios/Features/Settings/SettingsSheet.swift`
  - 新增设置 sheet 壳，覆盖 PRD v2 信息架构里的账户、数据维护、缓存、快捷指令 & JSON、Widgets、外观、订阅。
  - 当前全是本地 mock / 占位，不做 StoreKit、不做真实导入、不做网络。
- `ios/Features/Holdings/HoldingsView.swift`
  - 右上齿轮接入 `SettingsSheet()`，使用 `.medium/.large` detents。
- `ios/Features/Backtest/`
  - 新增 `BacktestView`、`BacktestMockData`。
  - 新增 `BacktestConfigCard`、`BacktestResultPreview`、`BacktestHistoryList`。
  - 回测 Tab 第一屏支持 `单基金 / 组合 / 定投 / 历史` segmented mock；默认落 `组合`，与设计稿 `bn-backtest.jsx` 对齐。
- `ios/App/RootTabView.swift`
  - 回测 Tab 从占位 `Text` 切到 `BacktestView()`。
- `ios/DesignSystem/BNBackground.swift`
  - 把 1b-3 的 `BNAmbientBackground` 抽到 DesignSystem，供 Holdings / Backtest 共用。
- `ios/Features/Shared/`
  - 把 1b-3 的 mock chart point / line chart 移到 shared mock UI 层，避免 Backtest 依赖 `Holdings/Components`。

**未触动**：`docs/prd/`、`docs/design/`、`docs/contracts/`、`docs/algorithms/`、权限声明、Widgets target 业务代码。

## Contract change

无。

## Algorithm drift

无。回测结果、历史列表、曲线均为 mock UI 数据；没有改回测算法、NAV、XIRR 或雷达口径。

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

代码文件行数已核对，新增最大文件 `BacktestConfigCard.swift` 231 行；所有手写代码文件均 ≤ 450 行。

## Review

✅ 通过（Claude / Opus，2026-04-26）。Build & swift test (13/13) 绿，红线无破，最大文件 `BacktestConfigCard.swift` 231 行 < 450。

核对结果：
- Settings 七组（账户 / 数据维护 / 缓存 / 快捷指令 & JSON / Widgets / 外观 / 订阅）覆盖 PRD §2 信息架构完整。当时版本严格 mock，没有提前接 `ImportService`（那是 1c `3f71dbb` 后续的事）—— 单元闸门守得很干净。
- Backtest 第一屏 segmented `单基金 / 组合 / 定投 / 历史` + `BacktestConfigCard` + `BacktestResultPreview` + `BacktestHistoryList` + 右上「新建」与 PRD §7.3 主结构一致。
- `BNAmbientBackground` 抽到 `ios/DesignSystem/BNBackground.swift`、`MockLineChart` / `ChartPoint` 抽到 `ios/Features/Shared/` —— 重组方向合理，让 Backtest 不依赖 `Holdings/Components`。

本次 review 顺手改：
- `BacktestView.swift:39-48`：「新建」按钮 action 原本是 `mode = .portfolio`，会把用户的 segmented 选择悄悄切走，且与 PRD §7.3「一键从当前持仓带入参数」无关。改为 no-op + `// TODO 1f: prefill ConfigCard from current holdings (PRD §7.3)` 注释，等 Phase 1f 真实回测落地时再实现 prefill。

未在本次 commit 改、放下次：
- `BacktestMockData.makeSeries` 与 `HoldingsMockData.makeSeries`/`SeededGenerator` 是同一算法两份拷贝。1b-4 已经把 `MockLineChart`/`ChartPoint` 抽到 Shared，下次顺手把 `makeSeries` 抽过去更彻底。详见下方 `## Ideas`。

## Conflict

无。

## Questions for Elvis

无。

## Ideas

- 下个 iOS 小单元可以做 1c ImportService，也可以先补 1b 视觉 QA（真机 / 模拟器截图对照设计稿）。按提交闸门，不和本次混做。
- Backtest mock 当前没有真实参数输入控件（日期 picker、金额 stepper、阈值 slider）；后续进入 1f Backtest 第一刀时再做真实 ViewModel 与输入验证。
- `BacktestMockData.makeSeries` 与 `HoldingsMockData.makeSeries` + `SeededGenerator` 是同一伪随机游走算法的两份拷贝。建议下次顺手把 `makeSeries(days:seed:volatility:drift:)` 与 `SeededGenerator` 抽到 `ios/Features/Shared/MockSeries.swift`，两边共用。当前 mock 阶段不阻塞，纯 DRY。

## Next

- [ ] Review 本 worklog 与 SwiftUI 实现。
- [ ] 下一小单元：按 Elvis 排期进入 1c ImportService 或先做 1b 视觉 QA。
