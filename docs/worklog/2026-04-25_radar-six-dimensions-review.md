# 2026-04-25 · 雷达六维审查 · 工作笔记

> 非 commit log，纯讨论记录。Elvis 的问题 + 我的分析，供后续决策参考。

---

## 背景

Elvis 问：当前六维窗口期是否合理。

---

## Elvis 的两个判断

### 判断 1：三快照锚点用交易日，而非日历天数

当前 radar.v1.md 定义：
- `lastWeek` → today − 7 days（日历）
- `lastMonth` → today − 30 days（日历）

**Elvis 倾向改为：**
- `lastWeek` → today − 5 trading days
- `lastMonth` → today − 22 trading days

**分析：** 合理。国内 A 股每年约 240-250 个交易日，5 ≈ 一周、22 ≈ 一月。这个锚点决定了"截取哪段历史数据来算这一期快照"，用交易日比日历更稳定——不会因为五一/端午/国庆长假导致"上周"截了 9-12 个日历天。

**影响范围：**
- `StrategyRadarSnapshot.anchorDate` 语义从"具体日期"改为"往前推 N 个交易日"
- `BNCalendar` 需要新增 `往前推N个交易日` 方法（当前只有日历偏移）
- 文档 `radar.v1.md` §2 需要更新

---

### 判断 2：六维窗口期统一为 90 天

当前 radar.v1.md §3：

| 维度 | 当前窗口 |
|---|---|
| excessQuality | 180 天 |
| strategyExecution | 90 天 |
| tradingDiscipline | 90 天 |
| riskControl | 180 天 |
| styleStability | 180 天 |
| sustainability | 180 天 |

**Elvis 倾向：统一 90 天（所有维度）。**

**分析：**
- **支持统一的理由**：用户理解成本低、六个维度的评估周期一致、不需要在 UI 上解释"此维看半年、此维看三个月"
- **反对 180 天的理由**：新账户前 90 天也能跑满所有维度，不需要等半年才有"完整雷达"

**对各维度的影响（潜在问题）：**

| 维度 | 改为 90 天后的风险 |
|---|---|
| excessQuality | 超额年化需要年化（annualize = 收益 / (90/365)），样本更少波动更大 |
| riskControl | 最大回撤/波动率在 90 天内可能比 180 天表现更好（运气成分更多），区分度下降 |
| styleStability | 风格漂移 90 天内观测窗口短，偶发调仓会被放大 |
| sustainability | 滚动正收益窗口用 90 天基数，结果更不稳定 |

**建议：** 可以统一为 90 天，但需要接受上述权衡。如果担心区分度，可以在 `RadarConfig` 里把各维度窗口做可配置参数（Phase 2+），而不是硬编码。

---

## 决策待确认

| # | 事项 | 待确认人 | 状态 |
|---|---|---|---|
| 1 | 三快照锚点改为 5/22 交易日 | Elvis | ⏳ |
| 2 | 六维窗口统一 90 天 | Elvis | ⏳ |
| 3 | BNCalendar 是否需要 `往前推N交易日` | Opus（实现层）| 待1确认后处理 |
| 4 | sustainability 公式补完（P0 阻塞）| GPT port 时补 | ⏳ |

---

## Evening check（22:24）

代码今天已推进，Swift 实现在多处超前文档：

### ✅ 代码里已改好

**1. 交易日锚点（已实现）**
```swift
// RadarConfig.swift
lastWeekTradingDayOffset: Int = 5    // ✅
lastMonthTradingDayOffset: Int = 22  // ✅
```
单测 `snapshotAnchorOffsets()` 也已加：
```swift
#expect(config.lastWeekTradingDayOffset == 5)
#expect(config.lastMonthTradingDayOffset == 22)
```

**2. sustainability 公式（已补完）**
`RadarScoring.sustainabilityScore()` 完整实现了四个子分：
- 正收益天数占比（权重 0.25）
- 正收益月数占比（权重 0.30）
- 收益分散度（top5占比 → 0.8 − topFiveShare，权重 0.25）
- 与上期正收益天数比值改善（权重 0.20）
- 阈值配置全部外化到 RadarConfig

单测也覆盖了（期望值 0.6833）。

### ⚠️ 文档与代码不同步

