# 2026-04-25 · be · arch-section-8-backfill

**Agent**: GPT
**Role**: Dev
**Scope**: 把 ARCH §8 里挂着的"Xcode 工程顶层目录决议"等参数按 [`ios/project.yml`](../../ios/project.yml) 实际落地参数回填，并对 [`2026-04-25_radar-six-dimensions-review.md`](2026-04-25_radar-six-dimensions-review.md) 给出 GPT 意见。属于 [project_state.md §5](../project_state.md) 列出的"Meta（GPT）：ARCH §8 回填"那一刀，与 Opus 的 commit D（Holdings mock UI）互不阻塞。

## What changed

### `docs/architecture/overview.v1.md` §8

回填表格（v1.3 changelog 已补）：

- **Xcode 工程顶层目录**：从"待 Phase 1b 决议" → 决议 `ios/`（硬扛，不顺 Xcode 默认 `BacktesterNote/`）
- **Swift 版本**：新增一行 6.0 + `SWIFT_STRICT_CONCURRENCY=complete`
- **包管理**：补充"算法层用本地 SwiftPM package（`BacktesterNoteAlgorithms`），由 App / Widgets / Tests 共享"
- **Bundle ID**：注明实际来源是 `ios/project.yml` 的 `bundleIdPrefix: com.chenyuefu`
- **Xcode 工程生成**：新增一行说明 xcodegen + `.xcodeproj` 不入库 + 重生成命令
- **Targets / Schemes**：明列四 target 命名

### `docs/worklog/2026-04-25_radar-six-dimensions-review.md`

加 `## Review (GPT, 2026-04-25)` 小节，对 Opus 提的两个雷达问题给意见：
- **判断 1（5/22 交易日锚点）**：✅ 赞成改，但 Opus 落实时必须先确认旧 app 口径，避免触红线 5
- **判断 2（统一 90 天）**：⚠️ 反对硬切 90 天，倾向"默认差异化 + RadarConfig 字段暴露给 Pro 可调"

## Contract change

ARCH §8 回填**不动主结构**，只是把待决议项按实际落地参数填好。改动按 [AGENTS.md 会合点](../../AGENTS.md) 流程算契约改动，但因为是单向回填（追认 Opus phase1b-1 已落事实，不引入新决策），无需 @ Opus 二次确认。

## Algorithm drift

无（本次未触算法）。

雷达 worklog 我提了一句：判断 1 落地时，Opus 必须先看旧 [HoldingsHomeFeature.swift](file:///Users/elvischen/Developer/investment%20app/FundMVP/Views/Holdings/HoldingsHomeFeature.swift) 怎么算 anchor，如果旧 app 用日历天 → 与新 app 的"5/22 交易日"差就是 drift，要走 `## Algorithm drift` 流程。这是预防性 flag，不是当前 drift。

## Review

- ⏳ 等 Opus review：ARCH §8 表里"Xcode 工程顶层目录 = `ios/` 硬扛"是否你的本意，命名表（targets / schemes）是否完整。
- ⏳ 等 Elvis 裁定：雷达两个判断（5/22 交易日锚点 / 90 天统一窗口）。

## Conflict

无。

## Questions for Elvis

1. **雷达三快照锚点改交易日（5/22）**：✅ 还是保持日历天？
2. **六维窗口期**：(a) 统一 90 天（你最初的倾向）；(b) 差异化默认 + RadarConfig Pro 可调（GPT 倾向）。

## Ideas

- ARCH §3 目录骨架（"最终态"）画的是 `ios/Algorithms/...` `ios/Features/...` 这套结构；Opus 实际用的是 `ios/Sources/BacktesterNoteAlgorithms/...` + `ios/App/` + `ios/DesignSystem/`。两者**没有矛盾**（最终态是远期目标），但等 Phase 1b 全部落完时建议 Opus 校对一次 §3，把"最终态"和"已落地"区分开。本次不动。

## Next

- [ ] **Elvis** 答 ## Questions for Elvis 两条
- [ ] **Opus** review ARCH §8 v1.3
- [ ] **Opus**（Elvis 答完后）落实雷达锚点改造 → 改 [`radar.v1.md`](../algorithms/radar.v1.md) §2、`BNCalendar` 加 `addingTradingDays(_:)`、重算未来 fixture
- [ ] **GPT** 等 Opus 1b-3 完成 → 准备做 Backend `portfolio/history` 真实化（[project_state.md §5](../project_state.md)）
