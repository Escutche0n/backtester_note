# 2026-04-25 · ios · phase1b-1-app-shell

**Agent**: Opus
**Role**: Dev
**Scope**: Phase 1b-1 第一片：用 xcodegen 在 `ios/` 下生成 Xcode 工程，落最小 App Shell（两个空 Tab 占位）+ Widgets extension 占位 target，引用 Phase 1a SwiftPM package。

## What changed

- `ios/project.yml`：xcodegen spec。`name: BacktesterNote`，`bundleIdPrefix: com.chenyuefu`，`deploymentTarget.iOS: 17.4`，`SWIFT_VERSION: 6.0`。两个 target：
  - `BacktesterNote`（application）：sources `App/`，依赖本地 SwiftPM `BacktesterNoteAlgorithms`，bundle id `com.chenyuefu.backtester-note`，entitlements `App/Entitlements/BacktesterNote.entitlements`，`TARGETED_DEVICE_FAMILY=1`（iPhone only），`MARKETING_VERSION=0.1.0`，`DEVELOPMENT_TEAM` 留空待 Elvis 在 Xcode 填。
  - `BacktesterNoteWidgets`（app-extension）：sources `Widgets/`，bundle id `com.chenyuefu.backtester-note.widgets`，entitlements `App/Entitlements/BacktesterNoteWidgets.entitlements`。
  - 两个 scheme：`BacktesterNote`（构建 App + Widgets）+ `BacktesterNoteWidgets`。
- `ios/App/BacktesterNoteApp.swift`：`@main`，`WindowGroup { RootTabView() }`。
- `ios/App/RootTabView.swift`：`TabView`，两个 Tab：「持仓」`Text("持仓占位")` / 「回测」`Text("回测占位")`，`Label` + SF Symbol 图标。**未引入** DesignSystem / BNTokens（commit C 的事）。
- `ios/App/Info.plist`：最小 plist。`LSRequiresIPhoneOS=true`、`UILaunchScreen={}`、portrait only、`UIApplicationSceneManifest.UIApplicationSupportsMultipleScenes=false`。**未新增任何权限**（红线 3）。
- `ios/Widgets/Info.plist`：最小 plist + `NSExtension.NSExtensionPointIdentifier = com.apple.widgetkit-extension`。
- `ios/App/Entitlements/BacktesterNote.entitlements` + `ios/App/Entitlements/BacktesterNoteWidgets.entitlements`：仅 `com.apple.security.application-groups = ["group.com.chenyuefu.backtester-note"]`，无 keychain / iCloud / push / 其他权能。
- `ios/Widgets/BacktesterNoteWidgets.swift`：最小占位 `WidgetBundle`（`StaticConfiguration` + `Text("Placeholder")` + `.systemSmall`），仅为让 Widgets target 有源码可 build；不实现任何业务。
- `ios/.gitignore`：忽略 `BacktesterNote.xcodeproj/`、`*.xcworkspace/`、`.build/`、`.swiftpm/`、`xcuserdata/`、`DerivedData/`、`*.xcuserstate`、`*.xcuserdatad/`。xcodegen 产物不入库；任何人 clone 后 `cd ios && xcodegen generate` 即可生成工程。

**未触动**：`ios/Sources/` `ios/Tests/` `ios/Package.swift` `docs/contracts/` `docs/algorithms/` `docs/prd/` `docs/design/` `docs/architecture/`（全部按计划）。

## Contract change

无。

## Algorithm drift

无。

## Verification

实际命令与结果（工作目录 `ios/`）：

```
$ xcodegen generate
⚙️  Generating plists...
⚙️  Generating project...
⚙️  Writing project...
Created project at /Users/elvischen/Developer/backtester_note/ios/BacktesterNote.xcodeproj

$ xcodebuild -project BacktesterNote.xcodeproj -scheme BacktesterNote \
    -destination 'platform=iOS Simulator,name=iPhone 17' \
    -configuration Debug build CODE_SIGNING_ALLOWED=NO
... (App + Widgets extension 全部链接、嵌入)
** BUILD SUCCEEDED **

$ swift test
✔ Test run with 10 tests in 4 suites passed after 0.001 seconds.
```

环境：Xcode 26.4.1（17E202），iOS Simulator SDK `iPhoneSimulator26.4`，target triple `arm64-apple-ios17.4-simulator`，Swift 6.0。

模拟器目标改用 iPhone 17（计划里写的 iPhone 15 在本机 Xcode 26 上未默认安装；iPhone 17 是当前 available simulators 里第一个）。功能上不影响 Phase 1b-1。

**待 Elvis 人工确认**：在 Xcode 里打开 `ios/BacktesterNote.xcodeproj`，选 iPhone 17 模拟器 Run，应看到一个空 TabView，两个 Tab 文案分别为「持仓占位」「回测占位」。

## Review

- ⏳ 等 GPT review，重点：
  - Bundle ID（`com.chenyuefu.backtester-note` / `.widgets`）、App Group（`group.com.chenyuefu.backtester-note`）、`IPHONEOS_DEPLOYMENT_TARGET=17.4` 是否与 `docs/architecture/overview.v1.md` §8 一致。
  - Widgets extension 选 A（本 commit 就声明 + 占位源码）是否合理 —— Elvis 已裁定选 A。
  - SwiftPM 引用方式（`packages.BacktesterNoteAlgorithms.path: .` 指向 `ios/`，让 Xcode 拾取 `ios/Package.swift`）是否符合 Phase 1c ImportService / 后续 Holdings 数据维护的预期接入。

## Questions for Elvis

- `DEVELOPMENT_TEAM` 当前留空。真机签名前你需要在 Xcode → Signing & Capabilities 里填入你的 Apple Developer Team ID（模拟器 build 不需要）。这条不阻塞当前 commit。

## Ideas

- xcodegen 产物 `ios/BacktesterNote.xcodeproj` 不入库，意味着任何 fresh clone 必须先跑 `xcodegen generate`。后续可在 repo 根加 `make bootstrap` 或 `scripts/dev/setup.sh` 一键化（**不在本 commit 范围**）。

## Next

- [ ] GPT review 本 worklog。
- [ ] Opus 下一个 session：commit C — DesignSystem / BNTokens（按架构 §3 与 `docs/design/project/lib/bn-tokens.css`）。
- [ ] GPT 另起 commit：架构 v1.4 §8 回填（Xcode 顶层目录 = `ios/`、生成方式 = xcodegen），以及 commit B 已落地的具体决议。
