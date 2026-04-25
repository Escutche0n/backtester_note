# 2026-04-25 · be · prd-readme-alignment

**Agent**: GPT
**Role**: Dev
**Scope**: 按 Elvis 裁定修正 PRD 雷达权重口径，并重写 repo README 作为正式开工入口。

## What changed

- `docs/prd/Backtester_Note_PRD_v2.md`：修正 §3.4 雷达权重，明确六维总分各 `1/6`，`0.22/0.22/0.18/0.14/0.14/0.10` 仅属于 `strategyExecution` 内部子分。
- `docs/prd/Backtester_Note_PRD_v2.md`：按 Elvis 要求写明修改记录：2026-04-25 09:19 CST，由 GPT 修改。
- `docs/algorithms/nav.v1.md`：把 XIRR `365.0` 天从“待裁定提案”更新为 Elvis 已确认决议。
- `docs/algorithms/radar.v1.md`：把雷达简单平均从“待裁定提案”更新为 Elvis 已确认决议。
- `docs/architecture/overview.v1.md`：同步雷达权重描述与 Phase 1a 解锁条件。
- `docs/worklog/2026-04-25_be_review-arch-and-algo-docs.md`：回填 Elvis 对 XIRR / Radar 两处 drift 的裁定结果。
- `README.md`：重写为项目入口，覆盖当前阶段、必读文档、目录所有权、已裁定口径、待补项与下一步入口。

## Contract change

无 `docs/contracts/` 字段变更。

## Algorithm drift

- XIRR：Elvis 确认统一 `365.0` 天，旧 HoldingsNAVCalculator 的 `31_556_926` 秒差异明确豁免红线 5。
- Radar：Elvis 确认六维总分简单平均（每维 `1/6`），PRD v2 旧文案中的 `0.22/.../0.10` 仅保留为策略执行维度内部子分权重。

## Questions for Elvis

- 后端 GitHub URL 仍待提供，用于补完 `docs/contracts/api.v1.md` v1.1。

## Next

- [ ] Opus 可按 Phase 1a 开始 Algorithms port + synthetic fixture。
- [ ] GPT 待后端 GitHub URL 后补 `api.v1.md` v1.1。
