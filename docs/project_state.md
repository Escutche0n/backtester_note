# Backtester Note · Project State (v1)

> **三文件分工**：[PRD v2](prd/Backtester_Note_PRD_v2.md) = 做什么 ／ [ARCH overview.v1](architecture/overview.v1.md) = 怎么搭 ／ 本文 = 现在搭到哪儿、决议落在哪儿。
> **与 worklog 的关系**：`docs/worklog/` 是事件流水（每个 commit 一份）；本文是聚合视图（永远只有一份当前态）。两者冲突时 —— **以本文为准**，并把 worklog 的过时点视为当时快照。

---

## 0. 元信息

- 文件版本：v1
- 上次更新：2026-04-30
- 上次更新者：Claude（Phase 1d-3 review polish + Phase 1d-4 manual account entry）

---

## 1. Phase 进度总表

| Phase | 名称 | 状态 | 最近 commit | 负责 AI |
|---|---|---|---|---|
| **iOS** | | | | |
| 1a | Algorithms foundation（XIRR / NAV / Metrics / Radar / StrategyIntent + 10 单测） | ✅ done | `2a88ed8` + `7c8fb03` review | GPT 主笔 / Opus review |
| 1a-fix | P2-1 Radar.swift sustainabilityScore 删除 calendar 参数（强制 Asia/Shanghai）+ deterministic 回归测试 | ⏳ Codex 复审第二轮 | 本次 | Claude |
| 1b-1 | App Shell（xcodegen + 两 Tab + Widgets extension 占位） | ✅ done | `7743d4a` | Opus |
| 1b-2 | DesignSystem / BNTokens（color / typography / spacing token 层） | ✅ done | `3a38419` | Opus |
| 1b-3 | Holdings mock UI（用 token 画 Card / Chip / Row 第一片 + ambient gradient 落 RootView） | ✅ done + Claude review ✅ | `e12c8e8` + 本次 review fixup | GPT 主笔 / Claude review |
| 1b-4 | Settings sheet 壳 + 回测 Tab 第一屏 | ✅ done + Claude review ✅ | `2059310` + 本次 review fixup | GPT 主笔 / Claude review |
| 1b-visual | AppIcon + 纯色暗色面视觉微调（移除当前 UI gradient / Material） | ✅ done | 本次 | GPT（Elvis 指派） |
| 1b-visual-2 | 字体与底色微调（正文 bold system / 中文 PingFang fallback，数字 SF Mono 同族，底色 `#1E1E20`） | ✅ done | 本次 | GPT（Elvis 指派） |
| 1b-visual-3 | 背景 / 卡片颜色微调（页面纯黑，卡片 `rgb(28, 28, 30)`） | ✅ done | 本次 | GPT（Elvis 指派） |
| 1b-visual-4 | 基础 haptic（tap / selection / success）+ `MockLineChart` vertical gradient（Peak watch 风） | ⏳ 真机过手中 | 本次 | Claude（Elvis 指派） |
| 1c | ImportService（快捷指令 JSON 导入）+ 最小 PortfolioService persistence | ✅ done + Claude review ✅ | `868f9a0` + `1dd6268` fixup | GPT 主笔 / Claude review |
| 1d-local | 手动日净值录入 + 持久化 + NavCard 本地曲线 | ✅ 1d-3 done + Claude review polish ✅ | `610f591` → `f77c91a` review fixup | GPT 主笔 / Claude review |
| 1d-4 | 手动建 baseline 账户表单（绕开 JSON import 兜底入口） | ✅ done, Codex review pending | `cb2593c` | Claude |
| 1e | NAV / 雷达图渲染 | 待排 | — | Opus |
| 1f | Backtest 第一刀 | 待排 | — | Opus |
| 1g | Widgets 业务化（用 token） | 待排 | — | Opus |
| **Backend** | | | | |
| be-α | api.v1.1 落地（按后端 commit `926c912` 反推） | ✅ done | 后端仓 | GPT |
| be-β | Phase 3 Pro：Networking + `portfolio/history` 真实化（原 1d 推迟） | 🔜 Phase 3 | — | GPT |
| be-γ | 雷达 / 回测计算服务化 | 待排 | — | GPT |
| **Meta** | | | | |
| arch-§8 回填 | xcodegen / iOS 17.4 / Swift 6.0 / bundle id / targets 写进 ARCH §8（v1.3） | ✅ done | 本次 | GPT |

---

## 2. 决议簿（Decisions log）

