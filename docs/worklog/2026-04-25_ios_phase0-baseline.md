# 2026-04-25 · ios · phase0-baseline

**Agent**: Opus
**Role**: Dev
**Scope**: 落 Phase 0 文档基线 —— salvage_matrix v1（追认）、architecture overview v1、清理 collaboration workflow 冲突。

## What changed

- 新增 `docs/algorithms/salvage_matrix.md`（**追认**）：旧 app 18 个模块的 port/rewrite 决策矩阵 + 调试债清单 + golden fixture 流程。上一 session 写完后未及落 worklog 即闪退，本次补登。
- 新增 `docs/architecture/overview.v1.md`：iOS 技术架构总览，整合 PRD v2 + salvage_matrix + json_import + 设计稿 + AGENTS.md 为单一架构权威。覆盖 5 层依赖、目录骨架、5 条数据流、跨切关注点、设计 token 桥、工程基础设施、与契约/算法文档的引用矩阵。
- 改写 `docs/collaboration/AGENT_WORKFLOW.md` 为 deprecated stub，指向 AGENTS.md。旧轮转协议（GPT=dev/Opus=review）与现行并行协议（Opus=iOS/GPT=backend）冲突，按 AGENTS.md 优先。
- `.gitignore` 加 `.DS_Store`。
- Phase 0 baseline commit：把 `AGENTS.md` + 整个 `docs/` 首次纳入版本控制。

## Contract change

不涉及现有契约。

`docs/architecture/overview.v1.md` 本身确立为新的"架构契约"，与 `docs/contracts/`、`docs/algorithms/` 同级，改动按 AGENTS.md 会合点流程走。已在 §0 写明。

## Algorithm drift

无（本次未触算法）。

## Review

- ⏳ 等 GPT review：
  - architecture §3 目录骨架 vs salvage_matrix 落点是否完全一致
  - architecture §9 引用矩阵列出的 5 份缺失文档（`nav.v1.md` / `radar.v1.md` / `backtest.v1.md` / `strategy_intent.v1.md` / `api.v1.md` + `legacy_fundmvp_mapping.md`）GPT 是否认可主笔分工
  - architecture §5.5 时区统一 `Asia/Shanghai`、§8 SwiftPM only / 零三方 / iOS 26 / Bundle ID 等工程默认值是否反对

## Conflict

无未决冲突。`docs/collaboration/AGENT_WORKFLOW.md` 已按 AGENTS.md 收敛为 stub。

## Questions for Elvis — 已答（2026-04-25）

1. ✅ **Bundle ID** = `com.chenyuefu.backtester-note`（Widgets `.widgets`、App Group `group.com.chenyuefu.backtester-note`）。架构 §8 已更新。
2. ✅ **最低 iOS = 16+**。Liquid Glass 改为渐进增强（iOS 16/17 fallback 静态 material；iOS 18+ 加 saturation；iOS 26+ 完整效果）。架构 §7 / §8 已更新。
3. ✅ **Golden Fixture**：不阻塞实现。改为 schema-first 两步走 —— synthetic fixture 由 Opus 在算法 port 时同步建（按 `json_import.v1` + 算法文档手工构造），real fixture 由 Elvis 自然时机后补。架构 §6.2 / salvage_matrix Golden Fixture 节已更新。
4. ✅ **App 名 = `回测手记`** 沿用。

## Ideas

- §5.4 错误处理建立 `BNErrorReporter` 单一入口，方便日后接 Sentry-like 自建上报（Pro-only）—— 不在本次做，记下。
- Algorithms 层裸跑能力可以另起一个 `tools/` 目录放命令行 fixture runner，方便 Elvis 在终端直接验数 —— 不在本次做。

## Next

- [ ] **GPT** 起草 5 份缺失算法/契约文档（按引用矩阵优先级）：`nav.v1.md` / `radar.v1.md` / `backtest.v1.md` / `strategy_intent.v1.md` / `api.v1.md` + `legacy_fundmvp_mapping.md`。
- [ ] **Opus** 与 #1 并行：建 Xcode 工程 + 架构 §3 目录骨架（Bundle ID `com.chenyuefu.backtester-note`，最低 iOS 16）。
- [ ] **Opus** 通读 `bn-tokens.css`，预编译成 `BNTokens.swift` 镜像草稿。
- [ ] **Opus** 算法 port 时同步建 synthetic golden fixture（schema-first）。
- [ ] **Elvis** 任意时机：导出 1 个真实账户 → `docs/algorithms/golden_fixtures/real/<account_slug>/`（不阻塞 Phase 1 启动，但 ship 前要补）。
