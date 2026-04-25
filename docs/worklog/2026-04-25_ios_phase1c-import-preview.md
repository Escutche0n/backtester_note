# 2026-04-25 · ios · phase1c-import-preview

**Agent**: GPT
**Role**: Dev
**Scope**: Elvis 指派进入 Phase 1c 第一刀：实现 `json_import.v1` 文件选择、解析校验与导入预览；本刀不写持久化存储。

## What changed

- `ios/Services/Import/ImportModels.swift`
  - 新增 `json_import.v1` 对应 Codable 模型：document / account / snapshot / holding / flow。
  - 新增 `ImportPreview`、`ImportIssue`、`ImportAccountSummary`，用于预览 UI 展示 fatal / warning / counts。
  - 日期解析统一使用 Asia/Shanghai 自然日；避免共享 `DateFormatter` / `ISO8601DateFormatter` 以通过 Swift 6 strict concurrency。
- `ios/Services/Import/ImportService.swift`
  - 新增 `ImportService.preview(data:)`。
  - 校验 `schema`、accounts 非空、baseline 恰 1 个且最早、flow 不早于 baseline、未来日期 warn、code 非空、flow type enum、holding / flow 数值规则、疑似重复流水 warn。
- `ios/Features/Settings/SettingsSheet.swift`
  - `快捷指令 & JSON 导入` section 新增“选择 JSON 文件”入口。
  - 使用 iOS `fileImporter` 选择 `.json` / `.plainText` 文件，读取后调用 `ImportService.preview(data:)`。
- `ios/Features/Settings/ImportPreview/ImportPreviewView.swift`
  - 新增导入预览页，显示状态、账户数、snapshot / flow 数、fatal / warning、每账户摘要。
  - “确认写入”按钮暂时 disabled，并注明 Persistence 待后续接入，符合契约“预览阶段不写持久化”。
- `ios/project.yml`
  - `BacktesterNote` target sources 新增 `Services`。

**未触动**：`docs/contracts/`、`docs/prd/`、`docs/design/`、算法口径、权限声明、网络代码、Widgets 业务代码。

## Contract change

无。实现按现有 `docs/contracts/json_import.v1.md`，未改契约字段或含义。

## Algorithm drift

无。只做 JSON 导入预览与校验，不改 NAV / XIRR / 雷达 / 回测算法。

## Verification

工作目录 `ios/`：

```
$ xcodegen generate
Created project at /Users/elvischen/Developer/backtester_note/ios/BacktesterNote.xcodeproj

$ swift test
✔ Test run with 13 tests in 4 suites passed after 0.001 seconds.

$ xcodebuild -project BacktesterNote.xcodeproj -scheme BacktesterNote \
    -destination 'platform=iOS Simulator,name=iPhone 17' \
    -configuration Debug build CODE_SIGNING_ALLOWED=NO
** BUILD SUCCEEDED **
```

代码文件行数已核对，新增最大文件 `ImportService.swift` 207 行；所有手写代码文件均 ≤ 450 行。

## Review

⏳ 等另一方 review，重点看：

- `ImportService.preview(data:)` 是否覆盖 `json_import.v1` 表里的 fatal / warn 规则。
- 预览 UI 是否明确“不写入持久化”，避免用户误以为已经导入成功。
- `SettingsSheet` 里的 fileImporter 是否是 Phase 1c 合适入口。

## Conflict

无。

## Questions for Elvis

无。

## Ideas

- 下一刀可以做 `PortfolioService` + 本地 store 的最小落库，或者先补 `ImportService` 的 app-level unit tests（当前 repo 只有 SwiftPM algorithms tests，没有 app target tests）。
- 快照前移当前只能在 preview 中支持“文件内 baseline 校验”；与库内现有 baseline 的旧→新对比要等 Persistence / PortfolioService 有真实账户后接入。

## Next

- [ ] Review 本 worklog 与 ImportService。
- [ ] Phase 1c 下一刀：最小 Persistence / PortfolioService commit，接入“确认写入”。