> 时间倒序，一行一条：日期 · 决议 · 出处。这是散落在各 worklog 的"凡定不再翻"事项的聚合视图。新决议追加在表头。

- 2026-04-30 · Phase 1d-4 完成：补 Phase 1 漏掉的"手动建 baseline 账户"反向兜底入口。Settings → 持仓快照 进入表单录入账户名 / 基线日期 / 持仓行（代码 / 名称 / 份额 / 市值 / nav），表单产出 `backtester-note/import/v1` JSON Data 后走和 file import 完全一致的 `ImportService.preview → PortfolioService.commit` 路径——零校验逻辑重复、复用 baseline 前移语义。已建账户后整页切只读，编辑/追加流水留待后续。新增 6 个 ManualAccountEntryDraftTests，App 层测试 16 → 22 全绿。无契约 / 算法 / 权能改动 · 2026-04-29_ios_phase1d-4-manual-account-entry worklog
- 2026-04-30 · Phase 1d-3 review polish：NavCard `statusText` 从互斥 if/else if/else 改为可叠加（`含快照 · 缺净值 N 天 · 仅流水 N 天`），与 1d-3 worklog 描述一致；删 `AccountNAVSeries.flowOnlyDateKeys` 多余的 `.sorted()`（返回前已 sort）。22 cases 仍全绿 · `f77c91a` commit
- 2026-04-29 · Phase 1d-3 完成：新增账户级 `NAVService`，用 baseline snapshot / flows + 手动基金日净值组装 `NAVInput`，复用既有 `NAVCalculator`；`NavCard` 有真实账户时消费本地 NAV 曲线，缺日净值 / 仅流水 / snapshot-only 均显式提示，不再用 mock 掩盖已有账户缺数据；沪深300未接入前显示「基准待接入 / 超额待算」 · 2026-04-29_ios_phase1d-3-navcard-local-nav worklog
- 2026-04-29 · Phase 1d-2 完成：Settings → 数据维护新增「手动日净值」入口；基金代码从已导入持仓 / 流水 unique codes 抽取；支持日期 + 4 位 Decimal NAV 单条录入、同日覆盖、列表回填编辑、删除确认；`FundNAVService` 补 `delete(code:date:)` 并新增删除单测。未接入 NavCard / NAV 算法，1d-3 继续 · 2026-04-29_ios_phase1d-2-nav-maintenance-ui worklog
- 2026-04-29 · Phase 1d-1 review fixup：`fund_nav_minimal/fund_nav.v1.json` 改为与 `FundNAVService` 写盘一致的 code/date 升序；`expected.json` 重命名 `metadata.json` 避免误解为 round-trip output；补损坏 store 经显式允许后覆盖写入并清空 `loadError` 的测试 · 2026-04-29_ios_phase1d-1-fund-nav-store worklog `## Review`
- 2026-04-29 · Phase 1d-1 simulator 验证补跑：执行 `xcrun simctl shutdown all && xcrun simctl erase all` 后，`xcodebuild test` 成功进入 XCTest runner；`FundNAVServiceTests` 6 个 + `PortfolioServiceTests` 5 个全绿 · 2026-04-29_ios_phase1d-1-fund-nav-store worklog `## Verification`
- 2026-04-29 · Phase 1d 方向调整：原 “Networking + portfolio/history” 整组推到 Phase 3 Pro 自动化；1.0 收紧为纯本地 JSON 闭环。1d 重新定义为 `1d-local · 手动日净值录入 + 持久化`，本次 1d-1 只落数据层：`FundDailyNAVRecord` / `FundNAVStore` / `FundNAVService` / app unit tests / `fund_nav_minimal` golden fixture。NAV 本地存储使用 `Decimal` 并编码为 4 位字符串；后续算法层若继续按 `Double` 计算，在服务边界转换 · 2026-04-29_ios_phase1d-1-fund-nav-store worklog
- 2026-04-29 · Claude 关闭 Phase 1c review，✅ 通过。第一轮 ⚠️ 有条件通过提了 4 条必修（baseline 前移 UI 弹窗 / OverviewPanel 假 0 / flow type fallback / store load silent）+ 5 条 Ideas；GPT fixup `1dd6268` 4 条必修全闭合 + 收掉 3/5 Ideas（FileStore round-trip test / merge guard throw / baselineMoved TODO hook），剩两条合理留待后续（fixture README / `enabledOverviewGraphIDs` 升 enum）。`xcodebuild test` 模拟器环境问题不阻塞关闭 · 2026-04-29_ios_phase1c-portfolio-persistence worklog `## Review`
- 2026-04-29 · Phase 1c review fixup：补 baseline 前移 UI 二次确认；snapshot-only 无法计算指标改为 `待算` 而非 0；删除 flow type `.buy` fallback；本地 store load 失败保留 `loadError` 且默认拒绝覆盖；补 FileStore round-trip 与 load-error 测试。`xcodebuild build` / `build-for-testing` 通过；`xcodebuild test` 当前被 iPhone 17 / 17 Pro 模拟器 Busy/preflight 阻断 · 2026-04-29_ios_phase1c-portfolio-persistence worklog
- 2026-04-29 · Phase 1c 第二刀完成：`PortfolioService` + 本地 JSON store + JSON import “确认写入” + 持仓页 snapshot 真实数据第一刀。实现 baseline 只能前移不能后移，前移时旧 baseline 降级 checkpoint；flow 按 `(date, code, type, amount, shares)` 去重；本地 persistence 模型预留可选 `enabledOverviewGraphIDs` 承接后续 graph 用户自选裁定，但 1.0 默认 UI 行为仍按 PRD §7.2 9 指标 3×3；新增 3 个 app unit tests 与最小 synthetic fixture 入口 · 2026-04-29_ios_phase1c-portfolio-persistence worklog
- 2026-04-29 · Claude 完成 v1-scope-boundary review，✅ 通过。两条 ✅（准确反映 Elvis 裁定 / "8 graph 非桌面 Widget" 表述清晰）+ 1 处硬冲突挂起 Elvis（scope §7 "8 graph" vs PRD §7.2 "OverviewPanel 9 指标 3×3"，Elvis 口头倾向"用户自选不强制 3×3"但 PRD 冻结）+ 三处 gap 落 worklog Ideas（Golden fixture CI / 快照前移规则 / NAV 5 状态机）。本次 review 不动 PRD、不动 scope · 2026-04-26_ios_v1-scope-boundary worklog `## Review`
- 2026-04-26 · Elvis 裁定 1.0 上架范围：国内公募基金（按支付宝覆盖范围理解）、手动 JSON 导入、手动维护 4 位日净值、真实持仓、影子持仓、完整历史回测四模式（一直持有 / 定投 / 定期再平衡 / 阈值再平衡）、持仓页 8 个状态 graph。Pro 自动拉取 / 后台同步 / 云备份 / 桌面 WidgetKit 不进 1.0。8 个 graph 是 App 内持仓页组件，不是桌面 WidgetKit · docs/scope/v1_0_app_store_scope.md
- 2026-04-26 · 修复 1b-1 起 `BacktesterNote.entitlements` / `BacktesterNoteWidgets.entitlements` 一直是空 `<dict/>` 的回归 —— 把 §2 决议簿 2026-04-25 已冻结的 App Group `group.com.chenyuefu.backtester-note` 写回两个文件。⚠️ PERMISSION CHANGE 已在 worklog 标红；无新增权限维度。模拟器静默通过；真机 / 上架时这条若缺 widget snapshot 共享会 runtime 失败。Codex review 抓到的 · 2026-04-26_ios_restore-app-group-entitlement worklog
- 2026-04-26 · 引入 `BNHaptics`（tap / emphasis / success 三档）；所有 Picker / Toggle 走 `.sensoryFeedback(.selection, trigger:)`，所有 Button 走 `BNHaptics.tap()`，「开始回测」CTA 走 `success()`（Phase 1f 真实回测后改为提交=tap、回调=success/error）。`MockLineChart` stroke / fill 改 vertical LinearGradient（顶亮底淡，Peak watch 风），不动 PRD §7.1 红涨绿跌色规则 · 2026-04-26_ios_phase1b-visual-4-haptics-chart-gradient worklog
- 2026-04-26 · **产品北极星（new）**：「对照线 × 雷达」是 app 的核心差异化亮点 —— 雷达六维量化**行为质量**（执行程度 / 投资纪律 / …），对照线量化**行为代价**（实线 vs 影线的 ¥ / %）。两者配合回答用户最痛的问题："我的低分到底亏了我多少钱 / 假如我守纪律会多赚多少"。**功能取舍时此组合优先级最高**，其他 nice-to-have 让路。Phase 1h 不能跳过，但当前不抢节奏，细节（命名 / 锚点 / 现金流默认 / 费率）冻到 1f 临近再解冻 · 本次 session
- 2026-04-26 · 「对照线」（暂名，候选：对照线 / 应得净值 / 影子组合 / 假如坚持，待最终命名）确定为 `NavCard` 上的叠加图层（toggle + 锚点 picker 复用现有 1M/3M/6M/1Y），不开独立 tab。算法 = 反事实重放，复用 Phase 1f backtest 引擎；起点对齐到锚点日实线 NAV，差距完全归因于这段期间行为成本。**红线建议**：app 内禁出现「预测 / 收益预估」字样，统一限定到「过去 / 历史 / 假如」（监管口径）。Phase 排到 1f 之后（暂记 `Phase 1h: 对照线`），命名/默认锚点/现金流默认/费率四题待 Elvis 裁后写进 PRD §7.2 · 本次 session 讨论
- 2026-04-26 · IA 仍按 PRD §2 冻结的 2 tab 走，不升 5 tab / 不升 4 tab。空旷感等 1c 写入 + 1d 真实数据 + 对照线全落完再判断。若届时仍觉得少，**优先走「流水从设置齿轮升级为独立全屏 sheet」**（持仓页 `TotalHeader` 旁加 `list.bullet` 入口），不动 PRD §2；只有 sheet 方案憋住才考虑改 PRD 升 3 tab `持仓 / 流水 / 回测` · 本次 session 讨论
- 2026-04-26 · Claude 完成 1b-3 / 1b-4 review，✅ 通过；同 commit fixup 三处：`BacktestView` 「新建」按钮副作用 → no-op + TODO 1f；`RadarCard` 硬编码 delta → 算 snapshot；`HoldingsList` 死控件 Picker → `@State`。PRD §7.2 异常 banner / `MockRadarChart` 颜色 / mock series DRY 三项落 worklog Ideas，留下次 · 1b-3 / 1b-4 worklog `## Review`
- 2026-04-26 · Elvis 确认卡片底色为 `rgb(28,28,30)`，页面背景改纯黑；实现层将 `surface/surfaceElevated` 统一为 `#1C1C1E`，`background/backgroundElevated` 统一为 `#000000` · 2026-04-26_ios_background-card-color worklog
- 2026-04-26 · Elvis 要求中文用 PingFang SC、英文用 SF Pro Display Bold、数字用 SF Mono 同族、纯色底色改为 `#1E1E20`；实现层用 bold system font + Chinese fallback，数字走 system monospaced，并同步 AppIcon 底色 · 2026-04-26_ios_font-background-tuning worklog
- 2026-04-26 · Elvis 要求当前 iOS UI 从 Liquid Glass / ambient gradient 转向截图参考的纯色暗色面；实现层先移除 SwiftUI gradient / Material，并补 AppIcon。设计源 `docs/design/` 暂不动，后续如定稿再请 Claude Design 更新 · 2026-04-26_ios_solid-theme-app-icon worklog
- 2026-04-25 · Phase 1c 第一刀只做 `json_import.v1` 文件选择、解析校验与预览；确认写入暂禁用，Persistence / PortfolioService 下一刀接入 · 2026-04-25_ios_phase1c-import-preview worklog
- 2026-04-25 · Phase 1b-4 落地 Settings sheet 壳 + Backtest mock 第一屏；回测仍是 UI mock，不触发算法口径与后端契约 · 2026-04-25_ios_phase1b-4-settings-backtest-shell worklog
- 2026-04-25 · sustainability 月度分桶**强制 Asia/Shanghai**，`sustainabilityScore` API 删除 calendar 参数（不留默认值留口子）。产品定位决定 —— 国内基金工具按非 CN 时区看盘无意义 · radar.v1.md v1.2 / Radar.swift / Codex P2-1 二轮 review
- 2026-04-25 · Elvis 临时指派 GPT 接手 iOS Phase 1b-3；本次只做 Holdings mock UI，不提前实现 1b-4 Settings / Backtest · 2026-04-25_ios_phase1b-3-holdings-mock-ui worklog
- 2026-04-25 · 雷达三快照锚点：日历天（7/30）→ **交易日 5/22**；BNCalendar 不需要"往前推 N 交易日"，由 RadarService 层用 `RadarConfig.lastWeek/lastMonthTradingDayOffset` 处理 · radar.v1.md v1.1
- 2026-04-25 · 雷达六维窗口期：**差异化默认（180/90 混合）+ RadarConfig 字段进 Pro 可调**；明确拒绝"统一 90 天" · radar.v1.md §4.2 决议 (b)
- 2026-04-25 · sustainability 公式落地：4 子分 weighted（0.25/0.30/0.25/0.20）+ 8 个阈值字段，全部进 RadarConfig · radar.v1.md §3.6
- 2026-04-25 · 跳过 Light mode 适配（设计稿 dark-only），等真有需要再说 · 本 session
- 2026-04-25 · `.bn-root` ambient radial gradient 落到 RootView ZStack 底层（组件级），不进 token namespace · 本 session
- 2026-04-25 · 雷达六维色阶用 accent (`#E3B15C`) 单色 + 透明度梯度，留到雷达图 commit 落 token · 本 session
- 2026-04-25 · BNColors 直写 sRGB 常量，不进 Asset Catalog（避免 CSS 与 Asset Catalog 双权威） · phase1b-2 worklog
- 2026-04-25 · BNSpacing 五档 4/8/12/16/24（CSS 没显式声明，按 padding 实际值归纳） · phase1b-2 worklog
- 2026-04-25 · `.bn-glass` / `.bn-tabbar` 多层叠加 + inset highlight 不在 token 层翻译，留给组件级用 `Material + overlay(stroke) + shadow` 重组 · phase1b-2 worklog
- 2026-04-25 · NAV 数字用固定 size + `.monospacedDigit()`，禁止 Dynamic Type 撑变宽 · phase1b-2 worklog
- 2026-04-25 · xcodegen 产物 `BacktesterNote.xcodeproj` 不入库（每次 fresh clone 跑 `xcodegen generate`） · phase1b-1 worklog
- 2026-04-25 · Widgets target 在 commit B 就声明 + 占位源码（选 A，非"等业务再加"） · phase1b-1 worklog（Elvis 当面裁定）
- 2026-04-25 · iOS deployment target = 17.4 · be_min-ios-17-4 worklog
- 2026-04-25 · App bundle id `com.chenyuefu.backtester-note`，Widgets `.widgets`，App Group `group.com.chenyuefu.backtester-note` · phase1b-1 worklog
- 2026-04-25 · 单代码文件 ≤ 450 行（含注释，不含空行）；`docs/*.md` / `Package.swift` / `project.yml` / `Info.plist` 等配置数据文件豁免 · `800795b` (AGENTS.md §代码组织原则)
- 2026-04-25 · 提交闸门：单元未 commit 不开下一个；半成品禁止 · `5783a08` (AGENTS.md §工作单元原则)
- 2026-04-25 · XIRR 使用 365.0 天分母 · phase1a worklog
- 2026-04-25 · 雷达总分六维简单平均（非加权） · phase1a worklog
- 2026-04-25 · 策略执行子权重 0.22 / 0.22 / 0.18 / 0.14 / 0.14 / 0.10（仅用于 `strategyExecution` 子分） · phase1a worklog
- 2026-04-25 · 旧 iOS app 是参考而非迁移源；不直接 port 代码 · be_legacy-ios-reuse-assessment worklog

