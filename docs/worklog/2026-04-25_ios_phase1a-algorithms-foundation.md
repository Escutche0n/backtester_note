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

### Opus review (2026-04-25)

**Agent**: Opus
**Role**: Review
**裁定**: ✅ 通过。Phase 1a 可以作为 Phase 1b iOS 骨架的依赖基线。

**验证**

- `swift test`（工作目录 `ios/`）10/10 全绿，已本地复跑确认。
- `ios/Package.swift` 平台声明 `iOS("17.4")` 与架构 v1.3 §8 一致；`macOS(.v14)` 让测试可在 macOS host 裸跑，符合架构 §2 "Algorithms 必须能裸跑"。
- 单测覆盖面：NAV 段起点 / 现金流剥离 / 清仓重启、XIRR 年化分母 365、CAGR、Drawdown、雷达总分简单平均、策略执行子权重 0.22/0.10 端点、StrategyIntent 默认值。Phase 1a 的 P0 已覆盖到位。

**逐条回应 GPT review 清单**

1. `docs/architecture/overview.v1.md` Phase 1a/1b/1c 拆分
   - 适合 Opus 接下来建 Xcode 工程。Phase 1b 顶层目录与生成方式见下方"Phase 1b 启动建议"。
2. `ios/Package.swift`
   - 适合后续被 Xcode App target 引用：作为 local SwiftPM package 加进 Xcode workspace 即可，不需要再发版。
   - `IPHONEOS_DEPLOYMENT_TARGET = 17.4` 在 Xcode 工程创建时同步设置。
3. `ios/Sources/BacktesterNoteAlgorithms/`
   - **NAV.swift**：`NAVLedgerRow` 字段（`endingMarketValue / externalCashFlow / previousShares / preFlowMarketValue / preFlowNAV / finalShares / finalNAV / status`）+ `NAVLedgerStatus` 9 个枚举值，已能撑起架构 §3 Settings → 数据维护页对账所需信息。`segment_reset_invalid_*` / `skip_*` / `segment_end_zero_position` 这套显式状态符合架构 §5.4 错误处理"区分而非静默"原则，Phase 1c ImportService 与未来 Holdings 数据维护页可以直接读 status 渲染对账提示。
   - **Radar.swift**：当前只实现 `excessQuality` 与 `strategyExecution` 子分；`tradingDiscipline / riskControl / styleStability / sustainability` 四维尚未实现。**不阻塞 Phase 1b mock UI**——1b 注入 mock 6 维数字即可。
   - 雷达窗口期：当前默认仍是 `180/90/...`，未反映 `2026-04-25_radar-six-dimensions-review.md` 中"统一 90 天 + 5/22 交易日锚点"的待裁定项。等 Elvis 裁定后由 GPT 改文档与代码，**不在 Phase 1b 范围**。
4. `ios/Tests/BacktesterNoteAlgorithmsTests/`
   - 当前 10 个内联单测作为 Phase 1a 第一片**已足够**。下一步按架构 §6.2 由 GPT 补 synthetic fixture 文件，让 tests 从 fixture 读 expected。

**架构 §8 待回填项 · Opus 建议（请 GPT 知会后另起 commit 落到 architecture v1.4）**

| 项 | Opus 建议 | 理由 |
|---|---|---|
| Xcode 工程顶层目录 | 保持 `ios/`，Xcode 工程文件落 `ios/BacktesterNote.xcodeproj`，与 `ios/Package.swift` 同根 | 架构 §3 目录骨架已假设 `ios/App/ ios/Features/ ios/Services/...`；新增 `BacktesterNote/` 顶层目录会让 SwiftPM 与 App target 二次搬迁 |
| 工程生成方式 | 用 `xcodegen` + `ios/project.yml`（dev-only 工具，不进二进制） | 单人项目手动维护 `pbxproj` 代价高；xcodegen 让 target 配置文本可 review；与 SwiftLint / swift-format 同属架构 §8 允许的"开发期工具" |

以上两项在本 commit 不动 architecture 文件，仅作为建议；Elvis 裁定后由 GPT 在独立 commit 走 `## Contract change` 流程落 §8 表格。

**对接 1b 不阻塞但需记一笔的后续工作**

- Radar 四维实现（GPT 后续 port）。
- 雷达窗口期与三快照锚点裁定（Elvis 决策待定，详见 `2026-04-25_radar-six-dimensions-review.md`）。
- Synthetic fixture 文件（GPT 已认领）。
- API contract `portfolio/history` mock 收口（Phase 3 解锁前由 GPT 处理）。

**Opus 即将启动的下一个工作单元**

- Phase 1b-1：`ios/project.yml`（xcodegen spec）+ `ios/App/BacktesterNoteApp.swift` + `RootTabView.swift`（持仓 / 回测 TabView 占位）+ Bundle ID / App Group entitlements。
- 严格独立 commit；本 review commit 完成并提交后才会开新 session 启动。

## Next

- [ ] 补 synthetic fixture 文件并让 tests 从 fixture 读取 expected。
- [ ] 继续 port Backtest 单基金 DCA 与 SIP schedule。
- [ ] 逐函数 port Radar 六维详细评分，并与旧 app 行号对齐。
