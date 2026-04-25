# NAV 算法 v1

> 账户净值（NAV）+ 衍生指标的数字级口径冻结。
> 实现锚点：`ios/Algorithms/NAV.swift` + `ios/Algorithms/Metrics.swift` + `ios/Algorithms/XIRR.swift`
> 旧 app 数字基准：`/Users/elvischen/Developer/investment app/FundMVP/Views/Holdings/HoldingsNAVCalculator.swift`
>
> **本文与旧 app 实现产生数字差异即视为漂移**（[AGENTS.md 红线 5](../../AGENTS.md)）。

---

## 0. 总则

- 时区：`Asia/Shanghai`，所有日期对齐为自然日 startOfDay
- 数值精度：`navPrecision = 4`（小数四位）；`navZeroTolerance = 0.0001`
- 圆整规则：`roundedNAVValue(x) = round(x * 10^4) / 10^4`，使用 banker's rounding 与否旧 app 用 Swift 默认 `.rounded()`（schoolbook），新版**保持 schoolbook**
- 非有限值（NaN / inf）输入按"跳过该点 + 状态切到 segment_reset"处理，不抛错
- 公式中所有 `roundedNAVValue(...)` 调用 = 强制四位精度，**每一步都要圆整**，否则会与旧 app 出现位级漂移

---

## 1. 输入

```swift
struct NAVInput {
    /// 账户每日总市值序列（升序），由 holdings × NAV 聚合而来
    let marketValueSeries: [(date: String, value: Double)]
    /// 当日外部现金流总额（账户级），按 dateKey 索引
    /// 申购/转入 → 正；赎回/转出 → 负；分红再投不计入；现金分红计入负值（账户外流出）
    let cashFlowByDate: [String: Double]
    /// 当日所有外部现金流明细（用于 ledger 调试）
    let cashFlowEventsByDate: [String: [Double]]
}
```

`dateKey` 格式：`yyyy-MM-dd`，UTC 无关，按 `Asia/Shanghai` 自然日。

---

## 2. TWRR 账户 NAV 曲线

### 2.1 算法（与旧 [HoldingsNAVCalculator.swift:4-62](file:///Users/elvischen/Developer/investment%20app/FundMVP/Views/Holdings/HoldingsNAVCalculator.swift) 数字一致）

伪码：

```
state:
  nav            = 1.0
  shares         = nil           // Double?
  prevEndingValue = nil          // Double?
  points         = []

for each (dateStr, rawValue) in marketValueSeries (升序):
    date         = parse(dateStr)  if fail → skip
    endingValue  = roundedNAV(max(rawValue, 0))
    cashFlow     = roundedNAV(cashFlowByDate[dateStr] ?? 0)

    // ── 段起点：首次出现持仓 ──
    if shares == nil OR shares ≤ tol OR prevEndingValue == nil OR prevEndingValue ≤ tol:
        if endingValue > tol:
            nav             = 1.0
            shares          = roundedNAV(endingValue / 1.0)   // = endingValue
            prevEndingValue = endingValue
            emit point(date, nav=1.0, returnRate=0)
        // 否则跳过该日
        continue

    // ── 段内：先剥离当日外部现金流，得到 pre-flow 账户表现 ──
    prevValueAfterFlow = prevEndingValue
    snapshotTotalValue = roundedNAV(endingValue - cashFlow)

    if prevValueAfterFlow ≤ tol:
        prevEndingValue = endingValue
        continue

    dailyReturn = roundedNAV((snapshotTotalValue - prevValueAfterFlow) / prevValueAfterFlow)

    if abs(dailyReturn) > 0.5:
        log "extreme_daily_return"   // 不阻断、仅警告

    nav = roundedNAV(nav * (1 + dailyReturn))
    if nav ≤ 0 OR nav not finite:
        prevEndingValue = endingValue
        continue

    // ── 现金流转化为虚拟份额变动 ──
    if abs(cashFlow) ≥ tol:
        deltaShares = roundedNAV(cashFlow / nav)
        shares      = roundedNAV(shares + deltaShares)

    prevEndingValue = endingValue
    emit point(date, nav=nav, returnRate=nav - 1)
```

### 2.2 关键不变量（写到单测里）

| 不变量 | 说明 |
|---|---|
| 段起点的 NAV 必为 `1.0` | 形成"自起算日 = 0%"的 returnRate 起点 |
| 段内 NAV 不受外部现金流当日抖动影响 | 因为 `snapshotTotalValue = endingValue - cashFlow`，已剥离 |
| 现金流改变 `shares`，不改变 NAV | 即 `shares` 永远等于 `endingValue / nav`（在四位精度下）|
| 段落条件 | 任何 `shares`/`prevValueAfterFlow` ≤ tol 触发段重置；下一非零 endingValue 重新起段 |

