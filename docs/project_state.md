# Backtester Note · Project State (v1)

> **三文件分工**：[PRD v2](prd/Backtester_Note_PRD_v2.md) = 做什么 ／ [ARCH overview.v1](architecture/overview.v1.md) = 怎么搭 ／ 本文 = 现在搭到哪儿、决议落在哪儿。
> **与 worklog 的关系**：`docs/worklog/` 是事件流水（每个 commit 一份）；本文是聚合视图（永远只有一份当前态）。两者冲突时 —— **以本文为准**，并把 worklog 的过时点视为当时快照。

---

## 0. 元信息

- 文件版本：v1
- 上次更新：2026-04-25
- 上次更新者：Opus（本文创建）

---

## 1. Phase 进度总表

| Phase | 名称 | 状态 | 最近 commit | 负责 AI |
|---|---|---|---|---|
| **iOS** | | | | |
| 1a | Algorithms foundation（XIRR / NAV / Metrics / Radar / StrategyIntent + 10 单测） | ✅ done | `2a88ed8` + `7c8fb03` review | GPT 主笔 / Opus review |
| 1b-1 | App Shell（xcodegen + 两 Tab + Widgets extension 占位） | ✅ done | `7743d4a` | Opus |
| 1b-2 | DesignSystem / BNTokens（color / typography / spacing token 层） | ✅ done | `3a38419` | Opus |
| 1b-3 | Holdings mock UI（用 token 画 Card / Chip / Row 第一片 + ambient gradient 落 RootView） | 🔜 next | — | Opus |
| 1b-4 | Settings sheet 壳 + 回测 Tab 第一屏 | 待排 | — | Opus |
| 1c | ImportService（快捷指令 JSON 导入） | 待排 | — | Opus |
| 1d | Networking + portfolio/history 接入 | 待排 | — | Opus |
| 1e | NAV / 雷达图渲染 | 待排 | — | Opus |
| 1f | Backtest 第一刀 | 待排 | — | Opus |
| 1g | Widgets 业务化（用 token） | 待排 | — | Opus |
| **Backend** | | | | |
| be-α | api.v1.1 落地（按后端 commit `926c912` 反推） | ✅ done | 后端仓 | GPT |
| be-β | `portfolio/history` 真实化（当前 mock） | 🔜 待排 | — | GPT |
| be-γ | 雷达 / 回测计算服务化 | 待排 | — | GPT |
| **Meta** | | | | |
| arch-§8 回填 | xcodegen / iOS 17.4 / bundle id 写进 ARCH §8 | 🔜 待排 | — | GPT |

---

## 2. 决议簿（Decisions log）

> 时间倒序，一行一条：日期 · 决议 · 出处。这是散落在各 worklog 的"凡定不再翻"事项的聚合视图。新决议追加在表头。

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
| 3 | 不动权限声明（Info.plist / entitlements） | ✅ 仅 App Group，无新增权能 |
| 4 | 商业决策停手 | — 暂无待决 |
| 5 | 算法漂移 | ✅ 无 drift（XIRR / 雷达 / NAV 数字未与旧 app 比对，等 1d/1e 接真实数据再核） |
| 6 | design 不动 | ✅ |

---

## 4. 当前未答 Questions for Elvis

> 只列**尚未裁定**的；裁定后挪到 §2 决议簿。

- （暂无 —— 本 session 三个 design questions 已全部裁定）
- 雷达窗口锚点是否改交易日（5/22）+ 六维窗口期是否统一 90 天 → 见 [docs/worklog/2026-04-25_radar-six-dimensions-review.md](worklog/2026-04-25_radar-six-dimensions-review.md)，等 GPT 也看一眼再定。

---

## 5. 下一步

- **iOS（Opus）**：commit D · Holdings mock UI（含 ambient gradient 落 RootView）
- **Backend（GPT）**：`portfolio/history` 真实化（待 GPT 自排时机）
- **Meta（GPT）**：ARCH §8 回填（xcodegen / 17.4 / bundle id 写进架构文档），与 commit D 互不阻塞

---

## 6. 维护规则

1. **每个 commit 收尾**的 AI（Opus 或 GPT）必须在**同一 commit** 里更新本文：§1 状态格、§2 新决议、§4 新问题、§5 下一步；§0 元信息行也同步。
2. **不重复维护 commit 链** —— `git log` 已是权威，本文不存 hash 表。§1 表里的"最近 commit"列只挂 phase 主 commit，不挂每个修补 commit。
3. **冲突仲裁**：worklog 与本文冲突 → 以本文为准（worklog 是当时快照）；本文与 PRD/ARCH 冲突 → 以 PRD/ARCH 为准（本文跟随）。
4. **不写过时叙述** —— 本文是当前态。已废弃的方案放进 worklog `## Ideas` 或决议簿（标"废弃"），不留在本文正文。