| 项 | 代码默认值 | 文档 §3 写的 |
|---|---|---|
| excessQuality 窗口 | 180 天 | 180 天 ✅ |
| strategyExecution 窗口 | 90 天 | 90 天 ✅ |
| tradingDiscipline 窗口 | 90 天 | 90 天 ✅ |
| riskControl 窗口 | 180 天 | 180 天 |
| styleStability 窗口 | 180 天 | 180 天 |
| sustainability 窗口 | 180 天 | 180 天 |
| lastWeek 锚点 | 5 交易日 | today − 7 days ❌ |
| lastMonth 锚点 | 22 交易日 | today − 30 days ❌ |
| sustainability 公式 | 完整实现 | stub ❌ |
| sustainability 阈值 | 8 个配置字段 | 未写 ❌ |

**窗口期问题待拍板**：代码仍用 180/90/180，Elvis 倾向统一 90 天，两边都还没动。

### 待动项清单

- [ ] **Elvis 拍板**：六维窗口统一 90 天（还是保留 180/90/180）
- [ ] **更新 radar.v1.md**：
  - §2 三快照锚点改为交易日
  - §3.6 sustainability 补完整公式
  - §4 RadarConfig 字段同步（加交易日偏移 + 8个sustainability阈值）
  - Changelog 加今日变更记录
- [ ] **BNCalendar** 目前没有 `往前推N交易日` 方法（anchor交易日偏移在 RadarService 层实现，日历天偏移走 BNCalendar）

---

涉及文件（不改，仅记录）

- `docs/algorithms/radar.v1.md` §2（三快照定义）、§3（各维窗口）
- `ios/Sources/BacktesterNoteAlgorithms/Radar.swift`（anchorDate 语义）
- `ios/Sources/BacktesterNoteAlgorithms/BNCalendar.swift`（工具方法）

---

## Review (GPT, 2026-04-25)

### 判断 1（5/22 交易日锚点）—— ✅ 赞成改

理由同 Opus 分析：日历天容易在长假后污染窗口（黄金周后"上周"可能截到 12 个日历日），交易日稳定。
**额外影响**（Opus 没列出）：
- `radar.v1.md` §2 三快照定义改后，**所有 synthetic fixture 的 expected 值要重算**（如果有用 lastWeek/lastMonth 的）。当前 fixtures 还没大规模出，时机正合适。
- 旧 app 用什么口径需要确认。如旧 app 也用日历天，这是与旧 app 的口径偏移（受红线 5 约束）。Opus 在落实时**必须**先看旧 [HoldingsHomeFeature.swift](file:///Users/elvischen/Developer/investment%20app/FundMVP/Views/Holdings/HoldingsHomeFeature.swift) 怎么算锚点 → 写进 worklog `## Algorithm drift`。

### 判断 2（六维统一 90 天）—— ⚠️ 反对统一硬切 / ✅ 赞成"默认差异 + 进 RadarConfig 可调"

我倾向**保留默认窗口差异**（excessQuality/riskControl/styleStability/sustainability = 180，strategyExecution/tradingDiscipline = 90），理由：
- 长期投资工具，180 天给慢变量（风险 / 风格 / 持续性）足够样本
- 90 天对短变量（执行 / 纪律）足够，且与 strategyExecution 内的"周定投达标率"自然吻合
- 用户理解成本：UI 上"近 N 天表现"用脚注解释，比把所有维度都"瘦"成 90 天但暗中失精度更诚实

**折中方案**（推荐）：
1. 默认值保持当前（180/90 混合）写进 [`radar.v1.md` §4 RadarConfig.default](../algorithms/radar.v1.md)
2. 把六个 `*WindowDays` 字段暴露在 RadarConfig，**Pro 用户可在 Settings → 数据维护 改窗口**（与 §4 已有边界一致）
3. Free 用户固定默认；改窗口当作 Pro 的"高级诊断"卖点之一

如果 Elvis 仍想"先简化体验，统一 90 天"也可，我接受——前提是写进决议簿，并在 PRD §3.4 文案明示"六维统一 90 天观察窗"，避免 UI 逻辑漂移。

### sustainability 公式补完（判断 4）

P0 阻塞，等 GPT port 时连同其余 5 维详细公式补 [`radar.v1.md` v1.1](../algorithms/radar.v1.md)。无异议。

### 待 Elvis 拍板（汇总）

| # | 事项 | GPT 建议 |
|---|---|---|
| 1 | 三快照锚点 5/22 交易日 | ✅ 改（先确认旧 app 口径） |
| 2 | 六维窗口统一 90 天 vs 差异化 | 倾向**差异化默认 + RadarConfig Pro 可调**；如 Elvis 仍想统一，写进决议簿即可 |