### 2.3 与可信度状态机的关系（PRD §3.2）

NAV 算法本身**不打 tag**。tag 由上游 `NAVService` 根据如下来源决定：

| 状态 | 来源 |
|---|---|
| `confirmed` | 该日 `marketValueSeries` 来自基金官方净值 + 该日 cashFlow 完全由确认的流水构成 |
| `pending_reconcile` | marketValueSeries 来自官方但流水缺失（如：未导入对应 buy/sell）|
| `intraday_estimate` | 来自 PriceService.fetchRealtime 的盘中估值 |
| `snapshot_only` | 来自用户录入的 holding snapshot（无官方支撑）|
| `flow_only` | 仅有流水、无 marketValueSeries → **不进入曲线**，列表展示 |

**铁律**：`intraday_estimate` 永不写入历史 `confirmed` 序列；它是 ViewModel 层在曲线尾部 append 的临时点。

---

## 3. 账户分段 Ledger（调试 / 对账用）

旧 app `:171-335` `buildPortfolioNAVLedgerRows()` —— 输出每日的：

```swift
struct PortfolioNAVLedgerRow {
    let date: Date
    let dateKey: String
    let endingMarketValue: Double
    let externalCashFlow: Double
    let previousShares: Double?
    let preFlowMarketValue: Double?
    let preFlowNAV: Double?
    let finalShares: Double?
    let finalNAV: Double?
    let status: String  // "ok_no_cash_flow" | "ok_with_cash_flow" | "segment_start"
                        // | "segment_reset_invalid_pre_flow_market_value"
                        // | "segment_reset_invalid_pre_flow_nav"
                        // | "segment_reset_invalid_final_nav"
                        // | "segment_end_zero_position"
                        // | "skip_cash_flow_without_position" | "skip_empty"
}
```

**算法与 §2 同**，但额外保留 ledger 行供 Settings → 数据维护页查看。详见旧实现行 171-335，逐行 port。

---

## 4. 衍生指标

### 4.1 CAGR

```swift
func cagr(startValue: Double, endValue: Double, startDate: Date, endDate: Date) -> Double? {
    guard startValue > 0, endValue > 0, startDate < endDate else { return nil }
    let dayCount = Calendar.gregorian.days(from: startDate.startOfDay, to: endDate.startOfDay)
    guard dayCount > 0 else { return nil }
    return pow(endValue / startValue, 365.0 / Double(dayCount)) - 1
}
```

