# Architecture Overview v1 — Backtester Note

> 本文件是**技术架构权威**：iOS 客户端怎么分层、模块怎么依赖、数据怎么流、Free/Pro 怎么分流。
> 与 [PRD v2](../prd/Backtester_Note_PRD_v2.md) 配套：PRD 是"做什么 / 不做什么"，本文是"怎么搭"。
> 改动本文 = 改动架构契约。流程同 [AGENTS.md · 会合点](../../AGENTS.md#会合点契约驱动)。
>
> **冲突优先级**：PRD v2 §1–§7 > 本架构 > salvage_matrix > 旧 app 实现。

---

## 0. 整合的源材料

| 源 | 给本文提供的东西 |
|---|---|
| [PRD v2](../prd/Backtester_Note_PRD_v2.md) | 信息架构（2 tab）、Free/Pro 边界、红线、口径冻结 |
| [salvage_matrix](../algorithms/salvage_matrix.md) | 旧 app 18 个模块的 port/rewrite 决策、调试债清单、golden fixture 流程 |
| [json_import.v1](../contracts/json_import.v1.md) | App 的唯一外部数据入口 schema |
| [bn-tokens.css](../design/project/lib/bn-tokens.css) + [bn-*.jsx](../design/project/lib/) | UI token、组件层级、Liquid Glass 风格 |
| [AGENTS.md](../../AGENTS.md) | 协作分工（Opus=iOS, GPT=backend）、红线 |
| 旧 app `/Users/elvischen/Developer/investment app/` | 算法实现的数字基准（仅参考，不搬运结构）|
| 旧后端 `/Users/elvischen/Developer/backtester_backend/` + `http://159.75.16.87` | Pro 数据源，复用不复制 |

---

## 1. 系统全景

```
                  ┌───────────────────────────────────────┐
                  │            iOS App (Swift)            │
                  │       backtester_note 主仓 / ios/     │
                  └──────────────┬────────────────────────┘
                                 │
            ┌────────────────────┼────────────────────────┐
            │                    │                        │
   ┌────────▼────────┐  ┌────────▼─────────┐   ┌──────────▼────────┐
   │  用户输入       │  │  快捷指令 / JSON │   │   自建后端        │
   │  (手动录入)     │  │  (json_import.v1)│   │  159.75.16.87     │
   └─────────────────┘  └──────────────────┘   │  (Pro only)       │
                                               │  FastAPI 旧仓库   │
                                               └───────────────────┘

   旧 iOS app = 算法数字基准（golden fixture 来源），不直接调用、不搬运代码。
   旧后端 = 直接复用线上实例，不在新仓库 fork。
```

**新仓库职责**：只装新 iOS 客户端 + 文档 + 契约。后端不进新仓。

---

## 2. iOS 分层（5 层，单向依赖）

```
┌─────────────────────────────────────────────────┐
│  L5  App Shell        ios/App/                  │
│      入口、TabView、SettingsSheet、Entitlements │
└─────────────────────────┬───────────────────────┘
                          │ depends on
┌─────────────────────────▼───────────────────────┐
│  L4  Features          ios/Features/            │
│      View + ViewModel（Holdings / Backtest /    │
│      Settings）                                 │
└─────────────────────────┬───────────────────────┘
                          │ depends on
┌─────────────────────────▼───────────────────────┐
│  L3  Services          ios/Services/            │
│      Portfolio / NAV / Radar / Backtest /       │
│      Import / Price / Cache / WidgetSync        │
└──────────┬───────────────────────────┬──────────┘
           │ depends on                │ depends on
┌──────────▼─────────┐       ┌─────────▼──────────┐
│ L2  Algorithms     │       │ L2  Infrastructure │
│ ios/Algorithms/    │       │ ios/Persistence/   │
│ 纯函数、无 IO、    │       │ ios/Networking/    │
│ 无 SwiftUI         │       │ ios/Config/        │
└────────────────────┘       └────────────────────┘
                          │
┌─────────────────────────▼───────────────────────┐
│  L1  Shared Surfaces    ios/WidgetsShared/      │
│      App Group 共享 Codable 模型                │
│      ios/WidgetsExt/（Widget targets）          │
└─────────────────────────────────────────────────┘
```

**依赖规则**（CI 检查）：

| 层 | 可依赖 | 不可依赖 |
|---|---|---|
| Algorithms | `Foundation` 数值部分 | 任何 SwiftUI / Combine / CoreData / Network |
| Infrastructure | Algorithms（仅 Persistence 写算法结果时）| Features / Services |
| Services | Algorithms + Infrastructure | Features |
| Features | Services + Shared | Algorithms 不直调 |
| Shell | Features | — |

**为什么 Algorithms 是地基**：`docs/algorithms/*.v1.md` 的口径要在两个地方独立验证（iOS app + 后端的复算，将来可能加 macOS / 服务端校验工具）。Algorithms 层必须能裸跑，无任何客户端依赖。

---

## 3. 目录骨架（最终态）

```
ios/
├── App/
│   ├── BacktesterNoteApp.swift      # @main
│   ├── RootTabView.swift            # 持仓 / 回测
│   ├── Entitlements/
│   │   ├── BacktesterNote.entitlements
│   │   └── BacktesterNoteWidgets.entitlements
│   └── Info.plist
├── Features/
│   ├── Holdings/
│   │   ├── HoldingsView.swift
│   │   ├── HoldingsViewModel.swift
│   │   ├── Components/
│   │   │   ├── TotalHeader.swift
│   │   │   ├── OverviewPanel.swift  # 9 metrics 3×3
│   │   │   ├── NavCard.swift
│   │   │   ├── RadarCard.swift
│   │   │   └── HoldingsList.swift
│   │   └── HoldingDetail/           # 点卡片进入
│   ├── Backtest/
│   │   ├── BacktestView.swift
│   │   ├── BacktestViewModel.swift
│   │   ├── Modes/
│   │   │   ├── SingleFundConfig.swift
│   │   │   ├── PortfolioConfig.swift
│   │   │   ├── SIPConfig.swift
│   │   │   └── HistoryList.swift
│   │   └── ResultPreview.swift
│   └── Settings/
│       ├── SettingsSheet.swift      # 右上齿轮入口
│       ├── AccountSection.swift
│       ├── DataMaintenanceSection.swift
│       ├── CacheSection.swift
│       ├── ImportExportSection.swift # 快捷指令 + JSON
│       ├── WidgetsSection.swift
│       ├── AppearanceSection.swift  # 密度/填充/hue（Pro）
│       └── SubscriptionSection.swift # Phase 1 占位
├── Services/
│   ├── PortfolioService.swift       # 账户/快照/流水 CRUD + 不变量
│   ├── NAVService.swift             # 调 Algorithms/NAV，缓存
│   ├── RadarService.swift           # 调 Algorithms/Radar，三快照
│   ├── BacktestService.swift        # 编排 Algorithms/Backtest
│   ├── ImportService.swift          # JSON v1 解析+预览+落库
│   ├── PriceService.swift           # Free 节流 / Pro 走后端
│   ├── CacheService.swift           # 单一缓存 facade
│   └── WidgetSyncService.swift      # 写 App Group + 触发刷新
├── Algorithms/
│   ├── Constants.swift              # navPrecision/zeroTolerance
│   ├── XIRR.swift                   # port as-is
│   ├── NAV.swift                    # port 逻辑+重写 API
│   ├── Metrics.swift                # CAGR/Sharpe/Calmar/MaxDD
│   ├── Radar/
│   │   ├── RadarScoring.swift       # 6 维打分（rewrite）
│   │   ├── RadarWeights.swift       # 0.22/0.22/0.18/0.14/0.14/0.10
│   │   └── RadarThresholds.swift
│   └── Backtest/
│       ├── SingleAsset.swift        # port as-is
│       ├── Portfolio.swift          # rewrite，rebalance enum
│       └── BacktestTypes.swift
├── Persistence/
│   ├── PersistenceController.swift  # port as-is
│   ├── CoreDataPortfolioStore.swift # port as-is
│   ├── BacktestHistoryStore.swift   # 文件型
│   └── Migrations/
├── Networking/
│   ├── APIClient.swift              # port as-is
│   ├── FundDataProvider.swift       # port as-is
│   └── Endpoints.swift              # 来自 docs/contracts/api.v1.md
├── Config/
│   ├── StrategyIntent.swift         # 抽出旧硬编码：targetWeight/driftTolerance/...
│   ├── RadarConfig.swift
│   └── Entitlement.swift            # Free / Pro
├── DesignSystem/
│   ├── BNTokens.swift               # 镜像 bn-tokens.css
│   ├── BNColor.swift
│   ├── BNFont.swift
│   ├── BNRadius.swift
│   ├── BNGlassModifier.swift        # iOS 26 Liquid Glass
│   └── BNFrostModifier.swift
├── WidgetsShared/                   # App + Widget 都能 import
│   ├── HoldingsWidgetStore.swift    # port as-is
│   └── SnapshotPayload.swift
├── WidgetsExt/                      # Widget extension target
│   ├── HoldingsNAVLargeWidget.swift
│   ├── HoldingsRadarLargeWidget.swift
│   └── HoldingsDailyScoreWidget.swift
└── Tests/
    ├── AlgorithmsTests/             # 跑 golden fixtures
    ├── ServicesTests/               # in-memory CoreData
    └── ImportTests/

docs/
├── prd/                             # 产品权威，Elvis only
├── architecture/                    # 技术架构权威（本文件所在）
├── contracts/                       # 接口契约（GPT 主笔）
├── algorithms/                      # 数值口径（GPT 主笔，Opus 校验）
│   └── golden_fixtures/<account>/   # Phase 1 阻塞项
├── design/                          # Claude Design 主笔，Opus 实现
├── collaboration/                   # 旧 workflow，待清理（见 §11）
└── worklog/                         # session log
```

---

## 4. 五条关键数据流

### 4.1 JSON 导入 → 持久化

```
JSON 文件 (json_import.v1)
   ↓
ImportService.preview(url) → ImportPreview
   │   ├── schema 校验
   │   ├── baseline 不变量校验
   │   └── 快照前移检测（如有）
   ↓ 用户在 ImportPreviewView 点"确认"
ImportService.commit(preview)
   ↓
PortfolioService.merge(accounts)        # snapshot upsert by date
   ↓                                     # flow dedup by (date,code,type,amount,shares)
CoreDataPortfolioStore.save()
   ↓
PortfolioService.didChange (Combine)
   ↓
HoldingsViewModel 重算 → View 刷新
   ↓
WidgetSyncService.refreshAfterDataChange()
```

### 4.2 持仓首屏渲染

```
HoldingsView (onAppear)
   ↓
HoldingsViewModel.load()
   ↓
   ├─ PortfolioService.currentAccount() → Account
   ├─ NAVService.curve(account, range: .threeMonths)
   │       ↓ 命中 CacheService 则直返
   │       ↓ 否则 → Algorithms/NAV.swift（纯函数）→ 写缓存
   ├─ RadarService.snapshots(account)
   │       ↓ → Algorithms/Radar/RadarScoring.swift
   ├─ Metrics 9 项                     # CAGR/XIRR/Sharpe/Calmar/...
   └─ 失衡 = currentWeight − targetWeight from StrategyIntent
   ↓
View 渲染（TotalHeader / OverviewPanel / NavCard / RadarCard / HoldingsList）
```

**NAV 可信度状态机**（PRD §3.2）由 `NAV.swift` 在每个点上打 tag，View 层只负责按 tag 决定半透明/灰/⚠ 标记。

### 4.3 回测执行

```
BacktestView 选模式 + 配参数
   ↓
BacktestViewModel.run(config)
   ↓
BacktestService.execute(config)
   ├─ 单基金 → Algorithms/Backtest/SingleAsset.swift
   ├─ 组合   → Algorithms/Backtest/Portfolio.swift（rebalance enum）
   ├─ 定投   → SingleAsset 加 SIP rule
   └─ 历史   → BacktestHistoryStore.list()
   ↓
BacktestResult { metrics, navCurve, trades, benchmarkCurve }
   ↓
ResultPreview 渲染 + 用户保存 → BacktestHistoryStore（Free ≤ 10, Pro ≤ 200）
```

### 4.4 Pro 后台同步（Phase 3）

```
BGAppRefreshTask（系统调度）或下拉刷新
   ↓
WidgetSyncService.syncIfPro()
   ├─ Entitlement.current == .pro?
   │     否 → 跳过
   ↓
PriceService.fetchRealtime(funds)         # 调 159.75.16.87
   ├─ 失败 → 退避，标 sync_failed，banner
   ↓
NAVService.recompute(account, intraday: true)
   ↓
WidgetsShared/SnapshotPayload 写 App Group
   ↓
WidgetCenter.shared.reloadAllTimelines()
```

**Free 路径**：用户手动下拉 → `PriceService.fetchRealtimeWithThrottle()`（每日 ≤ 50 次本地计数）→ 同上。

### 4.5 Widget 渲染

```
Widget Timeline Provider
   ↓
读 App Group: SnapshotPayload
   ↓
渲染（数据通路与旧 app 同；视觉用 BNTokens 重画）
```

Widget 永不直接调网络、不读 CoreData。它只读 App Group 里 App 写好的快照。

---

## 5. 跨切关注点

### 5.1 配置外化（解决旧 app 调试债 #1, #2, #3）

| 旧 app 散落处 | 新位置 | 类型 |
|---|---|---|
| `targetWeight=0.25` / `driftTolerance=0.08` / `weeklyMinimumContribution=1000` / `emergencyRepairWindowDays=90` / `negligibleDeviation=0.02` | `ios/Config/StrategyIntent.swift` | Codable，默认值在代码、Pro 可在 Settings 改 |
| 雷达权重 0.22/0.22/0.18/0.14/0.14/0.10 + 7 个打分函数阈值 | `ios/Config/RadarConfig.swift` + `docs/algorithms/radar.v1.md` | 默认值锁定，文档为准 |
| `navPrecision=4` / `navZeroTolerance=0.0001` | `ios/Algorithms/Constants.swift` | 编译期常量 |
| 再平衡阈值 `0.08` 多处 | `ios/Config/StrategyIntent.swift` | 同上 |

### 5.2 Free / Pro 分流

**单一开关**：`Entitlement.current` 由 StoreKit 推动。Phase 1 永远返回 `.free`。

**分流点**（仅这些位置 branch）：

| 模块 | Free | Pro |
|---|---|---|
| `PriceService.fetchRealtime` | 本地节流 ≤ 50/日 | 调 159.75.16.87，无限 |
| `WidgetSyncService.syncSchedule` | 不调度 | BGAppRefresh ≤ 5 min（交易时段）|
| `BacktestHistoryStore.maxCount` | 10 | 200 |
| `PortfolioService.maxAccounts` | 3 | 20 |
| `AppearanceSection` | 锁定默认 | 可调密度/填充/hue |
| 历史缓存范围 | 1y | 全量 |

**红线**：Algorithms 层完全相同。Free/Pro 拿到一样的 NAV/XIRR/雷达数字（PRD §4 红线）。

### 5.3 缓存

`CacheService` 是唯一缓存 facade：

- key: `"\(domain):\(account_id):\(version_hash)"`
- 失效：导入新数据 / 快照前移 / 配置改 → `CacheService.invalidate(domain:)`
- 实现：内存 LRU + 文件落地（在 `Caches/`，可被系统清）

**禁止**：在 ViewModel / Service 各自维护 dict 当缓存。旧 app 这条已计入调试债 #6。

### 5.4 错误处理

| 层 | 错误处理风格 |
|---|---|
| Algorithms | 纯函数；非法输入抛 `AlgorithmError`（precondition fail），不静默兜底 |
| Services | `Result<T, ServiceError>`，区分 `.dataMissing` / `.networkFailed` / `.entitlementRequired` / `.invariantViolated` |
| Features | `@Published var error: UserFacingError?`；UI 用 banner / sheet 展示 |

**禁止**：在 Service 里 `try?` 静默吞错。

### 5.5 时区与日期

全 App 统一 `Asia/Shanghai` 自然日（PRD §3 + json_import §Snapshot）。所有日期比较走 `BNCalendar`（一个工具枚举），禁止裸 `Date.now`。

---

## 6. 测试与 Golden Fixture

### 6.1 测试金字塔

```
       ┌──────────────┐
       │   UI snapshot │ optional, Phase 2+
       ├──────────────┤
       │  Service IT   │ in-memory CoreData
       ├──────────────┤
       │ Algorithm UT  │ ← golden fixture, 强制 CI
       └──────────────┘
```

### 6.2 Golden Fixture 流程（Phase 1 阻塞项，转载自 salvage_matrix）

```
docs/algorithms/golden_fixtures/<account_slug>/
├── input.json                # json_import.v1 格式
├── expected/
│   ├── nav_curve.csv         # date, nav, tag
│   ├── xirr.txt              # 单值
│   ├── metrics.json          # CAGR/Sharpe/Calmar/MaxDD
│   ├── radar_current.json    # 6 维 + 总分
│   ├── radar_lastweek.json
│   └── radar_lastmonth.json
└── source.md                 # Elvis 导出来源、日期
```

**CI 规则**：`AlgorithmsTests` 跑每个 fixture，diff > 0.01% → fail。触发 [AGENTS.md 红线 5](../../AGENTS.md#红线无例外)（algorithm drift）。

**起步**：1 个账户即可。

---

## 7. 设计 token → SwiftUI 映射

源：[bn-tokens.css](../design/project/lib/bn-tokens.css)。落点：`ios/DesignSystem/BNTokens.swift`。

**镜像规则**：

```swift
// AUTO-MIRRORED FROM docs/design/project/lib/bn-tokens.css
// 改这里时同步修改 css 文件并在 worklog 标 ## Design request
enum BNColor {
    static let bg        = Color(hex: 0x0B0B0D)  // --bn-bg
    static let up        = Color(hex: 0xF6465D)  // --bn-up    (红=涨，默认)
    static let down      = Color(hex: 0x2EBD85)  // --bn-down  (绿=跌，默认)
    static let accent    = Color(hex: 0xE3B15C)  // --bn-accent
    static let benchmark = Color(hex: 0x7A8AA8)  // --bn-benchmark
    // ...
}
```

**红绿翻转**：`@AppStorage("pnlColorInvert")` Bool；`BNColor.up`/`down` 返回 computed property 根据 flag 反转。

**Liquid Glass**：`BNGlassModifier` 用 `.regularMaterial` + 自定义 saturation/inner highlight 复刻 chat1 里"more native Liquid Glass"那一轮的效果。

---

## 8. 工程基础设施

| 项 | 决定 |
|---|---|
| 最低 iOS | iOS 26（与设计稿 Liquid Glass 对齐）|
| 包管理 | SwiftPM only。**不引入** CocoaPods / Carthage |
| 三方依赖 | 默认 0 个。AGENTS.md 红线 2。例外按 PRD §5 红线 2 走 |
| Bundle ID | App: `com.elvis.backtester-note` · Widgets: `com.elvis.backtester-note.widgets` |
| App Group | `group.com.elvis.backtester-note` |
| Xcode Scheme | 一个 App scheme + 一个 Widget scheme + 一个 Tests scheme |
| Concurrency | Swift Concurrency（async/await + actor）。Combine 仅用于 `@Published` 桥接 |
| Logging | `os.Logger`，不接三方 |
| Analytics | 本地 SQLite 埋点（PRD §8），永不接三方 |

---

## 9. 与契约 / 算法文档的引用矩阵

| 实现位置 | 必读契约/算法 | 状态 |
|---|---|---|
| `ios/Algorithms/NAV.swift` | `docs/algorithms/nav.v1.md` | ❌ 缺 |
| `ios/Algorithms/Radar/` | `docs/algorithms/radar.v1.md` | ❌ 缺 |
| `ios/Algorithms/Backtest/` | `docs/algorithms/backtest.v1.md` | ❌ 缺 |
| `ios/Config/StrategyIntent.swift` | `docs/algorithms/strategy_intent.v1.md` | ❌ 缺 |
| `ios/Networking/Endpoints.swift` | `docs/contracts/api.v1.md` | ❌ 缺（GPT 主笔）|
| `ios/Services/ImportService.swift` | `docs/contracts/json_import.v1.md` | ✅ 有 |
| `ios/Services/ImportService.swift`（旧 app 兼容）| `docs/contracts/legacy_fundmvp_mapping.md` | ❌ 缺（GPT 主笔）|
| `ios/DesignSystem/` | `docs/design/project/lib/bn-tokens.css` | ✅ 有 |
| `ios/` 整体迁移决策 | `docs/algorithms/salvage_matrix.md` | ✅ 有 |

**5 份缺的算法/契约文档是 Phase 1 进入实现前的硬阻塞项**。GPT 主笔，Opus 校验数字。

---

## 10. 与 PRD 阶段路线图的对齐

| PRD §9 阶段 | 本架构需要落地的东西 |
|---|---|
| **Phase 1 · 骨架** | App Shell + Holdings Feature + Settings + Algorithms（NAV/Radar/Metrics/XIRR）+ Persistence + ImportService + DesignSystem + Golden Fixture CI |
| **Phase 2 · 回测与 Widgets** | Backtest Feature + Algorithms/Backtest + WidgetsExt 三个 + WidgetSyncService（Free 路径）+ 快捷指令模板 |
| **Phase 3 · Pro 自动化** | StoreKit + Entitlement.pro 路径开通 + WidgetSyncService Pro 路径 + 退避/离线 |
| **Phase 4 · 上架** | 隐私清单、合规文案、TestFlight |
| **Phase 5 · 平台扩展** | Mac Catalyst 评估，Algorithms 层应已天然兼容 |

---

## 11. 仓库现状与待清理项

**已落档**：
- ✅ `AGENTS.md`（并行协作协议）
- ✅ `docs/prd/Backtester_Note_PRD_v2.md`
- ✅ `docs/algorithms/salvage_matrix.md`
- ✅ `docs/contracts/json_import.v1.md`
- ✅ `docs/design/`（设计稿 + chat 记录）

**冲突待裁定**：
- ⚠️ `docs/collaboration/AGENT_WORKFLOW.md` 是**旧**版（GPT=dev / Opus=review 轮转），与 AGENTS.md（Opus=iOS / GPT=backend 并行）**不一致**。建议：删除或改为指向 AGENTS.md 的 stub。等 Elvis 确认。

**Phase 0 工程债**（开干前必须做的事，按依赖顺序）：

1. `git add` + commit 当前 `AGENTS.md` + `docs/` 全量为 baseline（防闪退丢档）
2. 处理 §11 的 collaboration workflow 冲突
3. 补 salvage_matrix 工作的 worklog（按 AGENTS.md 规矩）
4. 补 5 份缺的算法/契约文档（GPT 主笔）+ 至少 1 个 golden fixture（Elvis 导出）
5. 建 Xcode 工程 + 上面 §3 的目录骨架（Opus）
6. 才能开始 Algorithms 层 port

---

## 12. Changelog

- v1 (2026-04-25) — 初版。整合 PRD v2 + salvage_matrix + json_import + design + AGENTS.md 为单一架构权威。
