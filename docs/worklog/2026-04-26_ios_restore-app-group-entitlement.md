# 2026-04-26 · ios · restore-app-group-entitlement

**Agent**: Claude / Opus
**Role**: Dev (Codex review fix)
**Scope**: 修复 1b-1 起两份 entitlement 一直是空 `<dict/>` 的回归 —— 把 App Group `group.com.chenyuefu.backtester-note` 写回 `BacktesterNote.entitlements` 与 `BacktesterNoteWidgets.entitlements`。

## ⚠️ PERMISSION CHANGE

按 AGENTS.md 红线 #3 标红。本次改动是**恢复**早已在 `project_state.md` §2 决议簿（2026-04-25 条目）冻结的 App Group 权能，不是新增；但出于代码层面这是 entitlement 文件的实质变更，故按规则标 `⚠️ PERMISSION CHANGE`。

| 文件 | 旧 | 新 |
|---|---|---|
| `ios/App/Entitlements/BacktesterNote.entitlements` | `<dict/>` | `com.apple.security.application-groups = [group.com.chenyuefu.backtester-note]` |
| `ios/App/Entitlements/BacktesterNoteWidgets.entitlements` | `<dict/>` | 同上 |

未引入任何**新**权限维度（无 push、无后台模式、无 keychain group、无网络客户端宣告等）；只补齐当时漏写的 App Group 一项。

## What changed

- `ios/App/Entitlements/BacktesterNote.entitlements`：补 `com.apple.security.application-groups` array。
- `ios/App/Entitlements/BacktesterNoteWidgets.entitlements`：补同一项，让 App + Widgets extension 在同一 App Group 下能共享 `UserDefaults(suiteName:)` / shared container —— 这是 Phase 1g Widgets 业务化的前置条件。

**未触动**：`docs/prd/`、`docs/design/`、`docs/contracts/`、`docs/algorithms/`、`Info.plist`、`project.yml`、任何源码。

## Contract change

无。

## Algorithm drift

无。

## Verification

```
$ xcodegen generate
Created project at /Users/elvischen/Developer/backtester_note/ios/BacktesterNote.xcodeproj

$ xcodebuild -project BacktesterNote.xcodeproj -scheme BacktesterNote \
    -destination 'platform=iOS Simulator,name=iPhone 17' \
    -configuration Debug build CODE_SIGNING_ALLOWED=NO
** BUILD SUCCEEDED **
```

模拟器 build 不验证签名，所以 entitlement 缺漏在模拟器是悄无声息的。**真机 / TestFlight / App Store 才会因为 entitlement 与 provisioning profile 不匹配而失败**。当前没真机签名流程，本次修是为 Phase 1g Widgets 业务化（写 shared container）和将来上架做的预防性修复。

## Review

⏳ 等 Codex 复审：
- App / Widgets 两个 entitlement 是否都补到位。
- 是否引入了任何**新**权限维度（应当是无）。

## Conflict

无。Codex 的发现完全成立，project_state §2 决议早就写明 App Group，是 1b-1 漏落。

## Questions for Elvis

无。本次纯回归修复，无产品决策待裁。

## Ideas

- 1g Widgets 业务化时，先在代码层 `UserDefaults(suiteName: "group.com.chenyuefu.backtester-note")` 验证 App Group 真的能读写共享 container；如果失败再回头查 provisioning profile。
- 上架前需要在 Apple Developer portal 注册同名 App Group 并把它绑到 App ID + Widgets App ID，本仓 entitlement 文件只是代码侧声明，不能替代 portal 配置。这步 Elvis 上架时手动做。

## Next

- [ ] Codex 复审本 commit。
- [ ] 等 Elvis 排到 1g Widgets 业务化时再实测 App Group 共享容器读写。
