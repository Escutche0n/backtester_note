# Legacy FundMVP → json_import.v1 字段映射（STUB）

> ⚠️ **本文件是 stub**。
>
> 旧 app `/Users/elvischen/Developer/investment app/FundMVP/` 的 Persistence 导出格式与 [json_import.v1](json_import.v1.md) 的字段对齐表，待 GPT 反推旧 Persistence 实现后补完。
>
> 实现锚点：`ios/Services/ImportService.swift`（`source: legacy_fundmvp_export` 分支）

---

## 1. 目标

新 app 必须能读旧 app 导出的 JSON 并**自动 source-detect** 后映射到 `backtester-note/import/v1`。映射失败的字段**丢弃但记入导入日志**（不阻塞）。

---

## 2. 待 GPT 反推的源

旧 app 涉及导出的位置（已知）：

- `FundMVP/Persistence/HoldingFileStore.swift` — 持仓快照文件 store
- `FundMVP/Persistence/CoreDataPortfolioStore.swift` — Portfolio Core Data
- `FundMVP/Persistence/SIPPlanFileStore.swift` — 定投计划
- `FundMVP/Persistence/BacktestHistoryFileStore.swift` — 回测历史
- `FundMVP/Persistence/PersistenceController.swift:269-413` — 总入口

**GPT 任务**：
1. 通读上面 5 个 store
2. 找出实际写入磁盘的 JSON 结构
3. 在本文 §3 写完整字段对齐表
4. 在本文 §4 写"无法映射的字段"清单（决定丢弃 vs 升级 schema）

---

## 3. 字段对齐表（v1.1 GPT 补完）

### 3.1 持仓 / 流水

| 旧 app 字段 | 新 schema 字段 | 转换 |
|---|---|---|
| `HoldingTransaction.date` | `Flow.date` | TBD |
| `HoldingTransaction.type` | `Flow.type` | 旧 enum 待 GPT 列出 |
| `HoldingTransaction.amount` | `Flow.amount` | TBD |
| `HoldingPositionSnapshot.date` | `Snapshot.date` | TBD |
| ... | ... | TBD |

### 3.2 baseline 推导

新 schema 要求恰一个 `is_baseline=true`。旧 app **没有** baseline 概念。

**v1 决议**：导入旧数据时，**取最早的 snapshot 自动标 `is_baseline: true`**。如旧账户没有 snapshot 只有 flows，**第一笔 flow 之前一天造一个空 baseline**（holdings=[]）—— 这会让 NAV 段从首笔流水起算，与旧 app 行为一致。

GPT v1.1 验证此规则在所有旧账户上不破口径。

### 3.3 回测历史

旧 app 的 `BacktestHistoryFileStore` 与新 app 的 `ios/Persistence/BacktestHistoryStore.swift` 都是文件型，**不通过 json_import 走**。Phase 2 处理。

---

## 4. 无法映射的字段

待 GPT 反推后填。预期会有：

- 旧 app 的 widget config（不导入，新 app 重置）
- 旧 app 的 cache fingerprint（不导入，按数据重算）
- 旧 app 的 UI 偏好（不导入）

---

## 5. 测试

`AlgorithmsTests/ImportTests/LegacyFundMVPTests/`：

1. Elvis 在 [phase0 worklog Next](../worklog/2026-04-25_ios_phase0-baseline.md) 任意时机导出 1 个真实账户（旧 app 格式）→ `tests/fixtures/legacy/<account>/legacy_export.json`
2. ImportService 读 → 转 → 验证：
   - baseline 推导正确
   - 流水条数一致
   - 跑 NAV 算法 → 与旧 app 截图数字一致
3. 这一步同时**充当 real golden fixture 的入口**（一鸡两吃）

---

## 6. Changelog

- v1 stub (2026-04-25) — 仅声明任务。字段对齐待 GPT 反推旧 Persistence 后补完 v1.1。
