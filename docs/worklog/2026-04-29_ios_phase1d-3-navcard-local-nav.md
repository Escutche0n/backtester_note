# 2026-04-29 · ios · phase1d-3-navcard-local-nav

**Agent**: GPT
**Role**: Dev
**Scope**: Phase 1d-3：让 `NavCard` 消费 1d-1/1d-2 的本地手动基金日净值。无网络、无后端、无算法契约改动。

## What changed

- `ios/Services/NAV/NAVService.swift`
  - 新增账户级 `NAVService.accountSeries(for:fundNAVRecords:)`。
  - 输入：`PortfolioAccount` 的 baseline snapshot / flows + `FundDailyNAVRecord`。
  - 输出：`AccountNAVSeries`，包含账户 NAV 点、`snapshot_only`、缺净值日期、仅流水日期。
  - 官方日净值齐全的日期进入 `NAVCalculator`；baseline 无官方日净值时用 snapshot value 作为 `snapshot_only` 起点。
  - 流水日缺官方日净值时不继续硬算后续 NAV，标为 `flow_only`，避免现金流未剥离造成假曲线。
  - 多基金某日只有部分基金有 NAV 时，该日不进曲线，记录为缺净值 gap。
- `ios/Features/Holdings/Components/NavCard.swift`
  - 有真实账户时优先显示本地 NAV 曲线；没有手动 NAV 时显示「录入日净值后生成曲线」。
  - 未接入沪深300前不显示假 benchmark；header 显示「基准待接入 / 超额待算」。
  - 图例旁显示「含快照 / 缺净值 N 天 / 仅流水 N 天」。
  - range selector 继续保留 1M / 3M / 6M / 1Y / 自定义。
- `ios/Features/Shared/MockLineChart.swift`
  - 支持 `ChartPoint.index` 非连续时断线，给缺净值 gap 使用；mock series 仍连续。
- `ios/Tests/BacktesterNoteAppTests/NAVServiceTests.swift`
  - 覆盖 confirmed 官方日净值曲线、baseline snapshot fallback、流水日缺 NAV 停止假算、部分基金缺 NAV 记录 gap。

## Contract change

无。未修改 `docs/contracts/*`。

## Algorithm drift

无。`NAVCalculator` 与 `docs/algorithms/nav.v1.md` 未改；本刀只在 service 层组装 `NAVInput` 并把结果映射到 UI。

说明：这不是完整历史对账引擎。1d-3 的保守边界是：数据齐才算；现金流日缺净值就停止后续曲线，避免把未剥离现金流误当收益。

## Verification

工作目录 `ios/`：

```bash
swift test
xcodegen generate
xcodebuild build -project BacktesterNote.xcodeproj -scheme BacktesterNote \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO
xcodebuild build-for-testing -project BacktesterNote.xcodeproj -scheme BacktesterNote \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO
xcodebuild test -project BacktesterNote.xcodeproj -scheme BacktesterNote \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO
```

结果：
- `swift test`：13 个算法测试通过。
- `xcodebuild build`：通过。
- `xcodebuild build-for-testing`：通过。
- `xcodebuild test`：通过。
  - `FundNAVServiceTests`：7 tests passed。
  - `NAVServiceTests`：4 tests passed。
  - `PortfolioServiceTests`：5 tests passed。
- 手写代码文件行数均 ≤ 450。

## Review

待 review。

## Conflict

无新增。既有 scope §7 “8 graph” vs PRD §7.2 “9 指标 3×3” 仍挂 `docs/project_state.md` §4。

## Questions for Elvis

无新增。

## Ideas

- `NavCard` benchmark 目前明确显示「基准待接入」，没有用 mock 沪深300。后续 Phase 3 Pro 或本地基准 fixture 决定数据源后再接。
- 未来需要对「流水日无官方净值」提供数据维护入口的定向提示，例如跳转到对应日期补 NAV。
- 1e 接 Radar / Overview 时复用 `AccountNAVSeries`，不要重新在 View 层组装 NAV。

## Next

- [ ] Review 本 worklog 与 1d-3 代码。
- [ ] Phase 1e-1：基于本地 NAV series 接 Overview / Radar 的第一批真实指标；不可算指标继续显示 `待算`。
