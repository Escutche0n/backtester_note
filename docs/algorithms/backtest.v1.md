# 回测引擎 v1

> 单基金 / 组合 / 定投 / 再平衡的口径冻结。
> 实现锚点：`ios/Algorithms/Backtest/`
> 旧 app 数字基准：`/Users/elvischen/Developer/investment app/FundMVP/Views/Backtest/BacktestEngine.swift`（1059 行）

---

## 0. 总则

- 时区 / 圆整 / tolerance 同 [nav.v1.md §0](nav.v1.md)
- 申购费 / 赎回费按用户在配置卡里设置或来自 fund 元数据，**不阉割**
- 交易日历：`tradingDates` 由 PriceService 提供（实际有净值的日期序列）；非交易日不会出现在序列里
- 申购：T 日下单 → T 日 NAV 成交（旧 app 默认）
- 赎回：T 日下单 → T 日 NAV 成交（同上；现实中通常 T+1，但旧 app 简化为 T，新版保持一致以避免漂移）

---

## 1. 数据类型

```swift
enum SIPPeriod: String { case daily, weekly, monthly, quarterly, semiannual, yearly }

enum BacktestPortfolioStrategy: String {
    case targetWeightDCA               // 按目标权重定投
    case targetWeightDCAWithRebalance  // 按目标权重定投 + 再平衡
    case incrementalRebalance          // 默认：增量补低配 + 再平衡
}

enum BacktestPeriodicRebalanceFrequency: String {
    case quarterly  // 每 3 个月
    case semiannual // 每 6 个月
    case yearly     // 每 12 个月

    var monthInterval: Int { switch self { case .quarterly: 3; case .semiannual: 6; case .yearly: 12 } }
}

enum BacktestWeekday: Int { case mon=2, tue=3, wed=4, thu=5, fri=6, sat=7, sun=1 }  // Calendar.weekday

struct BacktestExecutionRecord {
    let scheduledDate: Date           // 计划日（用户设的扣款日）
    let executionDate: Date           // 实际成交日（≥scheduled 的最近交易日）
    let amount: Double                // 总金额
    var executionNAV: Double?         // T 日 NAV
    var netInvestment: Double?        // amount / (1 + purchaseFeeRate)
    var unitsAdded: Double?           // netInvestment / NAV
}

struct BacktestMetrics {
    let totalPrincipal: Double
    let finalValue: Double
    let totalProfit: Double
    let totalReturn: Double
    let annualizedReturn: Double?
    let xirr: Double?
    let sharpeRatio: Double?
    let calmarRatio: Double?
    let maximumDrawdown: Double
    let executionCount: Int
}
```

---

## 2. 单基金回测（Port as-is）