---

## 3. 红线状态

| # | 红线（[AGENTS.md](../AGENTS.md#红线无例外) §红线） | 当前 |
|---|---|---|
| 1 | PRD 不动 | ✅ |
| 2 | 不加三方 SDK / tracker / 网络请求 | ✅ |
| 3 | 不动权限声明（Info.plist / entitlements） | ✅ 仅 App Group（1b-1 漏写、本次回归修复 ⚠️ PERMISSION CHANGE 已标，无新增权能） |
| 4 | 商业决策停手 | — 暂无待决 |
| 5 | 算法漂移 | ✅ 无 drift（XIRR / 雷达 / NAV 数字未与旧 app 比对，等 1d/1e 接真实数据再核） |
| 6 | design 不动 | ✅ |

---

## 4. 当前未答 Questions for Elvis

> 只列**尚未裁定**的；裁定后挪到 §2 决议簿。

**待 Elvis 裁定（1d-4 手动建账延伸题）**：
- (Q1) 多账户范围：v1 是否就允许 2-3 个账户，还是先锁单账户、Pro 再放？1d-4 当前按"单账户优先"实现（已建 1 个账户后表单切只读）；PRD §3.1 未显式收口。
- (Q2) 编辑现有 baseline 入口：放在同一个 ManualAccountEntryView 加"编辑"模式（同 date 走 upsert / 不同 date 走 baselineMoved），还是只允许 JSON 导入修改？倾向前者（1d-5 候选），因为表单已在、边际成本低。

