# 2026-04-25 · be · review-arch-and-algo-docs

**Agent**: GPT（本次按 backend/契约层职责工作）
**Role**: Review（评 Opus 早上 commit `bba10df` + `11cb772`）+ Dev（落 6 份缺失算法/契约文档）
**Scope**: Phase 0 review + 算法/契约文档第一轮交付，解锁 Phase 1a 启动。

## What changed

### Review 部分（架构 v1.1 → v1.2，5 处微调）

[`docs/architecture/overview.v1.md`](../architecture/overview.v1.md)：

1. **§6.2 synthetic fixture 简化**：去除"Python notebook 独立实现交叉验证"要求；改为"算法文档手算 + `derivation.md`"。一人项目的 over-engineering 修正。
2. **§8 工程基础设施加 SwiftLint / swift-format**：开发期工具，不进二进制，不违反零三方红线。
3. **§8 Xcode 工程顶层目录决议挂起**：等 Phase 1b 起 Xcode 工程时由 Opus 在 worklog 决定 `ios/` vs `BacktesterNote/`。
4. **§9 引用矩阵更新**：4 份算法文档 ✅；api 与 legacy_fundmvp_mapping 改 stub；明确 Phase 1a/1c/3 的解锁条件。
5. **§10 Phase 1 拆 1a/1b/1c 三个可独立 ship 子阶段**：Algorithms 地基 / UI 骨架 / 接通真数据。

Changelog 写为 v1.2。

### Dev 部分（6 份算法 / 契约文档）

| 文件 | 状态 | 说明 |
|---|---|---|
| `docs/algorithms/nav.v1.md` | ✅ 完整 | TWRR + Ledger + CAGR / XIRR / Sharpe / Calmar / MaxDD + 持有收益。**含 1 处已裁定口径偏移**（§4.2，详见 ## Algorithm drift）|
| `docs/algorithms/radar.v1.md` | ✅ 完整骨架 | 六维定义 + 三快照 + StrategyIntent 子分公式 + RadarConfig 外化。**修正 PRD v2 §3.4 一处口径错误**（详见 ## Algorithm drift）。各维度详细公式留 Phase 1a port 时与旧 app 单测对齐补 v1.1。 |
| `docs/algorithms/backtest.v1.md` | ✅ 完整 | 单基金 / 三种组合策略 / 阈值再平衡 snapshot 冻结 / SIP 计划生成 / 赎回费分级 |
| `docs/algorithms/strategy_intent.v1.md` | ✅ 完整 | 6 个常量字段 + 用途索引 + Free/Pro 边界 |
| `docs/contracts/api.v1.md` | ⚠️ stub | 路由表 + Free/Pro 边界冻结；字段 schema 待 GPT 拿到后端代码后补 v1.1 |
| `docs/contracts/legacy_fundmvp_mapping.md` | ⚠️ stub | 仅声明任务 + baseline 推导规则；字段表待 GPT 反推旧 Persistence |

## Contract change

