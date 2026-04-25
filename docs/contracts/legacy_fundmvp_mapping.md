# Legacy FundMVP → json_import.v1 迁移策略（DEPRECATED MAPPING）

> ⚠️ **本文件不再要求新 app 兼容旧 app 的内部导出格式**。
>
> Elvis 2026-04-25 裁定：不做“新 app 读取旧 app 私有格式再映射”的迁移方案。正确方案是反向改旧 app，使旧 app 直接导出 [json_import.v1](json_import.v1.md) 干净格式；新 app 只实现 `json_import.v1` 导入器。
>
> 实现锚点：
> - 新 app：`ios/Services/ImportService.swift` 只读取 `backtester-note/import/v1`
> - 旧 app：新增“导出为 Backtester Note JSON v1”能力（旧 app 仓库内实现）

---

## 1. 目标

新 app 的目标是只支持一个干净入口：

- `schema == "backtester-note/import/v1"`
- 结构完全遵守 [json_import.v1.md](json_import.v1.md)
- 导入前预览 + 用户确认 + 再落库

旧 app 如需迁移数据，必须先导出成该 schema。新 app 不承担旧私有 persistence 格式的自动探测、字段猜测和容错映射。

---

## 2. 旧 app 需要改的导出源

旧 app 涉及数据来源（已知）：

- `FundMVP/Persistence/HoldingFileStore.swift` — 持仓快照文件 store
- `FundMVP/Persistence/CoreDataPortfolioStore.swift` — Portfolio Core Data
- `FundMVP/Persistence/SIPPlanFileStore.swift` — 定投计划
- `FundMVP/Persistence/BacktestHistoryFileStore.swift` — 回测历史
- `FundMVP/Persistence/PersistenceController.swift:269-413` — 总入口

**旧 app 修改目标**：
1. 从上面 store 读取现有账户数据。
2. 在旧 app 内部转换为 `json_import.v1`。
3. 导出文件顶层必须是 `schema: "backtester-note/import/v1"`。
4. 新 app 只按 `json_import.v1` 验证和导入。

---

## 3. Baseline 生成规则

旧 app 如没有 baseline 概念，导出时在旧 app 侧生成 baseline：

- 有 snapshot：最早 snapshot 标 `is_baseline: true`。
- 没有 snapshot 只有 flows：第一笔 flow 前一天生成空 baseline（`holdings: []`）。
- 新 app 不做该推导；如果导入文件没有恰好一个 baseline，新 app 直接按 `json_import.v1` Fatal 拒绝。

## 4. 不迁移内容

旧 app 导出 `json_import.v1` 时默认不迁移：

- widget config（新 app 重设）
- cache fingerprint（新 app 按数据重算）
- UI 偏好（新 app 重设）
- 回测历史（Phase 2 另定是否迁移，不走 holdings import）

---

## 5. 测试

`ImportTests/JSONImportTests/`：

1. 旧 app 导出 `json_import.v1` 文件。
2. 新 app ImportService 只验证 `json_import.v1`：
   - schema 匹配
   - baseline 恰好一个
   - flows / snapshots 日期和数值规则合法
   - 预览结果正确
3. 导入后的真实账户文件可作为 real golden fixture 输入。

---

## 6. Changelog

- v1 stub (2026-04-25) — 原计划让新 app 读取旧 app 私有格式并映射。
- v1.1 (2026-04-25) — Elvis 裁定废弃 legacy mapping：旧 app 改为直接导出 `json_import.v1`，新 app 不兼容旧私有格式。