- **持仓页 graph 数量与"用户自选"路径**（2026-04-29 Claude review 升级）：scope §7 "8 graph" 与 PRD §7.2 冻结的 `OverviewPanel` "9 指标 3×3 网格" 冲突。Elvis 2026-04-29 口头倾向"可让用户自选 graph、不强制 3×3"。待裁定项：
  - (a) 直接改 PRD §7.2：`OverviewPanel` 改为"用户自选 N 项，默认 8"，3×3 网格降级为"默认布局"；或
  - (b) scope 注脚说明"以 PRD §7.2 9 指标 3×3 为准、用户自选作为 1.0 之后增量"，本期不动；或
  - (c) 其他路径（例如 1.0 锁定 8 项默认、用户自选作为 1.1 增量）。
  - 1c 已在本地 persistence 预留可选 `enabledOverviewGraphIDs` 字段承接"启用了哪些 graph、顺序"；Elvis 未裁定前默认行为仍按 PRD §7.2。

**待 Elvis 裁定（对照线 spec）**：
- 命名（对照线 / 应得净值 / 影子组合 / 假如坚持 / 其他）
- 默认锚点（1M / 3M / 6M / 1Y，建议 3M）
- 现金流默认模式（"假装继续定投" vs "纯净值走势 C=0"，建议前者）
- 再平衡费率（0 费率理想对照 vs 用户配置费率，建议 0）
- 本功能写进 PRD §7.2 的时机（现在草稿 vs 1f 临近时）

