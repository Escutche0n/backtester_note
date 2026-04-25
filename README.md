# 回测手记 / Backtester Note

`backtester_note` 是一款 iOS 原生个人基金复盘工作台，面向国内个人基金投资者。核心只做两件事：

1. **跟踪持仓**：真实账户 NAV、趋势雷达、交易流水、Widgets。
2. **回测复盘**：单基金、组合、定投、历史策略对比。

产品目标是回答三个问题：我现在到底持有什么；净值变化来自市场还是操作；如果继续某种定投或调仓方式，过去会怎样。

## 当前阶段

当前仓库处于 **Phase 0 → Phase 1a** 切换点。

- Phase 0 文档基线已建立：PRD、架构、算法口径、JSON 导入契约、设计稿、worklog。
- Phase 1a 可启动：端上 Algorithms 层 port + synthetic golden fixture。
- 后端 GitHub URL 已提供；`api.v1.md` 已按后端源码更新到 v1.1。`portfolio/history` 仍是 mock，后续需在后端 repo 实现。
- iOS 最低版本已定为 **17.4**。

## 开工前必读

每个 AI agent 每次开工前先读 [AGENTS.md](AGENTS.md)。它是本仓协作规则的最高入口。

必读顺序：

1. [AGENTS.md](AGENTS.md)
2. [docs/prd/Backtester_Note_PRD_v2.md](docs/prd/Backtester_Note_PRD_v2.md)
3. [docs/design/README.md](docs/design/README.md) + 当前任务涉及的设计源文件
4. 最近 worklog：自己层最近 2 条 + 对方层最近 1 条
5. 本次要改的契约或算法文档

禁止在未读上述文件前修改 `ios/`、`backend/` 或 `docs/contracts/`。

## 角色与目录所有权

| 区域 | 默认 owner | 规则 |
|---|---|---|
| `ios/` | Opus | SwiftUI、Algorithms port、Widgets、本地存储、视觉实现 |
| `backend/` | GPT | FastAPI、抓取、缓存、API schema、Pro 同步任务 |
| `docs/contracts/` | 任一方，需会合 | 改动必须写 worklog 并 @ 另一方确认 |
| `docs/algorithms/` | GPT 主笔，Opus 校验 | 任何数字口径变更都要记录 drift |
| `docs/prd/` | Elvis | AI 只读，除非 Elvis 明确授权 |
| `docs/design/` | Elvis / Claude Design | AI 只读，设计调整写 request |
| `docs/worklog/` | 谁干活谁写 | 每次收工必须补 |

## 权威文档

| 文档 | 用途 |
|---|---|
| [docs/prd/Backtester_Note_PRD_v2.md](docs/prd/Backtester_Note_PRD_v2.md) | 产品冻结项、Free/Pro 边界、红线 |
| [docs/architecture/overview.v1.md](docs/architecture/overview.v1.md) | iOS 分层、数据流、工程默认值、阶段拆分 |
| [docs/contracts/json_import.v1.md](docs/contracts/json_import.v1.md) | 快捷指令 / 外部工具导入 schema |
| [docs/contracts/api.v1.md](docs/contracts/api.v1.md) | Pro 后端 API 契约 v1.1 |
| [docs/contracts/legacy_fundmvp_mapping.md](docs/contracts/legacy_fundmvp_mapping.md) | 旧 FundMVP 导出到新 schema 的映射 stub |
| [docs/algorithms/nav.v1.md](docs/algorithms/nav.v1.md) | NAV、XIRR、CAGR、Sharpe、Calmar、回撤、持有收益 |
| [docs/algorithms/radar.v1.md](docs/algorithms/radar.v1.md) | 趋势雷达六维、三快照、StrategyIntent 子分 |
| [docs/algorithms/backtest.v1.md](docs/algorithms/backtest.v1.md) | 单基金 / 组合 / 定投 / 再平衡回测口径 |
| [docs/algorithms/strategy_intent.v1.md](docs/algorithms/strategy_intent.v1.md) | 策略意图配置默认值 |
| [docs/algorithms/salvage_matrix.md](docs/algorithms/salvage_matrix.md) | 旧 app port / rewrite 决策 |

## 已裁定口径

- **XIRR 时间归一化**：统一 `365.0` 天，账户 XIRR 与回测 XIRR 保持可对账。
- **雷达总分**：六维简单平均，每维 `1/6`。
- **策略执行子分**：`0.22 / 0.22 / 0.18 / 0.14 / 0.14 / 0.10` 仅用于 `strategyExecution` 维度内部。
- **NAV 可信度 tag**：由 `NAVService` 根据数据来源打标，`NAV.swift` 只负责纯数值计算。
- **Free/Pro 红线**：核心算法结果不阉割；Pro 只买省心、规模、自定义和自动化。

## 仍待补齐

- 后端 `POST /api/portfolio/history`：当前仍是 mock，需要在 `backtester-backend` repo 替换成真实基金历史聚合。
- 旧 FundMVP 导出字段表：用于补 [docs/contracts/legacy_fundmvp_mapping.md](docs/contracts/legacy_fundmvp_mapping.md) v1.1。
- Real golden fixture：Elvis 后续从旧 app 导出真实账户，Phase 1 ship 前必须补。

## 阶段路线

| 阶段 | 目标 | 关键产物 |
|---|---|---|
| Phase 1a | Algorithms 地基 | `ios/Algorithms/*` + synthetic golden fixture CI |
| Phase 1b | UI 骨架 | Xcode 工程、DesignSystem、Holdings mock UI、Settings 壳 |
| Phase 1c | 真数据接通 | Persistence、ImportService、JSON 预览与落库、快照前移 UI |
| Phase 2 | 回测与 Widgets | Backtest 四模式、历史对比、三个核心 widget、快捷指令模板 |
| Phase 3 | Pro 自动化 | StoreKit、后端同步、Widget snapshot 推送、离线回退 |
| Phase 4 | 上架 | 隐私、合规、TestFlight、App Store |
| Phase 5 | 平台扩展 | Mac Catalyst 或原生评估 |

## 开发纪律

- 一次 session 只做一个连贯小单元。
- 改契约、算法、PRD 必须写 worklog。
- 算法数字与旧 app 差异 > `0.01%` 视为口径漂移，必须停下等 Elvis 裁定。
- 不得自作主张加三方 SDK、analytics、tracker 或新网络请求。
- Free 不调用自建后端 `159.75.16.87`；Pro 才走后端。

## 当前建议入口

下一位执行者如果做 iOS，应从 Phase 1a 开始：

1. 建 Algorithms 可裸跑的 Swift package / target。
2. Port `XIRR.swift`、`NAV.swift`、`Metrics.swift`。
3. 建 `docs/algorithms/golden_fixtures/synthetic/` 最小 fixture。
4. 用单测锁 `nav.v1.md`、`radar.v1.md`、`backtest.v1.md` 的口径。

如果做后端/契约，应进入 `https://github.com/Escutche0n/backtester-backend`，优先补部署流程和真实 `portfolio/history`。
