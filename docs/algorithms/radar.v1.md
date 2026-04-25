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

**锚点定义**：
- `current` —— `anchorDate = today`
- `lastWeek` —— `anchorDate = today − 7 days`
- `lastMonth` —— `anchorDate = today − 30 days`

**计算窗口**：每个 snapshot 用 **anchor 之前的 N 天数据**（N 由维度决定，见 §3）。

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
| 输入 | NAV 序列 anchor 前 N=180 天 |
| 输出 | `[0, 1]` |
| 评估 | 滚动窗口正收益占比 + 收益与风险比 |
| 旧 app 函数 | （Phase 1a port 时定位行号）|

---

## 4. 配置外化

`ios/Config/RadarConfig.swift`（替代旧硬编码）：

```swift
struct RadarConfig: Codable {
    // 各维度计算窗口（天）
    var excessQualityWindowDays:     Int = 180
    var strategyExecutionWindowDays: Int = 90
    var tradingDisciplineWindowDays: Int = 90
    var riskControlWindowDays:       Int = 180
    var styleStabilityWindowDays:    Int = 180
    var sustainabilityWindowDays:    Int = 180

    // strategyExecution 子分权重
    var subWeightWeeklyContribution:    Double = 0.22
    var subWeightUnderweightFunding:    Double = 0.22
    var subWeightThresholdRepair:       Double = 0.18
    var subWeightStructureConvergence:  Double = 0.14
    var subWeightClassifiedAverage:     Double = 0.14
    var subWeightEmergency:             Double = 0.10

    // 关键阈值（详见 §3 各维度）
    var excessQualityFullMarkAnnualExcess: Double = 0.05
    var excessQualityZeroAnnualExcess:     Double = -0.05

    static let `default` = RadarConfig()
}
```

**默认值锁死与旧 app 一致**。Pro 用户允许在 Settings → 数据维护 改这些参数（Phase 3）；Free 永远 default。

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