**已修复 / 待 Codex 复审**：
- ✅ P2-1 `Radar.swift` `sustainabilityScore` **删除 calendar 参数硬编码 BNCalendar.calendar**（Elvis 2026-04-25 决议升级方案，比原计划"改默认值"更彻底）；新增 `sustainabilityIsTimezoneStable` 确定性回归测试。详见 [radar-calendar-default-fix worklog](worklog/2026-04-25_ios_radar-calendar-default-fix.md)，radar.v1.md → v1.2，等 Codex 复审第二轮。
- ⏳ P2-2（流程）radar v1.1 worklog `## Review` 待显式填 ✅/🔧/⚠️ 关闭。P2-1 修完顺势可填。

---

## 5. 下一步

- **iOS（候选下一刀）**：
  - **1d-5（小）**：在同一表单基础上加"为当前账户追加流水"入口（buy/sell/dividend），日常增量也脱离 JSON 导入。
  - **1d-6（中）**：编辑/删除现有 baseline 与 holdings；处理"baseline 不能删"红线下的 explainable 错误。
  - **1e-1（大）**：基于本地 `AccountNAVSeries` 接 Overview / Radar 的第一批真实指标；不可算指标继续显示 `待算`，不得静默填 0。
  - 顺序待 Elvis 裁 §4 Q1/Q2 后定。
