# 2026-04-25 · ios · phase1b-3-holdings-mock-ui

**Agent**: GPT
**Role**: Dev
**Scope**: Elvis 临时指派 GPT 接手 iOS Phase 1b-3，落地可 build 的 Holdings mock UI：持仓首屏、mock 数据、玻璃卡片、净值曲线、雷达图、基金列表，以及 RootView ambient gradient。

## What changed

- `ios/Features/Holdings/HoldingsView.swift`
  - 新增持仓 Tab 首屏 SwiftUI 入口。
  - 页面顺序按 PRD v2 §7.2：`TotalHeader` → `OverviewPanel` → `NavCard` → `RadarCard` → `HoldingsList`。
  - `.bn-root` ambient radial gradient 落为 `BNAmbientBackground`，供 `RootTabView` 的回测占位复用。
- `ios/Features/Holdings/HoldingsMockData.swift`
  - 新增 Phase 1b mock 数据：overview、6 只基金、NAV 1M/3M/6M/1Y 曲线、雷达三快照。
  - 所有数据只用于 UI mock，不接网络、不写存储、不改算法口径。
- `ios/Features/Holdings/HoldingsFormatters.swift`
  - 新增金额、百分比、涨跌色、数字字体 helper。
- `ios/Features/Holdings/Components/`
  - 新增 `BNGlassCard`、`MockLineChart`、`MockRadarChart`、`TotalHeader`、`OverviewPanel`、`NavCard`、`RadarCard`、`HoldingCard`、`HoldingsList`。
  - 使用现有 `BNTokens`，未新增 token，未修改 `docs/design/`。
- `ios/App/RootTabView.swift`
  - 持仓 Tab 从占位 `Text` 切到 `HoldingsView()`。
  - 回测 Tab 仍保留占位，套用同一 ambient background；真正回测第一屏留给 1b-4。
- `ios/project.yml`
  - `BacktesterNote` target sources 新增 `Features`。

**未触动**：`docs/prd/`、`docs/design/`、`docs/contracts/`、`docs/algorithms/`、权限声明、Widgets target 业务代码。

## Contract change

无。

## Algorithm drift

无。全部为 UI mock 数据与绘制；没有改 NAV / XIRR / 雷达 / 回测算法实现。

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

代码文件行数已核对，新增最大文件 `HoldingsMockData.swift` 214 行；所有手写代码文件均 ≤ 450 行。

## Review

✅ 通过（Claude / Opus，2026-04-26）。Build & swift test (13/13) 绿，红线无破，文件行数全部 < 250。

核对结果：
- 页面顺序 `TotalHeader → OverviewPanel → NavCard → RadarCard → HoldingsList` 与 PRD v2 §7.2 一致。
- `BNGlassCard` / `MockLineChart` / `MockRadarChart` 用 `BNTokens` 上层，未新增 token、未触 `docs/design/`。
- 当时 `BNAmbientBackground` 为三层 ZStack（accent + benchmark radial gradient），对得上 worklog 描述（后续 1b-visual commit 才砍成纯色）。
- 严格停在 1b-3，没有提前碰 1b-4。

本次 review 顺手改：
- `RadarCard.swift:76-81`：「↑ 2.2 vs 上周」硬编码字符串改为从 `radarSnapshots` 计算 delta，避免 mock 数据漂移后脱节。
- `HoldingsList.swift:4-22`：排序 Picker 从 `selection: .constant("按市值")` 死控件改为 `@State private var sortKey`，并加 `// mock: 排序逻辑留给真实数据接入（1d）` 注释。

未在本次 commit 改、放下次：
- PRD §7.2 第 6 项「异常 banner」（失衡>10% / 待对账 / Pro 同步失败）未实现且 worklog 未列 Ideas。当前 mock `overview.unbalance = 0.143` 已超 10%，是触发示例。详见下方 `## Ideas`。
- `MockRadarChart.radarColor` 三色（accent / benchmark / foregroundPrimary）偏离 2026-04-25 决议「accent 单色 + 透明度梯度」。雷达正稿在 Phase 1e 落 token，留给 1e 一并校。

## Conflict

无。

## Questions for Elvis

无。

## Ideas

- 下一刀 1b-4 可以把 `BNAmbientBackground` 从 `HoldingsView.swift` 抽到 `ios/DesignSystem/BNBackground.swift`，让 Settings / Backtest 复用时语义更清楚。本次为了不做额外重构，先留在 Holdings 文件。（已在 1b-4 落地）
- 后续真实 chart 接入时，`MockLineChart` 应替换为 Feature 层 chart component，数据来源从 `NAVService` / `RadarService` 注入；当前不接 service。
- **PRD §7.2 第 6 项「异常 banner」** 待补：失衡 > 10% / 连续 N 天待对账 / Pro 同步失败。`HoldingsView` 留 banner 占位，触发条件可先用 mock `overview.unbalance > 0.1`。建议放到 1d Networking 接入时一起做，因为对账 / Pro 同步状态需要真实 service。
- `MockRadarChart` 三 snapshot 的颜色统一到 accent 单色 + 不同透明度梯度（与 2026-04-25 决议一致），留给 Phase 1e 雷达正稿落 token 时一并改。

## Next

- [ ] Review 本 worklog 与 SwiftUI 实现。
- [ ] 进入 Phase 1b-4：Settings sheet 壳 + 回测 Tab 第一屏。
