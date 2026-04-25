# JSON Import Schema v1

> 契约文件。改动前看 [AGENTS.md · 会合点](../../AGENTS.md#会合点契约驱动)。
> 本 schema 是 App 与快捷指令 / 外部工具的唯一数据入口。
> **Additive-only**：永不删字段、永不改字段含义；新增需升 `schema` 版本号尾数。

---

## 顶层

```json
{
  "schema": "backtester-note/import/v1",
  "exported_at": "2026-04-25T00:00:00+08:00",
  "source": "user_manual | shortcut | legacy_fundmvp_export",
  "accounts": [ /* Account[] */ ]
}
```

- `schema` —— 固定 `backtester-note/import/v1`。未来改字段含义或删字段必须升 v2。
- `exported_at` —— ISO 8601 带时区。
- `source` —— 枚举。`legacy_fundmvp_export` 表示文件由旧 FundMVP 按本 schema 导出；不是旧 app 私有格式兼容模式。
- `accounts` —— 至少 1 个。

---

## Account

```json
{
  "account_id": "default",
  "display_name": "主账户",
  "currency": "CNY",
  "snapshots": [ /* Snapshot[] */ ],
  "flows":     [ /* Flow[] */ ]
}
```

**不变量**：
- 恰有一个 snapshot 的 `is_baseline: true`，且必须是 `snapshots[*].date` 中最早的一条。
- `flows` 可空。空数组代表"仅快照、无历史流水"——PRD §3.1 允许的路径。
- 同 `account_id` 多次导入时，App 端做合并：snapshot 按 date upsert；flow 按 `(date, code, type, amount, shares)` 去重。

---

## Snapshot

```json
{
  "date": "2024-01-01",
  "is_baseline": true,
  "note": "期初快照",
  "holdings": [
    {
      "code": "000001",
      "name": "华夏成长混合",
      "shares": 1234.5600,
      "value": 1500.00,
      "nav": 1.2150
    }
  ]
}
```

- `date` —— `YYYY-MM-DD`，时区用 Asia/Shanghai 自然日。
- `is_baseline` —— 恰一个 true；该 snapshot 的日期 = XIRR/持有收益的"起算参考日"但不是 XIRR 现金流点。
- `holdings[*].value` —— 人民币元，2 位小数；`shares` 4 位小数；`nav` 4 位小数。至少提供 `shares + value` 或 `shares + nav`。
- `note` —— 可选，用户自由文本。

### 快照前移（PRD §3.1 方案 B）

导入新 baseline 时：
1. 若导入后的 `is_baseline` 快照日期**早于**库内现有 baseline —— App 把库内 baseline 降级为 `is_baseline=false` 中间 checkpoint，新导入的成为 baseline，全曲线重算。
2. 若晚于或等于 —— 拒绝导入（或提示："baseline 只能向前移动"）。

---

## Flow

```json
{
  "date": "2024-02-15",
  "code": "000001",
  "type": "buy",
  "amount": 500.00,
  "shares": 400.1234,
  "fee": 0.60,
  "note": "定投"
}
```

- `type` 枚举：`buy` / `sell` / `dividend` / `transfer_in` / `transfer_out`
  - `buy` / `transfer_in`：`shares` 正，`amount` 正（出账）
  - `sell` / `transfer_out`：`shares` 正（表示卖出多少份），`amount` 正（入账）
  - `dividend`：`amount` 正（入账）；`shares` 为 0 表示现金分红、> 0 表示红利再投
- `fee` —— 可选，未提供按 0 处理
- `note` —— 可选

---

## 验证规则（App 导入时必须全跑）

| 规则 | 报错级别 |
|---|---|
| `schema` 匹配 `backtester-note/import/v1` | Fatal |
| `accounts` 非空 | Fatal |
| 每账户恰 1 个 `is_baseline` | Fatal |
| baseline 日期最早 | Fatal |
| 所有 snapshot/flow 日期可解析 | Fatal |
| 日期不在未来 | Warn（允许但提示）|
| `code` 非空字符串 | Fatal |
| flow `type` 在枚举内 | Fatal |
| flow 日期 ≥ baseline 日期 | Fatal |
| `value > 0`, `shares > 0`（holdings/买卖）| Fatal |
| 同 `(account_id, code, date, type)` 组合的 flow 无重复 | Warn |

**预览 UI 强制步骤**：
1. 显示将写入 / 更新 / 跳过的 snapshot、flow 条数
2. 如发生快照前移，显著提示旧 XIRR 基准日 → 新基准日、"曲线将重算"
3. 用户点"确认写入"才真落库。预览阶段不写任何持久化存储。

---

## 快捷指令模板

App 设置里提供可导出的快捷指令模板：
- 模板 A：手动输入一条 flow（表单 → 追加到 JSON → 导入）
- 模板 B：从券商邮件/短信解析（正则，用户可改）
- 模板 C：外部 API 抓净值 + 组装成 holdings 快照

模板文件放 `docs/contracts/shortcuts/`（GPT 起草 Phase 2 时落）。

---

## 与旧 app 的兼容

`source: legacy_fundmvp_export` 模式下，文件仍必须已经是 `backtester-note/import/v1` schema。新 app 不读取旧 FundMVP 私有 persistence 格式，也不做字段猜测映射。

Elvis 2026-04-25 裁定：迁移方向反过来做，旧 app 增加"导出为 Backtester Note JSON v1"能力；新 app 只维护一个干净导入器。

---

## Changelog

- `v1` — 初版。快照 + 继承流水，支持 baseline 前移。
- `v1.1` — 明确 `legacy_fundmvp_export` 不是旧私有格式兼容模式；旧 app 必须导出本 schema。