- **Backend（GPT）**：原 1d Networking + `portfolio/history` 真实化推到 Phase 3 Pro 自动化；1.0 local NAV 闭环期间不动后端 / 网络代码。
- **Meta**：ARCH §8 回填 ✅ 完成（v1.3）。雷达 v1.1 ✅ 完成。下一个 Meta 任务待 Opus 1b 全部落完时校对 ARCH §3 目录骨架"最终态" vs "已落地"差异。
- **Phase 1h（新增・暂排）对照线**：1f Backtest 引擎落地后启动。算法 = 反事实重放，UI = `NavCard` 叠加图层。**当前不开工、不催 Elvis 裁 §4 四题** —— 节奏优先于细枝末节；等 1f 进入 in-flight 状态再解冻这四题与 PRD §7.2 增补。Elvis 已确认对照线 × 雷达是北极星，到时不会被其他功能挤掉。
- **IA 复评观察点**：1c 写入 + 1d 真实数据 + 1h 对照线全落完后，复评持仓 tab 是否仍空旷。若是，先升级流水为独立 sheet（不改 PRD）；仍憋住才考虑 PRD §2 升 3 tab。

---

## 6. 维护规则

1. **每个 commit 收尾**的 AI（Opus 或 GPT）必须在**同一 commit** 里更新本文：§1 状态格、§2 新决议、§4 新问题、§5 下一步；§0 元信息行也同步。
2. **不重复维护 commit 链** —— `git log` 已是权威，本文不存 hash 表。§1 表里的"最近 commit"列只挂 phase 主 commit，不挂每个修补 commit。
3. **冲突仲裁**：worklog 与本文冲突 → 以本文为准（worklog 是当时快照）；本文与 PRD/ARCH 冲突 → 以 PRD/ARCH 为准（本文跟随）。
4. **不写过时叙述** —— 本文是当前态。已废弃的方案放进 worklog `## Ideas` 或决议簿（标"废弃"），不留在本文正文。
