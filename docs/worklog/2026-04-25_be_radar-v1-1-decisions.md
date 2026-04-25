# 2026-04-25 · be · radar-v1-1-decisions

**Agent**: GPT
**Role**: Dev
**Scope**: Elvis 答完 [`radar-six-dimensions-review.md`](2026-04-25_radar-six-dimensions-review.md) 两个待答 → 把决议同步到 [`docs/algorithms/radar.v1.md`](../algorithms/radar.v1.md)，让文档追上 Opus phase1b 已经落到 [`Radar.swift`](../../ios/Sources/BacktesterNoteAlgorithms/Radar.swift) 的代码（avoid"代码超前文档"漂移）。

## What changed

### Elvis 决议（2026-04-25）

| # | 事项 | 决议 |
|---|---|---|
| 1 | 三快照锚点：日历天 → 交易日 5/22 | ✅ 改 |
| 2 | 六维窗口：(a) 统一 90 天 / (b) 差异化默认 + Pro 可调 | **(b)** |

### `docs/algorithms/radar.v1.md` v1 → v1.1

- **§2 三快照模型**：`lastWeek` `today − 7 days` → **`today − 5 trading days`**；`lastMonth` `today − 30 days` → **`today − 22 trading days`**。注明配置字段 `RadarConfig.lastWeekTradingDayOffset / lastMonthTradingDayOffset`。
- **§3.6 sustainability**：从 stub 升级为完整公式 —— 4 子分 weighted（`positiveDayScore=0.25` / `positiveMonthScore=0.30` / `dispersionScore=0.25` / `improvementScore=0.20`），含 normalize lower→upper 阈值表与月度聚合规则。
- **§4 RadarConfig**：从 14 字段扩展到 22 字段：
  - 6 个 `*WindowDays`（差异化默认保留）
  - 2 个交易日锚点 offset
  - 6 个 strategyExecution 子权重
  - 2 个 excessQuality 阈值
  - 8 个 sustainability 阈值
- **§4.2 Free / Pro 边界**：Free 锁默认；**Pro 可调** 6 个窗口 + 三快照锚点 + 子分阈值。决议拒绝"六维统一 90 天"理由写进文档供 Phase 5 重审。
- **§4.3 配置变更触发**：任何 `RadarConfig` 字段变化 → `CacheService.invalidate(domain: "radar")` → 全重算。
- **Changelog**：加 v1.1 条目。

### `docs/project_state.md`

- §0 `last-updated` 行替换为本次更新者
- §2 决议簿前置追加 3 条新决议（锚点 / 窗口差异化 / sustainability 公式）
- §4 待答清单清空（雷达两个问题已答）
- §5 Next：雷达 v1.1 ✅ 加进已完成项

### `docs/algorithms/radar.v1.md` 与代码的对齐状态

| 项 | 文档 v1.1 | 代码 [`Radar.swift`](../../ios/Sources/BacktesterNoteAlgorithms/Radar.swift) | 一致？ |
|---|---|---|---|
| 三快照锚点 5/22 | ✅ | ✅ `lastWeekTradingDayOffset=5 / lastMonthTradingDayOffset=22` | ✅ |
| 6 windowDays 差异化 | ✅ 180/90/90/180/180/180 | ✅ 同 | ✅ |
| sustainability 4 子分 | ✅ 0.25/0.30/0.25/0.20 | ✅ 同 `weightedScore([...])` | ✅ |
| 8 sustainability 阈值 | ✅ | ✅ 同（`0.38/0.68/0.30/0.85/-0.20/0.80/-0.15/0.15`）| ✅ |
| 总分简单平均 | ✅ 每维 1/6 | （RadarScoring 整合层未读，[`radar-six-dimensions-review.md`](2026-04-25_radar-six-dimensions-review.md) Evening check 22:24 报告期望值 0.6833 含简单平均假设）| ✅ 待 Opus 二次确认 |

## Contract change

