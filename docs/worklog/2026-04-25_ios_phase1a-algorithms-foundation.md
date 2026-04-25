# 2026-04-25 · ios · phase1a-algorithms-foundation

**Agent**: GPT
**Role**: Dev
**Scope**: Phase 1a 第一片：建立可裸跑 SwiftPM Algorithms 包，落 XIRR / NAV / Metrics / Radar / StrategyIntent 基础实现与单测。

## What changed

- `ios/Package.swift`：新增 `BacktesterNoteAlgorithms` SwiftPM package，最低 iOS `17.4`，并允许 macOS 测试宿主裸跑。
- `ios/Sources/BacktesterNoteAlgorithms/Constants.swift`：新增算法精度、XIRR 迭代、年化天数常量。
- `ios/Sources/BacktesterNoteAlgorithms/BNCalendar.swift`：新增 `Asia/Shanghai` 自然日工具。
- `ios/Sources/BacktesterNoteAlgorithms/XIRR.swift`：实现 Newton-Raphson XIRR，统一 `365.0` 天分母。
- `ios/Sources/BacktesterNoteAlgorithms/Metrics.swift`：实现 CAGR / Sharpe / Calmar / MaxDD / CurrentDD。
- `ios/Sources/BacktesterNoteAlgorithms/NAV.swift`：实现 TWRR NAV 曲线与基础 ledger row。
- `ios/Sources/BacktesterNoteAlgorithms/StrategyIntent.swift`：落旧 app 默认策略意图常量。
- `ios/Sources/BacktesterNoteAlgorithms/Radar.swift`：落雷达维度、快照、配置、简单平均总分、策略执行子权重、超额质量线性阈值。
- `ios/Tests/BacktesterNoteAlgorithmsTests/`：新增 10 个 Swift Testing 单测覆盖 NAV 段起点、现金流剥离、清仓重启、XIRR、CAGR、回撤、雷达总分、策略执行子权重、StrategyIntent 默认值。

## Contract change

无 `docs/contracts/` 变更。

## Algorithm drift

无新增 drift。本次按已裁定口径实现：

- XIRR 使用 `365.0` 天分母。
- 雷达总分六维简单平均。
- `0.22/0.22/0.18/0.14/0.14/0.10` 仅用于 `strategyExecution` 子分。

## Verification

- ✅ `swift test`（在 `ios/` 下执行）通过，10 个测试全绿。

## Review

- ⏳ 等 Opus review：
  - NAV ledger 字段是否足够后续 Settings → 数据维护页对账使用。
  - SwiftPM package 作为 Phase 1a 裸跑入口是否符合后续 Xcode 工程接入方式。

## Next

- [ ] 补 synthetic fixture 文件并让 tests 从 fixture 读取 expected。
- [ ] 继续 port Backtest 单基金 DCA 与 SIP schedule。
- [ ] 逐函数 port Radar 六维详细评分，并与旧 app 行号对齐。