旧 [BacktestEngine.swift:46-110](file:///Users/elvischen/Developer/investment%20app/FundMVP/Views/Backtest/BacktestEngine.swift) `buildSingleAssetResult()`：

```
state:
  units              = 0
  investedPrincipal  = 0
  executionIndex     = 0
  points             = []
  enrichedExecutions = []

for date in tradingDates:
    while executionIndex < executions.count and executions[executionIndex].executionDate == date:
        execution = executions[executionIndex]
        if let executionPrice = priceLookup(date), executionPrice > 0:
            netInvestment = execution.amount / (1 + purchaseFeeRate)
            unitsAdded    = netInvestment / executionPrice
            units            += unitsAdded
            investedPrincipal += execution.amount
            enrichedExecutions.append(execution with executionNAV/netInvestment/unitsAdded)
        else:
            enrichedExecutions.append(execution)  // unfilled — record as-is
        executionIndex += 1

    if let valuationPrice = valuationLookup(date), valuationPrice > 0, investedPrincipal > 0:
        value = units * valuationPrice
        emit point(date, value, returnRate=value/investedPrincipal - 1)
```

`points[i].value` 是市值（非 NAV），`returnRate = value/principal - 1`。

---

## 3. 组合回测

旧 [:269-437](file:///Users/elvischen/Developer/investment%20app/FundMVP/Views/Backtest/BacktestEngine.swift) `simulatePortfolioStrategy()`。**salvage_matrix 决议为 rewrite**，但口径完全保留。

### 3.1 三种策略

#### A. `targetWeightDCA` —— 按目标权重定投

每次新增资金按 `targetWeights[code]` 拆分到每只基金。**不再平衡**。

#### B. `targetWeightDCAWithRebalance` —— 按目标权重定投 + 阈值再平衡

= A + 在每个 T 日收盘后检查偏离，若任一基金 `|actualWeight - targetWeight| ≥ rebalanceThreshold` →
T+1 交易日按 T 日冻结的 `targetValueByCode` 执行再平衡（避免未来函数）。

可选：开启 `isPeriodicRebalanceEnabled`，按 `periodicRebalanceFrequency` 额外做被动再平衡。

#### C. `incrementalRebalance` —— 增量补低配（默认策略）

新增资金优先填最欠配的成分，填平后填下一名；剩余资金按目标权重投入。
框架与 B 相同，强制开启 quarterly 被动再平衡。

### 3.2 阈值再平衡的关键不变量

**snapshot 冻结**（避免未来函数）：

```
T 日收盘后检测：
    targetValueByCode = { code: totalValue × targetWeights[code] for each code }
    pendingRebalance = (triggerDate=T, executionDate=nextTradingDay(T), targetValueByCode)

T+1 日开盘前执行 performSnapshotRebalance：
    用 T+1 日的价格 + T 日冻结的 targetValueByCode 算需要卖/买的份额
```

**先卖后买**：[performSnapshotRebalance:756-816](file:///Users/elvischen/Developer/investment%20app/FundMVP/Views/Backtest/BacktestEngine.swift)
1. 对每只 `currentValue > targetValue` 的基金，卖出 `(currentValue - targetValue) / price` 份额，扣赎回费
2. 用净到手现金，按缺口大小排序补低配（先大缺口）
3. 残余现金留账户（实际不留，rebalance 完成）

### 3.3 增量补低配

[investIncrementally:614-669](file:///Users/elvischen/Developer/investment%20app/FundMVP/Views/Backtest/BacktestEngine.swift)：

```
amount: 本次新增资金
finalTargetValue = totalCurrentValue + amount
deficits = sorted_desc by (finalTargetValue * targetWeights[code] - currentValue)
remaining = amount

for d in deficits where remaining > tol:
    allocation = min(d.deficit, remaining)
    netInvestment = allocation / (1 + purchaseFeeRate[d.code])
    units = netInvestment / price[d.code]
    add lot
    remaining -= allocation

if remaining > tol:
    用 investByTargetWeight 把剩余按 targetWeights 摊到所有基金
```

---

## 4. 定投计划生成

[generateScheduledDates:949-1015](file:///Users/elvischen/Developer/investment%20app/FundMVP/Views/Backtest/BacktestEngine.swift)：

| period | 规则 |
|---|---|
| daily | 每天 |
| weekly | 每周指定 weekday；从 startDate 起首个匹配 weekday 开始 |
| monthly | 每月指定 dayOfMonth；从 startDate 起 |
| quarterly | 每 3 个月指定 dayOfMonth |
| semiannual | 每 6 个月 |
| yearly | 每 12 个月 |

**首笔规则**：若 `initialAmount > 0`，scheduledDate=startDate 入计划；否则 weekly/monthly 从 startDate 之后第一个匹配日开始（`startAfterStartDate=true`）。

**成交日**：`scheduledDate` 不是交易日时，顺延到 `tradingDates.first { $0 ≥ scheduledDate }`。

---

## 5. 卖出与赎回费分级

[sellUnits:855-896](file:///Users/elvischen/Developer/investment%20app/FundMVP/Views/Backtest/BacktestEngine.swift)：

- **FIFO**：按 lot 的 `purchaseDate` 升序消耗份额
- 每个 lot 单独算 `holdingDays = T 日 − purchaseDate`
- 在 `feeInfo.redemptionFeeTiers` 里找匹配 tier：`tier.minimumHoldingDays ≤ holdingDays < tier.maximumHoldingDays`
- 若都不匹配，取最后一档（通常 0）

---

## 6. 衍生指标

复用 [nav.v1.md §4](nav.v1.md)：CAGR / XIRR / Sharpe / Calmar / MaxDD 完全相同公式。

**XIRR 现金流构造**（与持仓 XIRR 一致以保证可对账）：

```
cashFlows = executionRecords.map { (executionDate, -amount) } + [(finalDate, +finalValue)]
```

---

## 7. 单测要求

`AlgorithmsTests/BacktestTests/`：

1. 单基金月定投 6 个月 — totalReturn / annualizedReturn / xirr 与旧 app 数字一致
2. 单基金含赎回费分级 — 不同 holdingDays 触发不同档
3. 组合 targetWeightDCA — 验证按权重拆分
4. 组合 targetWeightDCAWithRebalance — 验证 snapshot 冻结、T+1 执行
5. 组合 incrementalRebalance — 验证缺口排序
6. 周定投 startDate 不是匹配 weekday — 验证首日顺延
7. scheduledDate 落在非交易日 — 验证 executionDate 顺延

---

## 8. Synthetic fixtures

```
docs/algorithms/golden_fixtures/synthetic/backtest_*/
├── single_dca_6m/
├── single_with_redemption_fee/
├── portfolio_target_weight/
├── portfolio_threshold_rebalance/
├── portfolio_incremental/
├── weekly_dca_anchor_off_weekday/
└── monthly_dca_dom_in_holiday/
```

---

## 9. Changelog

- v1 (2026-04-25) — 初版。从旧 [BacktestEngine.swift](file:///Users/elvischen/Developer/investment%20app/FundMVP/Views/Backtest/BacktestEngine.swift) port 公式，rewrite API（按 salvage_matrix）。
