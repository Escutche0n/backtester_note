# 2026-04-25 · be · handoff-opus-review-before-ios-skeleton

**Agent**: GPT
**Role**: Dev / Handoff
**Scope**: 在 Opus 开始 iOS 骨架与 UI 前，收口 GPT 当前职责边界、review 清单与剩余阻塞项。

## What changed

本 log 不新增代码，只做正式 handoff。

已推到 `origin/main` 的 GPT 相关提交：

- `d930f75` — `Document phase 0 algorithm contracts`
  - 新增 NAV / Radar / Backtest / StrategyIntent 算法契约。
  - 新增 API / legacy FundMVP mapping 契约 stub。
  - 更新架构 v1.2。
- `46ba465` — `Align project kickoff docs`
  - 修正 PRD 雷达权重口径：六维总分各 `1/6`，`0.22/.../0.10` 仅属于 `strategyExecution` 子分。
  - 确认 XIRR 统一 `365.0` 天。
  - 重写 repo README。
  - 把最低 iOS 调整到 `17.4+`。
- `2a88ed8` — `Start phase 1a algorithms package`
  - 新增 `ios/Package.swift` 与 `BacktesterNoteAlgorithms` SwiftPM package。
  - 实现 XIRR / NAV / Metrics / Radar 基础 / StrategyIntent。
  - 新增 10 个 Swift Testing 单测。

## Contract change

无新增契约变更。

当前契约状态：

- `docs/contracts/json_import.v1.md`：可供 Phase 1c 导入实现使用。
- `docs/contracts/api.v1.md`：已由 GPT 在后续 commit 补到 v1.1；`portfolio/history` 仍为 mock，不可生产使用。
- `docs/contracts/legacy_fundmvp_mapping.md`：仍是 stub，等待旧 app 导出 / 反推 Persistence 后补 v1.1。

## Algorithm drift

无新增 drift。已裁定口径：

- XIRR：统一 `365.0` 天，旧 HoldingsNAVCalculator 的 `31_556_926` 秒差异已由 Elvis 明确豁免。
- Radar：六维总分简单平均，每维 `1/6`。
- `0.22/0.22/0.18/0.14/0.14/0.10`：仅用于 `strategyExecution` 维度内部子分。

## Verification

- ✅ `swift test`（工作目录 `ios/`）通过。
- ✅ 当前 `main` 已推到 `origin/main`，本地没有未提交改动。

## Review

请 Opus 在开始 iOS 骨架 / UI 前先 review：

1. `docs/architecture/overview.v1.md`
   - Phase 1a / 1b / 1c 拆分是否适合 Opus 接下来建 Xcode 工程。
   - Xcode 工程顶层目录决议：继续 `ios/` SwiftPM + 后续 Xcode project，还是 Phase 1b 新建 `BacktesterNote/` 顶层工程目录。
2. `ios/Package.swift`
   - SwiftPM package 是否适合后续被 Xcode App target 引用。
   - `IPHONEOS_DEPLOYMENT_TARGET = 17.4` 是否应在 Xcode 工程创建时同步。
3. `ios/Sources/BacktesterNoteAlgorithms/`
   - `NAV.swift` ledger 字段是否够 Settings → 数据维护 / 对账页使用。
   - `Radar.swift` 当前只落总分、配置和部分子分，是否符合 Phase 1b mock UI 需要。
4. `ios/Tests/BacktesterNoteAlgorithmsTests/`
   - 当前 10 个内联单测是否足够作为 Phase 1a 第一片，下一步再补 synthetic fixture 文件。

Review 结论请追加到 `docs/worklog/2026-04-25_ios_phase1a-algorithms-foundation.md` 的 `## Review` 小节。

## Ownership boundary

按 Elvis 最新指示：

- **Opus 负责**：iOS 骨架与 UI（Phase 1b）、Xcode 工程、DesignSystem、Holdings mock UI、Settings 壳、Widgets target。
- **GPT 暂停触碰**：Phase 1b iOS 骨架 / UI 文件，除非 Elvis 临时重新指派。
- **GPT 后续负责**：synthetic fixtures、Backtest/Radar 口径补全、API contract v1.1、legacy mapping v1.1。

## Questions for Elvis

- 后端 GitHub URL 已提供：`https://github.com/Escutche0n/backtester-backend`。当前不阻塞 Opus 开 Phase 1b；后续 Pro API 对接前需处理 `portfolio/history` mock 与部署自动化。

## Next

- [ ] Opus review `2a88ed8` 与本 handoff。
- [ ] Opus 在 review 通过后开 Phase 1b：Xcode 工程 + App Shell + Holdings mock UI。
- [x] GPT 已按后端 GitHub URL 补 `api.v1.md` v1.1。
- [ ] GPT 在不碰 Phase 1b UI 的前提下，另开小单元补 synthetic fixtures。
