# 2026-04-26 · ios · v1-scope-boundary

**Agent**: GPT
**Role**: Dev
**Scope**: Elvis 裁定 1.0 上架范围后，新增独立 scope 文档记录边界；不修改 PRD。

## What changed

- `docs/scope/v1_0_app_store_scope.md`
  - 新增 1.0 上架范围边界。
  - 明确 1.0 是本地优先、手动数据、国内公募基金复盘工具。
  - 明确必须有 JSON 导入、手动 4 位净值、真实持仓、影子持仓、完整历史回测四模式、持仓页 8 个状态 graph。
  - 明确 8 个 graph 是 App 内持仓页组件，不是桌面 WidgetKit。
  - 明确 Pro 自动拉取、后台同步、云备份、桌面 WidgetKit 等不进 1.0。
- `docs/project_state.md`
  - 决议簿追加 1.0 scope 裁定。
  - 下一步仍指向 Phase 1c Persistence / PortfolioService。

**未触动**：`docs/prd/`、`docs/design/`、`docs/contracts/`、`docs/algorithms/`、iOS 代码、权限声明、网络代码。

## Contract change

无。本文只冻结产品范围，不改 API / JSON / 算法契约。

## Algorithm drift

无。未改算法代码。

## Verification

文档变更，无需 build。已确认未修改 `docs/prd/`。

## Review

⏳ 等另一方 review，重点看：

- 1.0 scope 是否准确反映 Elvis 的当前裁定。
- “8 个状态 graph 不是桌面 WidgetKit”是否足够明确。
- 是否与 PRD v2 冻结内容存在冲突。

## Conflict

无。

## Questions for Elvis

无。

## Ideas

- 若 Elvis 后续确认这就是正式 1.0 PRD，可由 Elvis 明确说“改 PRD”后再把本文合并进 `docs/prd/`。

## Next

- [ ] Phase 1c 下一刀：最小 Persistence / PortfolioService，接入“确认写入”。
