# 2026-04-29 · ios · phase1d-4-manual-account-entry

**Agent**: Claude / Opus
**Role**: Dev
**Scope**: Phase 1d-4：补 Phase 1 漏掉的"手动建 baseline 账户"反向兜底入口。在 App 内提供表单录入持仓快照，绕开必须先写 JSON 再 import 的硬核路径，让无快捷指令经验的用户也能跑起来。无契约改动、无算法改动，表单产出同一份 v1 schema JSON 后走和 file import 完全一致的 `ImportService.preview → PortfolioService.commit` 路径。

## What changed

- `ios/Features/Settings/ManualAccountEntry/ManualAccountEntryDraft.swift`（新增）
  - `ManualAccountDraft` / `ManualHoldingDraft` —— 纯表单状态结构。
  - `makeImportJSONData(now:)` 把表单序列化成 `backtester-note/import/v1` JSON `Data`，字段顺序与 `docs/contracts/json_import.v1.md` 一致（snake_case、Asia/Shanghai 时区 ISO 8601 `exported_at`、`source: user_manual`）。
  - `DraftError` 枚举覆盖表单层面的轻校验（账户名、持仓行存在、份额 > 0、市值/nav 至少二选一），结构性校验（schema 是否匹配、baseline 是否最早等）继续由 `ImportService.validate` 兜底，零重复。
- `ios/Features/Settings/ManualAccountEntry/ManualAccountEntryView.swift`（新增）
  - List 表单：账户名、基线日期（默认今天）、货币（v1 锁 CNY）、备注、可增删的持仓行（代码 / 名称 / 份额 / 市值 / nav）。
  - 保存按钮 → 构造 JSON Data → `ImportService.preview` → `PortfolioService.commit`，成功弹"已保存"alert，点完成自动 dismiss 回设置页。
  - 已存在账户时整页切到 "已建账户" 只读视图，明确告知"当前版本仅支持首次建账，编辑/添加持仓走 JSON 导入或下一刀"。
- `ios/Features/Settings/SettingsSheet.swift`
  - 注入 `@EnvironmentObject portfolioService`（之前只有 `ImportPreviewView` 自己注入，外层没有用）。
  - 「账户」section 第一行从静态 `主账户 · elvis · 默认` 改成 NavigationLink → `ManualAccountEntryView`，副标题动态显示 `账户名 · baseline 日期`，未建账时显示「新建」。
  - 账户数量行用 `portfolioService.accounts.count` 真值替换硬编码 `1 / 3`。
- `ios/Tests/BacktesterNoteAppTests/ManualAccountEntryDraftTests.swift`（新增，6 cases）
  - 表单 → JSON → preview 可 commit。
  - 提交后落账户：displayName / baseline 日期 / 持仓代码集合 / 份额 / 市值都对得上。
  - 仅填 nav（缺 value）时 `PortfolioService.makeHolding` 自动算出 value。
  - 三条 reject 用例：空账户名、空 value+空 nav、份额非数字。

## Contract change

无。`docs/contracts/json_import.v1.md` 字段未改，仍是 v1。手动表单只是这个 schema 的另一条客户端入口，与 file import / 将来的 Shortcut 共用同一份契约。

## Algorithm drift

无。未触 `Sources/BacktesterNoteAlgorithms/`，未改 NAV / Radar / Backtest 任一算法。

## ⚠️ PERMISSION CHANGE

无。未动 entitlements、Info.plist、网络权能、后台模式、剪贴板、键盘扩展、URL Scheme 等任何 capability。

## Verification

工作目录 `ios/`：

```bash
swift test
xcodegen generate
xcodebuild build -project BacktesterNote.xcodeproj -scheme BacktesterNote \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO
xcodebuild build-for-testing -project BacktesterNote.xcodeproj -scheme BacktesterNote \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO
xcodebuild test -project BacktesterNote.xcodeproj -scheme BacktesterNote \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO
```

结果：
- `swift test`：13 个算法测试通过。
- `xcodebuild build`：通过。
- `xcodebuild build-for-testing`：通过。
- `xcodebuild test`：通过。
  - `FundNAVServiceTests`：7 tests passed。
  - `NAVServiceTests`：4 tests passed。
  - `PortfolioServiceTests`：5 tests passed。
  - `ManualAccountEntryDraftTests`：6 tests passed（新增）。
  - 合计 22 cases。
- 手写代码文件行数：`ManualAccountEntryDraft.swift` 159、`ManualAccountEntryView.swift` 226、`SettingsSheet.swift` 185、`ManualAccountEntryDraftTests.swift` 105，全部 ≤ 450。

## Review

待 Codex 复审。建议复审重点：
- 表单字段与 `json_import.v1.md` 是否字段一一对应、命名一致（不要让手动表单和未来快捷指令模板出现轻微 schema 漂移）。
- "已建账户即只读"这个保守决策是否符合 Phase 1 范围（替代方案：允许编辑 baseline，但语义复杂——同 date 走 upsert，不同 date 走 baselineMoved）。
- `ImportService.validate` 是否所有规则在表单走通后都会被覆盖（重复一遍：表单 → JSON → preview，preview 里的 fatal/warning 都会拒绝 commit）。

## Conflict

无新增。既有 scope §7 "8 graph" vs PRD §7.2 "9 指标 3×3" 仍挂 `docs/project_state.md` §4，不在本刀范围。

## Questions for Elvis

1. 多账户：当前限制只能建一个 baseline 账户，符合 PRD §3.1 "v1 单账户"吗？还是 v1 就支持 2-3 个账户？现版按"单账户优先"切。
2. 编辑现有 baseline：是放在 1d-5（同 sheet 加"编辑"模式），还是直接走 JSON 导入修改？倾向前者，因为表单已经在了，再加一个编辑分支边际成本低。

## Ideas

- 1d-5 候选：在同一表单基础上加"为当前账户追加一笔流水"入口（buy/sell/dividend），日常增量也能脱离 JSON 导入。
- 1d-6 候选：编辑/删除现有 baseline 与 holdings；触及"baseline 不能删"红线时给 explainable 错误。
- Phase 2 候选：把 `ManualAccountDraft.makeImportJSONData` 的字段对齐表抽成 `docs/contracts/shortcuts/manual_account.template.json`，作为 Shortcut 模板 A 的种子。
- 已建账户视图后续可以加 "导出当前 baseline 为 JSON"，作为 Shortcut 自动化的种子文件。

## Next

- [ ] Codex 复审本 worklog 与 1d-4 代码。
- [ ] 决定 Q1（多账户范围）/ Q2（编辑入口位置）后开 1d-5 或 1d-6。
- [ ] 真机验证（任意 Apple Developer 账号即可，无需 App Group capability，因为本刀不动持久化路径）：建账 → 在 Holdings 看到对应曲线（可能为"待录入"——还需先去 DataMaintenanceView 录基金日净值）。