`docs/algorithms/radar.v1.md` v1 → v1.1。**算法契约改动**，按 [AGENTS.md §会合点](../../AGENTS.md#会合点契约驱动) 流程：必须 @ 另一方在 `## Review` 小节正式填 ✅/🔧/⚠️ 才算合并完成。

**前置事实**：
1. 决议人 = Elvis（最高权威），方向不可推翻
2. Opus 已先在 `Radar.swift` / `RadarConfig` / `RadarTests` 落实同等参数（事实层面已对齐）

**但事实对齐 ≠ 豁免流程门**。Opus 仍必须在本 worklog `## Review` 小节正式填一行 ✅/🔧/⚠️，否则跨层算法契约改动就绕过了仓库依赖的协调闸。Codex 2026-04-25 P2 review 已正确指出这点。

**本次正确状态**：⏳ 等 Opus 显式 review。下面 §Review 留空待填，未填前**不可视为合并完成**。

## Algorithm drift

无（本次只追文档不动代码）。

⚠️ **预防性 flag**（[`radar-six-dimensions-review.md` Review (GPT)](2026-04-25_radar-six-dimensions-review.md) 已写）：交易日锚点是与旧 app 的潜在口径偏移。Phase 1c 接通真数据时，Opus 必须先确认旧 [HoldingsHomeFeature.swift](file:///Users/elvischen/Developer/investment%20app/FundMVP/Views/Holdings/HoldingsHomeFeature.swift) 用日历天还是交易日。如旧 app 用日历天 → 新 app 用 5/22 交易日是受 Elvis 授权的口径变更，**已豁免红线 5**，Opus 直接按新口径走，不需要再申请。

## Review

- ⏳ **等 Opus 在此处显式填 ✅/🔧/⚠️**（不是隐式默认通过）。检查项：
  - radar.v1.md §3.6 sustainability 文档公式与 [`Radar.swift`](../../ios/Sources/BacktesterNoteAlgorithms/Radar.swift) `sustainabilityScore` 是否字面对齐
  - radar.v1.md §4 22 字段表与 `RadarConfig` 实际字段顺序 / 类型 / 默认值是否字面对齐
  - 顺带处理 ## Codex review 反馈（P2-1 sustainability calendar default bug）

## Codex review 反馈（2026-04-25）

| # | 等级 | 议题 | 决议 |
|---|---|---|---|
| 1 | P2 | `Radar.swift:188` `sustainabilityScore` 默认 `calendar: Calendar = .current` 违反 [nav.v1 §0](../algorithms/nav.v1.md) 的 Asia/Shanghai 自然日红线。出国 / CI 在非 CN 时区跑会让 `monthlyReturns` 分桶错位 → sustainability 漂 | ✅ **接受**。Opus 在下一刀里加 `BNCalendar.shanghai`（固定 `TimeZone(identifier: "Asia/Shanghai")` 的 `Calendar`），把 `sustainabilityScore` 默认改过去。Tests 加非 CN 时区下不漂的断言 |
| 2 | P2 | 本 worklog `## Contract change` 写"不需要 @ Opus 二次确认"违反 [AGENTS.md §会合点](../../AGENTS.md#会合点契约驱动) 流程 | ✅ **接受**。已修正 `## Contract change` 措辞：事实对齐 ≠ 豁免流程门，Opus 仍必须显式填 ✅/🔧/⚠️ 才算合并完成 |

## Conflict

无。

## Questions for Elvis

无（本次决议 = Elvis 答 b）。

## Ideas

- 雷达 windowDays Pro 可调上线后，Settings → 数据维护 → 雷达高级 这一屏的 UI 应该有一个"恢复默认"按钮 + 警告 banner（"改窗口会让历史快照失去可比性"）。Phase 3 落 Pro 时再说。
- sustainability 的 monthly bucket 用 `Calendar.dateComponents([.year, .month])`，月初停盘 + 月末停盘的边界容易漂。Phase 1c 接真数据时建议加一条"每桶最少 N 个 NAV 点（默认 3）"防御。本次不动。

## Next

- [ ] **Opus** review 雷达 v1.1 文档对齐（在本 worklog `## Review` 显式填 ✅/🔧/⚠️）
- [ ] **Opus** 修 P2-1：[`Radar.swift:188`](../../ios/Sources/BacktesterNoteAlgorithms/Radar.swift) `sustainabilityScore` 默认 calendar → `BNCalendar.shanghai`（或等价的固定 Asia/Shanghai TimeZone Calendar），并加非 CN 时区下不漂的单测断言
- [ ] **Opus** Phase 1c 接真数据时，按本 worklog `## Algorithm drift` 预防性 flag 处理旧 app 锚点口径核对
- [ ] **GPT** 等 Opus 1b-3 完成 → 准备做 Backend `portfolio/history` 真实化
