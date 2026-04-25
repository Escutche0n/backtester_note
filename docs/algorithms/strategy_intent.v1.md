# StrategyIntent 配置 v1

> 把旧 app 散落在 `HoldingsHomeFeature.swift` 各处的硬编码常量抽成单一外部配置。
> 实现锚点：`ios/Config/StrategyIntent.swift`
> 旧 app 来源：`/Users/elvischen/Developer/investment app/FundMVP/Views/Holdings/HoldingsHomeFeature.swift:35-51`

---

## 1. 默认值（与旧 app 一致，锁死）

```swift
struct StrategyIntent: Codable, Equatable {
    /// 单基金目标权重（用于"未指定 portfolio 时的默认仓位估算"）
    var targetWeight: Double = 0.25

    /// 周定投基础金额下限（低于则视为未达标）
    var weeklyMinimumContribution: Double = 1000

    /// 阈值再平衡触发线（绝对偏离）
    var driftTolerance: Double = 0.08

    /// 季度被动再平衡间隔（天）
    var quarterlyRebalanceIntervalDays: Int = 90

    /// 紧急赎回 / 紧急回补的有效观察窗口（天）
    var emergencyRepairWindowDays: Int = 90

    /// 视为"无意义偏离"的下限（不计入打分）
    var negligibleDeviation: Double = 0.02

    static let `default` = StrategyIntent()
}
```

---

## 2. 用途索引

| 字段 | 用在哪里 |
|---|---|
| `targetWeight` | RadarScoring `strategyExecution` 子分计算缺省目标权重 |
| `weeklyMinimumContribution` | `weeklyContributionCoverage` 计算基准 |
| `driftTolerance` | `tradingDiscipline` 评分；与 BacktestEngine 的 `rebalanceThreshold` **不是同一个** —— 后者是回测引擎参数（用户每次回测可调），前者是用户的策略意图（持仓评分用）|
| `quarterlyRebalanceIntervalDays` | `quarterlyRebalanceCoverage` 计算窗口 |
| `emergencyRepairWindowDays` | `emergencyRepairRate` 计算窗口 |
| `negligibleDeviation` | 偏离 < 此值时不计入 `structureConvergenceScore` 的扣分 |

---

## 3. 持久化

- 存 `Caches/strategy_intent.json`（不是 CoreData，避免迁移成本）
- 改动后 `CacheService.invalidate(domain: "radar")` 触发雷达重算
- 多账户共享一份（v1 不分账户）。v1.1 如有需要再拆 per-account。

---

## 4. Free / Pro 边界

| 边界 | Free | Pro |
|---|---|---|
| 改默认值 | ❌（锁定 default）| ✅（Settings → 数据维护 → 策略意图）|
| 读默认值 | ✅ | ✅ |

Free 永远拿到与旧 app 一致的雷达分数。Pro 调整后只影响该账户雷达，**不影响算法核心口径**（与 PRD §5 红线 1 一致）。

---

## 5. 单测

`ConfigTests/StrategyIntentTests/`：

- 默认值与旧 app 字面常量逐字段比对
- Codable 往返
- 改动一个字段 → `CacheService.invalidate(domain: "radar")` 被调用

---

## 6. Changelog

- v1 (2026-04-25) — 初版。