注意：分母 `Double(dayCount)`，分子 `365`（不是 365.25），与旧 [:337-348](file:///Users/elvischen/Developer/investment%20app/FundMVP/Views/Holdings/HoldingsNAVCalculator.swift) 一致。

### 4.2 XIRR（Newton-Raphson）

旧 [:350-393](file:///Users/elvischen/Developer/investment%20app/FundMVP/Views/Holdings/HoldingsNAVCalculator.swift) 与旧 [BacktestEngine.swift:1025-1058](file:///Users/elvischen/Developer/investment%20app/FundMVP/Views/Backtest/BacktestEngine.swift) 是**两个略有差异的实现**：

| 差异点 | HoldingsNAVCalculator | BacktestEngine |
|---|---|---|
| 时间归一化 | `years = timeIntervalSince(baseDate) / 31_556_926` | `years = (timeInterval / 86400) / 365.0` |
| derivative 中 years==0 跳过 | ✅ | ✅ |

`31_556_926` 秒 ≈ 365.2422 天 ≈ 一回归年；`86400 * 365` 秒 = 365.0 天。

**v1 提案**：两边都用 `365.0` 天分母（即 BacktestEngine 的版本）。理由：账户 NAV 与回测产出的 XIRR 必须可对账，统一分母。**这是与旧 HoldingsNAVCalculator 的 1 处口径偏移**，需要 Elvis 在 worklog 里 ✅ 后才能进入实现。

伪码（统一版）：

```
xirr(cashFlows: [(date, amount)]) -> Double?:
    if cashFlows.count < 2: return nil
    sorted = cashFlows.sortedByDate
    base   = sorted[0].date

    func npv(rate):
        Σ flow.amount / (1 + rate)^( (flow.date - base) / 86400 / 365.0 )

    func dnpv(rate):
        Σ -years * flow.amount / (1 + rate)^(years + 1)
        where years = (flow.date - base) / 86400 / 365.0; skip years==0

    rate = 0.12
    for i in 0..<40:
        v = npv(rate)
        s = dnpv(rate)
        if abs(s) ≤ 1e-6: break
        next = rate - v/s
        if abs(next - rate) < 1e-7: return next (if finite)
        rate = next
    return rate (if finite) else nil
```

**XIRR 起点（PRD §3.3）**：现金流序列 = 所有 type ∈ {buy, sell, dividend, transfer_in, transfer_out} 的流水（带正负号），加最后一笔 `(valuationDate, +currentMarketValue)`。**baseline snapshot 不参与现金流**——它只决定"持有收益"基数。

### 4.3 Sharpe Ratio

旧 [:415-438](file:///Users/elvischen/Developer/investment%20app/FundMVP/Views/Holdings/HoldingsNAVCalculator.swift)：

```
sharpe(values: [Double], annualRf=0, daysPerYear=252) -> Double?:
    if values.count < 3: return nil
    dailyReturns = [v_i / v_{i-1} - 1 for i in 1..<count where v_{i-1}>0 and v_i>0]
    if dailyReturns.count < 2: return nil
    rfDaily = annualRf / 252
    excess  = dailyReturns - rfDaily
    mean    = excess.mean
    var     = Σ(x - mean)^2 / (n - 1)        // sample variance
    if var ≤ 0 or not finite: return nil
    std = sqrt(var)
    return (mean / std) * sqrt(252)
```

**注**：旧 BacktestEngine [:925-940](file:///Users/elvischen/Developer/investment%20app/FundMVP/Views/Backtest/BacktestEngine.swift) 的 sharpe 实现**未减无风险利率**（即 `rfDaily=0` 隐含）。新 v1 统一用上面 HoldingsNAVCalculator 的版本（带 rf 参数），`annualRf` 默认 0 时与 BacktestEngine 数字一致 —— 兼容老回测结果。

### 4.4 Calmar Ratio

```
calmar(annualizedReturn: Double?, maxDrawdown: Double) -> Double?:
    guard let r = annualizedReturn, r.isFinite, maxDrawdown.isFinite else: return nil
    denom = abs(maxDrawdown)
    if denom ≤ navZeroTolerance: return nil
    return r / denom
```

### 4.5 Maximum Drawdown / Current Drawdown

```
maxDrawdown(values) -> Double:                           // 返回非正值
    if values.first ≤ 0: return 0
    peak = values[0]
    md   = 0
    for v in values where v > 0:
        peak = max(peak, v)
        md   = min(md, v/peak - 1)
    return md

currentDrawdown(values) -> Double:
    if values.last ≤ 0: return 0
    peak = max(values)
    if peak ≤ 0: return 0
    return values.last / peak - 1
```

---

## 5. 持有收益（PRD §3.3）

```
持有收益     = 当前市值 − (最早 baseline snapshot 市值 + Σ baseline 后所有流水净投入)
持有收益率  = 持有收益 / (baseline 市值 + Σ 净投入)
```

**净投入**：

| 流水 type | 计入净投入 |
|---|---|
| buy / transfer_in | + amount |
| sell / transfer_out | − amount |
| dividend（再投，shares > 0）| 0（账户内循环）|
| dividend（现金，shares == 0）| − amount（账户外流出）|

UI 必须在持有收益附近小字注明 "自 `baseline.date` 起计"。

---

## 6. 测试要求（synthetic fixture）

`docs/algorithms/golden_fixtures/synthetic/` 下至少建：

1. `single_fund_pure_dca/` — 单基金、每月定投 1000、6 个月
2. `single_fund_with_dividend/` — 含一次现金分红 + 一次再投分红
3. `multi_fund_with_flows/` — 3 基金、不规则流水
4. `snapshot_forward_shift/` — 验证 baseline 前移规则（PRD §3.1 方案 B）
5. `extreme_day_return/` — 测试 dailyReturn > 0.5 的告警分支
6. `segment_reset/` — 中间清仓 → 重新建仓，验证段起点 NAV=1.0

每个 fixture 目录：

```
<scenario>/
├── input.json          # json_import.v1 格式
├── expected/
│   ├── nav_curve.csv   # date, nav, returnRate
│   ├── ledger.csv      # date, status, finalNAV, finalShares, ...
│   ├── metrics.json    # cagr, xirr, sharpe, calmar, maxDrawdown
│   └── hold_pnl.json   # 持有收益 / 持有收益率
└── derivation.md       # 每个 expected 值是怎么手算出来的
```

CI：`AlgorithmsTests` import fixture，diff > 1e-4 fail。

---

## 7. Changelog

- v1 (2026-04-25) —— 初版。从旧 [HoldingsNAVCalculator.swift](file:///Users/elvischen/Developer/investment%20app/FundMVP/Views/Holdings/HoldingsNAVCalculator.swift) port 逻辑，重写 API。
  - **口径偏移待 Elvis 裁定**：XIRR 时间归一化提议统一为 `86400*365.0`。旧 HoldingsNAVCalculator 用 `31_556_926` → 与本版会有 ~0.07% 量级数字差；若 Elvis 确认，这部分差异才可豁免红线 5。旧 BacktestEngine `86400*365` 与本版一致。
