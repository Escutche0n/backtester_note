# 2026-04-25 · be · drop-legacy-import-mapping

**Agent**: GPT
**Role**: Dev
**Scope**: 按 Elvis 裁定，废弃“新 app 兼容旧 app 私有格式”的迁移方案，改为旧 app 导出 `json_import.v1` 干净格式。

## What changed

- `docs/contracts/legacy_fundmvp_mapping.md`：从字段映射 stub 改为迁移策略文档，明确新 app 不做旧私有格式映射。
- `docs/contracts/json_import.v1.md`：明确 `source: legacy_fundmvp_export` 仍必须是 `backtester-note/import/v1` schema。
- `README.md`：更新旧 FundMVP 迁移缺口说明。
- `docs/architecture/overview.v1.md`：更新 Phase 1c 解锁条件和引用矩阵。

## Contract change

- 契约：`docs/contracts/json_import.v1.md` / `docs/contracts/legacy_fundmvp_mapping.md`
- 旧 → 新：
  - 旧：新 app 读取旧 app 私有导出格式，再映射成新 schema。
  - 新：旧 app 直接导出 `json_import.v1`，新 app 只认统一 schema。
- 影响面：
  - `ios/Services/ImportService.swift` 不需要 legacy auto-detect / field mapping 分支。
  - 旧 app 若要迁移真实数据，需要新增“导出为 Backtester Note JSON v1”功能。
  - Phase 1c 的新 app 导入器更简单、更可测。

## Algorithm drift

无。

## Questions for Elvis

无。本次是 Elvis 明确裁定。

## Next

- [ ] Opus 实现 ImportService 时只支持 `json_import.v1`。
- [ ] 如需真实账户迁移，另开旧 app 工作单元实现 JSON v1 exporter。
