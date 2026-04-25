# Salvage Matrix — 旧 app 迁移决策

> 旧 app 路径：`/Users/elvischen/Developer/investment app/`
> 本文件是 Opus/GPT 重构时的**唯一权威**：什么 port、什么 rewrite、以哪个文件的数字为准。
> 改动此文件 = 改动契约，按 [AGENTS.md 会合点](../../AGENTS.md#会合点契约驱动) 流程走。

---

## 决策矩阵

| 模块 | 旧 app 锚点 | 决策 | 新 repo 落点 | 理由 |
|---|---|---|---|---|
| **XIRR 求解** | `FundMVP/Views/Backtest/BacktestEngine.swift:1025-1058` | **Port as-is** | `ios/Algorithms/XIRR.swift`（纯函数）| 纯数学，Newton-Raphson 稳定，参数: 40 iter / tol 1e-7 / init 0.12 保留 |
| **TWRR 账户 NAV** | `FundMVP/Views/Holdings/HoldingsNAVCalculator.swift:4-62` `buildTWRRNAVCurve()` | **Port 逻辑, 重写 API** | `ios/Algorithms/NAV.swift` + `docs/algorithms/nav.v1.md` | 核心算法对，但参数混杂、无错误处理。抽成 `(inputs: NAVInput) -> NAVResult` |
| **账户分段 ledger** | 同上 `:171-335` `buildPortfolioNAVLedgerRows()` | **Port 逻辑, 重写 API** | `ios/Algorithms/NAV.swift` | 外部现金流分段正确，wrapper 太耦合 UI |
| **CAGR** | 同上 `:337-348` | **Port as-is** | `ios/Algorithms/Metrics.swift` | 单行公式 |
| **单基金 DCA 回测** | `BacktestEngine.swift:46-110` `buildSingleAssetResult()` | **Port as-is** | `ios/Algorithms/Backtest/SingleAsset.swift` | 执行循环干净 |
| **指标聚合**（CAGR/XIRR/Sharpe/Calmar/MaxDD）| `BacktestEngine.swift:112-140` `buildMetrics()` | **Port as-is** | `ios/Algorithms/Metrics.swift` | OK |
| **组合再平衡回测** | `BacktestEngine.swift:14-44` + 散落的阈值 | **Rewrite** | `ios/Algorithms/Backtest/Portfolio.swift` + config | 阈值 `0.08` 硬编码多处；策略与执行混；rebalance 频率（daily/weekly/monthly/quarterly）要抽 enum |
| **雷达六维打分** | `FundMVP/Views/Holdings/HoldingsHomeFeature.swift:3-95` 枚举 + `:84-95` 权重 + `:1458-1799` 七个打分函数 | **Rewrite（逻辑保留，数字对齐）** | `ios/Algorithms/Radar/` + `docs/algorithms/radar.v1.md` | 3797 行 god file；权重 0.22/0.22/0.18/0.14/0.14/0.10 抽成 config；打分函数逐个 port，各自 unit test 对齐旧数字 |
| **StrategyIntentConfig** | `HoldingsHomeFeature.swift:43` `default` | **Rewrite 为外部 config** | `docs/algorithms/strategy_intent.v1.md` + `ios/Config/StrategyIntent.swift` | 硬编码 `targetWeight=0.25` / `driftTolerance=0.08` / `weeklyMinimumContribution=1000` / `emergencyRepairWindowDays=90` / `negligibleDeviation=0.02`；用户可调 |
| **Persistence facade** | `FundMVP/Persistence/PersistenceController.swift:49-330` | **Port as-is** | `ios/Persistence/` | 分层合理，CoreData + file stores 已分开 |
| **CoreData 模型** | `FundMVP/Persistence/CoreDataPortfolioStore.swift` | **Port as-is** | `ios/Persistence/` | 新 schema 覆盖不变，保留 |
| **Widget refresh** | `FundMVP/App/HoldingsWidgetRefreshController.swift:25-102` | **Port + 拆职责** | `ios/Widgets/Refresh/` | 数据聚合 vs shared container 写出拆两个类 |
| **Widget data models** | `FundMVP/WidgetsShared/HoldingsWidgetStore.swift` | **Port as-is** | `ios/WidgetsShared/` | Codable 模型干净 |
| **Widgets（3 个）** | `FundMVPWidgets/HoldingsNAVLargeWidget`, `HoldingsRadarLargeWidget`, `HoldingsDailyScoreWidget` | **Port + 视觉对齐设计稿** | `ios/WidgetsExt/` | 数据通路不变；视觉用 `docs/design/` tokens 重画 |
| **App Group 共享容器** | （App delegate / entitlements 配置）| **Port as-is** | `ios/` + entitlements | 改 bundle id 时一起改 |
| **Networking layer** | `FundMVP/Networking/FundDataProvider.swift` + `APIClient.swift` | **Port as-is** | `ios/Networking/` | 最小且有效 |
| **Backend（FastAPI 代理）** | `/Users/elvischen/Developer/investment app/backend/` + 部署在 `http://159.75.16.87` | **Port as-is + 加 .env + 加请求校验** | 暂不复制到 `backtester_note/`，直接复用线上实例；GPT 起草时写 `docs/contracts/api.v1.md` 对齐实际路由 | 旧代码能跑，Pro 直接调 |
| **旧 `prd/` 75 份 session log** | `prd/*.md` | **不迁移** | — | Elvis 决定。考古需要时查旧 repo |
| **旧 app 本身** | 整个旧仓库 | **不改** | — | Elvis 决定。仅在"导出按新 schema"有强需求时考虑加一个导出按钮 |

---

## 调试债（Phase 1 必须解决）

旧 app 有这些"能用但脏"的地方。重构时顺势清掉：

1. **`HoldingsHomeFeature.swift` 3797 行** —— 拆为：`HoldingsViewModel`（SwiftUI 状态）+ `RadarScoring`（纯函数）+ `HoldingsOrchestrator`（数据编排）
2. **`navPrecision=4` / `navZeroTolerance=0.0001` 在多处定义** —— 收拢到 `ios/Algorithms/Constants.swift`
3. **再平衡阈值 `0.08` 硬编码** —— 抽到 `StrategyIntentConfig`
4. **零单元测试** —— Phase 1 不允许这条继续。XIRR / TWRR / 雷达打分每个都要测
5. **`ViewModels/` 空目录，状态全在 View** —— 新 repo 强制 View ↔ ViewModel ↔ Service 三层
6. **缓存散落** —— `HoldingOverviewCache` / `HoldingStrategyScoreCache` 在 feature / controller / persistence 多处。新 repo 走单一 `CacheService`

---

## Golden Fixture 流程（schema-first 两步走）

**为什么需要**：[PRD v2 §5 红线 4](../prd/Backtester_Note_PRD_v2.md) 说数字漂移 > 0.01% 必须停。靠人肉对数不可持续，必须 CI 自动化。

**详细流程见 [架构 §6.2](../architecture/overview.v1.md)**。要点：

- **Step 1（不阻塞）**：synthetic fixture 由 Opus 在算法 port 时按 `json_import.v1` + 算法文档手工构造，单元测试驱动力。放 `docs/algorithms/golden_fixtures/synthetic/<scenario>/`。
- **Step 2（Phase 1 ship 前补）**：real fixture 由 Elvis 自然时机从旧 app 导出，与旧 app 数字交叉验证。放 `docs/algorithms/golden_fixtures/real/<account_slug>/`。

**当前状态**：Step 1 与算法 port 同步推进；Step 2 不卡进度，等 Elvis。

---

## Changelog

- v1 (2026-04-25) — 初版，基于 Explore agent 的旧 app survey
- v1.1 (2026-04-25) — Golden Fixture 流程改为 schema-first 两步走，详见架构 §6.2；real fixture 不再标 Phase 1 阻塞项
