# 趋势雷达 v1

> 六维投资复盘评分的口径冻结。
> 实现锚点：`ios/Algorithms/Radar/RadarScoring.swift` + `ios/Config/RadarConfig.swift`
> 旧 app 数字基准：`/Users/elvischen/Developer/investment app/FundMVP/Views/Holdings/HoldingsHomeFeature.swift:3-95` + `:1458-1799`

---

## ⚠️ 重要的口径澄清（PRD v2 §3.4 修正）

PRD v2 §3.4 写"六维权重 0.22/0.22/0.18/0.14/0.14/0.10 来自旧 app `:84-95`" —— **错误**。

**真实口径**（[HoldingsHomeFeature.swift:20-24](file:///Users/elvischen/Developer/investment%20app/FundMVP/Views/Holdings/HoldingsHomeFeature.swift)）：

```swift
var overallScore: Double {
    let values = StrategyRadarDimension.allCases.compactMap { scores[$0] }
    return values.reduce(0, +) / Double(values.count)
}
```

**六维总分 = 简单平均**（每维权重 = 1/6 ≈ 0.1667）。

那组 `0.22/0.22/0.18/0.14/0.14/0.10` 是**单一维度内部** `策略执行 (strategyAlignmentScore)` 的子打分权重（[:84-95](file:///Users/elvischen/Developer/investment%20app/FundMVP/Views/Holdings/HoldingsHomeFeature.swift)）。

**v1 决议（Elvis 2026-04-25 确认）**：保持简单平均（每维 1/6 ≈ 0.1667）。

**为什么不加权**（决策记录，Phase 5 重审前不再讨论）：
- 任何具体加权都需要解释"为什么 A 维比 B 维重要"，当前**没有数据回答**
- 简单平均与旧 app 一致，零口径漂移
- 旧 app 已跑一段时间形成用户直觉（Elvis 自己），改了要重新校准
- 简单平均最诚实——告诉用户"六维是平等观察口"，不撒谎

**未来路径（不在 Phase 1）**：
- v2：`StrategyIntent.radarWeights` 作为 Pro 用户自调项
- v3：积累 6+ 月真实账户后，与"下个月超额收益"做回归找经验权重

---

## 1. 六维定义

```swift
enum StrategyRadarDimension: String, CaseIterable {
    case excessQuality      = "超额质量"   // 账户 vs 沪深300 超额收益的稳定性
    case strategyExecution  = "策略执行"   // 周定投/再平衡/补低配等动作完成度
    case tradingDiscipline  = "交易纪律"   // 频繁交易/追涨杀跌反向扣分
    case riskControl        = "风险控制"   // 回撤/波动率/集中度
    case styleStability     = "风格稳定"   // 组合风格漂移
    case sustainability     = "收益质量"   // 绝对收益（滚动窗口）
}
```

每维分数 ∈ `[0, 100]`（旧 app 内部用 `[0, 1]`，UI 展示乘 100）。
总分 = 六维简单平均。

---

## 2. 三快照模型

```swift
struct StrategyRadarSnapshot {
    let label: String          // "current" / "lastWeek" / "lastMonth"
    let anchorDate: Date       // 计算锚点
    let scores: [StrategyRadarDimension: Double]   // 每维 0..1
}
```

**锚点定义（Elvis 2026-04-25 ✅ 改交易日）**：
- `current` —— `anchorDate = today`
- `lastWeek` —— `anchorDate = today − 5 trading days`（实现锚点 `RadarConfig.lastWeekTradingDayOffset = 5`）
- `lastMonth` —— `anchorDate = today − 22 trading days`（实现锚点 `RadarConfig.lastMonthTradingDayOffset = 22`）

**为什么交易日**：A 股每年约 240–250 个交易日，5 ≈ 一周、22 ≈ 一月。日历天容易在长假后污染窗口（黄金周后"上周"可能截到 12 个日历日），交易日更稳定。

**计算窗口**：每个 snapshot 用 **anchor 之前的 N 天数据**（N 由维度决定，见 §3 / §4）。

UI 叠加显示：bottom→top = lastMonth → lastWeek → current（[bn-holdings.jsx](../design/project/lib/bn-holdings.jsx) `RadarCard`）。

---

## 3. 六维打分函数（v1 stub，详见旧 app）

每维打分函数旧 app 散落在 `HoldingsHomeFeature.swift:1458-1799`。本 v1 文档先冻结**输入 + 输出 + 关键阈值**，详细公式留给 Phase 1a port 时**逐函数 port + unit test 数字对齐旧 app**。

### 3.1 excessQuality（超额质量）

| 项 | 值 |
|---|---|
| 输入 | 账户 NAV 序列、基准（沪深300）NAV 序列、anchor 前 N=180 天 |
| 输出 | `[0, 1]` |
| 关键阈值（旧 app）| 超额年化 ≥ 5% → 满分；≤ -5% → 0；中间线性插值 |
| 旧 app 函数 | `scoreExcessQuality(...)` `:~1458` |

### 3.2 strategyExecution（策略执行）

= `StrategyIntentContext.strategyAlignmentScore`，用六个子分加权（这是 0.22/0.22/0.18/0.14/0.14/0.10 真正的归宿）：

```swift
strategyAlignmentScore = clamp([
    weeklyContributionCoverage      * 0.22,
    underweightFundingHitRate       * 0.22,
    thresholdRepairRate             * 0.18,
    structureConvergenceScore       * 0.14,
    classifiedAverage               * 0.14,
    emergencyScore                  * 0.10,
].sum, 0, 1)
```

子分定义：
- `weeklyContributionCoverage` — 周定投达标率 = 完成周 / 应有周
- `underweightFundingHitRate` — 出现低配时优先补低配的命中率
- `thresholdRepairRate` — 触发再平衡阈值后实际再平衡的比率
- `structureConvergenceScore` — 实际权重与目标权重的整体收敛度
- `classifiedAverage` — 已分类交易事件的平均评分
- `emergencyScore` — 紧急赎回 / 紧急回补的妥善程度

每个子分公式见 §6 fixture derivation。

### 3.3 tradingDiscipline（交易纪律）

| 项 | 值 |
|---|---|
| 输入 | 流水序列、价格序列、anchor 前 N=90 天 |
| 输出 | `[0, 1]` |
| 旧 app 函数 | `scoreTradingDiscipline(...)` `:~1610` |
| 扣分项 | 短期来回交易 / 价格暴涨后买入 / 价格暴跌后卖出 |

### 3.4 riskControl（风险控制）

| 项 | 值 |
|---|---|
| 输入 | NAV 序列 anchor 前 N=180 天 |
| 输出 | `[0, 1]` |
| 评估 | 最大回撤 + 年化波动率 + 集中度 |
| 旧 app 函数 | `scoreRiskControl(...)` `:~1700` |

### 3.5 styleStability（风格稳定）

| 项 | 值 |
|---|---|
| 输入 | 历史持仓权重序列 anchor 前 N=180 天 |
| 输出 | `[0, 1]` |
| 评估 | 权重分布的 Hellinger 距离平均 |
| 旧 app 函数 | `scoreStyleStability(...)` `:~1750` |

### 3.6 sustainability（收益质量）

| 项 | 值 |
|---|---|
| 输入 | 当期 NAV 序列 anchor 前 N=180 天 + 上一期 NAV 序列（用于改善度子分）|
| 输出 | `[0, 1]` |
| 实现 | [`RadarScoring.sustainabilityScore()`](../../ios/Sources/BacktesterNoteAlgorithms/Radar.swift) |

**时区策略（Elvis 2026-04-25 决议）**：sustainability 月度分桶**强制** Asia/Shanghai，[`sustainabilityScore`](../../ios/Sources/BacktesterNoteAlgorithms/Radar.swift) **不暴露 calendar 参数**。理由：产品定位是国内基金复盘工具，按非 CN 时区看盘没有合法语义；不暴露 calendar 参数 = 在 API 表面就堵死"传错时区"漂移路径。这是 [`nav.v1.md` §0](nav.v1.md) "全 App 统一 Asia/Shanghai 自然日"红线在 sustainability 上的兑现点。

**完整公式**（已实现，与旧 app 数字对齐留 Phase 1c 真实数据接通时补 `## Algorithm drift` 校验）：

```
sustainabilityScore = weightedSum([
    (positiveDayScore,   0.25),
    (positiveMonthScore, 0.30),
    (dispersionScore,    0.25),
    (improvementScore,   0.20),
])
```

四个子分：

| 子分 | 输入 | 公式 | 阈值（normalize lower → upper）|
|---|---|---|---|
| `positiveDayScore` | 当期日收益序列 | `count(daily > 0) / total` | `0.38 → 0.68` |
| `positiveMonthScore` | 当期按月聚合的月收益 | `count(monthly > 0) / total` | `0.30 → 0.85` |
| `dispersionScore` | 当期所有正收益日 | `0.8 − topFiveShare`，`topFiveShare = sum(top5正收益) / sum(all正收益)` | `-0.20 → 0.80` |
| `improvementScore` | 当期 vs 上期 positiveDayRatio | `currentRatio − previousRatio`（上期为空则取 0 改善）| `-0.15 → 0.15` |

**normalize 规则**：`(value − lower) / (upper − lower)`，超界 clamp 到 `[0,1]`；若 `upper ≤ lower` 返回 `0.5`。

**月度聚合**：按 `Calendar.dateComponents([.year, .month])` 分桶，每桶取首末两个 NAV 算 `end/start − 1`，桶内首末必须 NAV > 0。

**所有阈值外化到 [`RadarConfig`](../../ios/Sources/BacktesterNoteAlgorithms/Radar.swift) 8 个字段**（见 §4），Pro 用户可调。

---

## 4. 配置外化

实现位置：[`ios/Sources/BacktesterNoteAlgorithms/Radar.swift`](../../ios/Sources/BacktesterNoteAlgorithms/Radar.swift) `public struct RadarConfig`。

### 4.1 字段（实际默认值与代码一致）

```swift
public struct RadarConfig: Codable, Equatable, Sendable {
    // ── 各维度计算窗口（天）── Elvis 2026-04-25 决议 (b)：差异化默认
    var excessQualityWindowDays:     Int = 180
    var strategyExecutionWindowDays: Int = 90
    var tradingDisciplineWindowDays: Int = 90
    var riskControlWindowDays:       Int = 180
    var styleStabilityWindowDays:    Int = 180
    var sustainabilityWindowDays:    Int = 180

    // ── 三快照交易日锚点 ── Elvis 2026-04-25 决议
    var lastWeekTradingDayOffset:  Int = 5
    var lastMonthTradingDayOffset: Int = 22

    // ── strategyExecution 子分权重（PRD §3.4 strategyExecution 维度内部）──
    var subWeightWeeklyContribution:    Double = 0.22
    var subWeightUnderweightFunding:    Double = 0.22
    var subWeightThresholdRepair:       Double = 0.18
    var subWeightStructureConvergence:  Double = 0.14
    var subWeightClassifiedAverage:     Double = 0.14
    var subWeightEmergency:             Double = 0.10

    // ── excessQuality 阈值 ──
    var excessQualityFullMarkAnnualExcess: Double = 0.05
    var excessQualityZeroAnnualExcess:     Double = -0.05

    // ── sustainability 4 个子分 × 上下界 = 8 个阈值 ──
    var sustainabilityPositiveDayLower:    Double = 0.38
    var sustainabilityPositiveDayUpper:    Double = 0.68
    var sustainabilityPositiveMonthLower:  Double = 0.30
    var sustainabilityPositiveMonthUpper:  Double = 0.85
    var sustainabilityDispersionLower:     Double = -0.20
    var sustainabilityDispersionUpper:     Double = 0.80
    var sustainabilityImprovementLower:    Double = -0.15
    var sustainabilityImprovementUpper:    Double = 0.15

    public static let `default` = RadarConfig()
}
```

### 4.2 Free / Pro 边界（Elvis 2026-04-25 ✅ 决议 (b)）

| 用户 | 6 个 `*WindowDays` | 三快照交易日锚点 | 子分权重 / 阈值 |
|---|---|---|---|
| Free | 锁定默认（差异化 180/90 混合）| 锁定默认（5/22）| 锁定默认 |
| Pro | **可调**（Settings → 数据维护 → 雷达高级）| **可调** | **可调** |

**为什么不统一 90 天**（决策记录，Phase 5 重审前不再讨论）：
- 长期投资工具，180 天给慢变量（风险 / 风格 / 持续性）足够样本量
- 90 天对短变量（执行 / 纪律）足够，与 strategyExecution 内的"周定投达标率"自然吻合
- "六维统一 90 天"看似简化体验，实际是把所有维度都"瘦"成 90 天但暗中失精度，比"差异化 + 脚注解释"更不诚实
- Pro 用户可调窗口当作"高级诊断"卖点之一，与 PRD §4 Free/Pro 边界一致

### 4.3 配置变更触发

任何 `RadarConfig` 字段变化 → `CacheService.invalidate(domain: "radar")` → 雷达全重算。三快照单独缓存（key 含 `lastWeekTradingDayOffset` / `lastMonthTradingDayOffset`），改其一只重算对应快照。

---

## 5. 单测要求

`AlgorithmsTests/RadarTests/`：

1. **每维独立测**：用合成数据让某维分数 = 0、0.5、1 各一例
2. **总分 = 简单平均**：mock 六维分 = `[0.6, 0.6, 0.6, 0.6, 0.6, 0.6]` → overallScore = 0.6（不是任何加权值）
3. **三快照独立**：current / lastWeek / lastMonth 互不相关
4. **`strategyAlignmentScore` 子分加权**：mock 子分 = `[1, 0, 0, 0, 0, 0]` → 0.22；`[0, 0, 0, 0, 0, 1]` → 0.10
5. **窗口边界**：anchor 前刚好 N 天 / N+1 天 → 数据被正确切片

---

## 6. Synthetic fixture

`docs/algorithms/golden_fixtures/synthetic/radar_*/`：

| 场景 | 期望 |
|---|---|
| `radar_perfect_account/` | 6 维都拿满分；overallScore = 1 |
| `radar_zero_account/` | 6 维都拿 0；overallScore = 0 |
| `radar_realistic_account/` | 模拟一个普通账户（混合分），手算每维 + 平均 + 写 derivation.md |
| `radar_strategy_execution_subscore/` | 验证 0.22/0.22/0.18/0.14/0.14/0.10 子权重 |

---

## 7. Changelog

- v1 (2026-04-25) — 初版。修正 PRD v2 §3.4 的权重错置；冻结六维定义、三快照模型、配置外化。详细打分函数公式留 Phase 1a port 时与旧 app 单测对齐补完 v1.1。
- v1 (2026-04-25) — 雷达总分沿用简单平均；加权方案推到 v2/v3。
- v1.1 (2026-04-25) — Elvis 雷达窗口 / 锚点决议落地（与 Opus phase1b 代码同步）：
  - §2 三快照锚点：日历天（7/30）→ **交易日 5/22**（`lastWeekTradingDayOffset` / `lastMonthTradingDayOffset`）
  - §3.6 sustainability：从 stub → 完整公式（4 子分 + 阈值，与 [`Radar.swift`](../../ios/Sources/BacktesterNoteAlgorithms/Radar.swift) 一致）
  - §4 RadarConfig：扩展到 22 字段（6 windowDays + 2 交易日锚点 + 6 strategyExecution 子权重 + 2 excessQuality 阈值 + 8 sustainability 阈值）
  - §4.2 Free/Pro 边界落决议 (b)：差异化默认 + Pro 可调；明确拒绝"六维统一 90 天"
  - 实现锚点全部指向 `ios/Sources/BacktesterNoteAlgorithms/Radar.swift`
- v1.2 (2026-04-25) — Codex P2-1 review + Elvis 决议：sustainability 月度分桶强制 Asia/Shanghai：
  - §3.6 加"时区策略"段落，明示 `sustainabilityScore` **不暴露 calendar 参数**
  - 实现层：`monthlyReturns` 删除 calendar 参数，硬编码 `BNCalendar.calendar`