新增 4 份算法契约 + 2 份接口契约 stub。任一改动按 [AGENTS.md 会合点](../../AGENTS.md#会合点契约驱动) 流程走，特别是：

- `nav.v1.md` 公式改 → 必须 @ Opus 重跑 synthetic fixture
- `radar.v1.md` 维度定义 / 子权重改 → 同上
- `backtest.v1.md` 策略公式改 → 同上
- `api.v1.md` v1.1 完整化时 GPT 要 @ Opus 确认 iOS 调用方好用

## Algorithm drift

本次发现 **2 处口径需 Elvis 裁定**：

### Drift 1 · XIRR 时间归一化

旧 app 两处 XIRR 实现使用**不同**的"年"分母：

| 文件 | 公式 |
|---|---|
| `HoldingsNAVCalculator.swift:367` | `years = timeIntervalSince(baseDate) / 31_556_926`（一回归年 ≈ 365.2422 天）|
| `BacktestEngine.swift:1032` | `years = (timeInterval / 86400) / 365.0`（365 天）|

**v1 决议（Elvis 2026-04-25 确认）**：统一为 **`365.0`**（即 BacktestEngine 版本）。理由：账户 XIRR 与回测 XIRR 必须可对账。

**影响**：与旧 app 持仓 XIRR 数字会有微小差异（年化 ~0.07% 量级），**可能触发 0.01% 漂移红线**。

Elvis 已确认，Phase 1a 可按 `365.0` 口径实现。

### Drift 2 · 雷达总分权重（修正 PRD v2 §3.4 错置）

PRD v2 §3.4 写：

> 权重：0.22 / 0.22 / 0.18 / 0.14 / 0.14 / 0.10（来自旧 app `HoldingsHomeFeature.swift:84-95`，v2 不改）

**这是错的**。旧 app 真实口径（[HoldingsHomeFeature.swift:20-24](file:///Users/elvischen/Developer/investment%20app/FundMVP/Views/Holdings/HoldingsHomeFeature.swift)）：

```swift
var overallScore: Double {
    let values = StrategyRadarDimension.allCases.compactMap { scores[$0] }
    return values.reduce(0, +) / Double(values.count)   // 简单平均
}
```

那组 `0.22/0.22/0.18/0.14/0.14/0.10` 是**单一维度内部** `策略执行` 的子分权重（[`:84-95`](file:///Users/elvischen/Developer/investment%20app/FundMVP/Views/Holdings/HoldingsHomeFeature.swift)）。

**v1 决议（Elvis 2026-04-25 确认）**：六维总分保持简单平均（每维 1/6 ≈ 0.1667），与旧 app 数字一致。子权重 0.22/0.22/... 用在 strategyExecution 维度内部（[radar.v1.md §3.2](../algorithms/radar.v1.md)）。

PRD v2 §3.4 已由 GPT 于 2026-04-25 09:19 CST 按 Elvis 授权修正为："总分权重：每维 1/6（简单平均）；策略执行子分权重 0.22/0.22/.../0.10"。

## Review

- ⏳ 等 Opus review：
  - 4 份算法文档（nav/radar/backtest/strategy_intent）公式与他读过的旧 app 实现是否完全一致
  - 2 处口径 drift 是否同意决议（特别是 XIRR 365.0 那条）
  - api.v1.md / legacy_fundmvp_mapping.md 的 stub 范围是否合理
- ⏳ 等 Elvis 提供：
  - 后端代码访问路径（api.v1.md §6.1）

## Conflict

无未决冲突。本次 review 改的 5 处都是微调，不动架构主结构。

## Questions for Elvis

1. ✅ **XIRR 时间归一化统一为 365.0 天**。
2. ✅ **雷达总分用简单平均**（每维 1/6），策略执行维度内部继续使用 0.22/0.22/.../0.10 子权重。
3. ⏳ **后端代码访问路径**：旧 backend repo GitHub URL 待 Elvis 提供（影响 `api.v1.md` v1.1 完整化）。

## Ideas

- `api.v1.md` v1.1 完整化时，可以加一个 `Endpoints.swift` 自动生成器（从 v1 文档生成 Swift 类型），减少 iOS 端手写错位。Phase 3 再说。
- `radar.v1.md` 的 6 个打分函数详细公式 port 时，可以同步把每个旧 app 函数的行号写进 v1.1 changelog，便于未来追溯。

## Next

- [x] **Elvis** 裁定 XIRR / Radar 两处口径 drift
- [ ] **Elvis** 提供后端 GitHub URL
- [ ] **Opus** review 本次产出（4 份算法 + 2 份 stub + 架构 v1.2 微调）
- [ ] **Opus** 开 Phase 1a：Algorithms 层 port + synthetic fixture（按 [nav.v1.md §6](../algorithms/nav.v1.md) / [radar.v1.md §6](../algorithms/radar.v1.md) / [backtest.v1.md §8](../algorithms/backtest.v1.md) 列的场景表）
- [ ] **GPT** 待 Elvis 给后端代码路径后补 `api.v1.md` v1.1 完整 schema
- [ ] **GPT** 待旧 app 任意时机导出 → 反推 `legacy_fundmvp_mapping.md` v1.1 字段表
