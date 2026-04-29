# 2026-04-29 · ios · phase1c-portfolio-persistence

**Agent**: GPT
**Role**: Dev
**Scope**: Phase 1c 第二刀：最小 PortfolioService + 本地 JSON store + JSON import “确认写入” + 持仓页真实数据第一刀。

## What changed

- `ios/Services/Portfolio/`
  - 新增 `PortfolioAccount` / snapshot / holding / flow / preferences 模型。
  - 新增 `PortfolioFileStore`，先用本机 `Application Support/BacktesterNote/portfolio.v1.json` 作为最小持久化，不引入 CoreData 或三方依赖。
  - 新增 `PortfolioService.commit(_:)`，接 `ImportPreview` 写入本地账户。
- `ios/Features/Settings/ImportPreview/ImportPreviewView.swift`
  - “确认写入”按钮从 disabled 改为真实 commit。
  - 写入后显示新增 / 更新 / 跳过重复流水数量；发生快照前移时显示旧基准日 → 新基准日。
- `ios/App/RootTabView.swift`
  - 注入全局 `PortfolioService`。
- `ios/Features/Holdings/HoldingsView.swift`
  - 若已有导入账户，持仓页首屏优先读本地 snapshot 汇总；无数据时继续显示 mock。
  - 当前只做“真实数据第一刀”：总市值、持有收益、基金列表来自本地快照；NAV 曲线 / 雷达仍是 mock，等 1d/1e 接官方净值和算法服务。
- `ios/Services/Import/ImportService.swift`
  - 疑似重复流水 warning 的 key 对齐契约 `(date, code, type, amount, shares)`。
- `ios/project.yml` + `ios/Tests/BacktesterNoteAppTests/PortfolioServiceTests.swift`
  - 新增 app unit test target。
  - 覆盖确认写入、重复流水跳过、baseline 后移拒绝、baseline 前移时旧 baseline 降级为 checkpoint。
- `docs/algorithms/golden_fixtures/synthetic/portfolio_import_minimal/`
  - 新增一份最小 import fixture 与 expected commit 结果，作为后续 golden fixture CI 的固定入口之一。

## Contract change

无。未修改 `docs/contracts/*`；实现按现有 `json_import.v1` 与 PRD §3.1 / §3.2 预留。

说明：为 Elvis 未裁定的 “8 vs 9 graph + 用户自选” 预留了 `PortfolioPreferences.enabledOverviewGraphIDs: [String]?`。字段仅在本地 persistence 模型中可选存在；1.0 默认 UI 行为仍按 PRD §7.2 的 9 指标 3×3，不改默认行为。

## Algorithm drift

无。没有改 NAV / XIRR / 雷达 / 回测算法数字。

## Verification

工作目录 `ios/`：

```bash
swift test
xcodegen generate
xcodebuild -project BacktesterNote.xcodeproj -scheme BacktesterNote \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug build CODE_SIGNING_ALLOWED=NO
xcodebuild test -project BacktesterNote.xcodeproj -scheme BacktesterNote \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO
```

结果：
- `swift test`：13 个算法测试通过。
- `xcodebuild build`：通过。
- `xcodebuild test`：3 个 `PortfolioServiceTests` 通过。
- 手写代码文件行数均 ≤ 450。

## Review

✅ Claude review 关闭（2026-04-29，commit `1dd6268`）：

第一轮（commit `868f9a0`）⚠️ 有条件通过，提了 4 条必修 + 5 条 Ideas。GPT fixup `1dd6268` 把 4 条必修全部闭合 + 收掉 3/5 Ideas，剩两条（fixture README / `enabledOverviewGraphIDs` 升 enum）合理留待后续。

三个原自查点 ack：

- ✅ `PortfolioService.commit(_:)` baseline 前移 / 后移规则符合 PRD §3.1：service 层后移 throw / 前移降级旧 baseline；UI 层 `previewCommit` dry-run + `confirmationDialog` 文案与 PRD §3.1:75 字面一致（"XIRR 基准日将从 YYYY-MM-DD 改为 YYYY-MM-DD，历史 NAV 曲线会重算，是否继续？"）。
- ✅ `PortfolioPreferences.enabledOverviewGraphIDs: [String]?` 预留足够承接 Elvis 后续 8 vs 9 graph 三裁定路径，1.0 默认 UI 行为按 PRD §7.2 9 指标 3×3 走，schema 不需回头改。
- ✅ 持仓页真假分层清楚：`totalValue / unitNAV / holdPnl / holdPct` 走真实 snapshot；其余 9 字段 `Double?` + `"待算"` placeholder；NavCard / RadarCard 整卡保留 mock 结构清楚。

测试环境：`xcodebuild test` 被 iPhone 17 / 17 Pro 模拟器 SpringBoard Busy / preflight 阻断 — 环境问题不是代码问题（`build-for-testing` 通过即编译 OK），不阻塞关闭。下一刀开工前重启模拟器跑一次 confirm 即可。

### Claude review fixup（2026-04-29）

Claude 对 commit `868f9a0` 给出 ⚠️ 有条件通过；本 fixup 已处理：

- ✅ baseline 前移 UI 二次确认：新增 `PortfolioService.previewCommit(_:) -> PortfolioCommitPlan` dry-run，不写盘；`ImportPreviewView` 在 baseline 前移时弹确认文案：“XIRR 基准日将从 YYYY-MM-DD 改为 YYYY-MM-DD，历史 NAV 曲线会重算，是否继续？”
- ✅ `OverviewPanel` 假 0：将 snapshot-only 无法计算的当日盈亏 / XIRR / 超额 / 回撤 / 夏普 / 卡尔马 / 失衡等字段改为 optional，真实导入数据下显示 `待算`，不再静默显示 0。
- ✅ flow type fallback：删除 `PortfolioFlowType(rawValue:) ?? .buy`，改为 `ImportFlowType -> PortfolioFlowType` 的 exhaustive switch；未来新增 flow type 时编译器会要求同步处理。
- ✅ store load silent：`PortfolioService` 现在保留 `loadError`；加载失败时不静默当空账户，commit 默认拒绝覆盖，只有 UI 二次确认后才允许 `allowOverwriteAfterLoadFailure`。
- ✅ 额外收掉 Ideas 两条：补 `PortfolioFileStore` round-trip test；baseline 前移处加下游 NAV / 雷达 / 回测重算 TODO hook。

Fixup verification：

```bash
swift test
xcodebuild -project BacktesterNote.xcodeproj -scheme BacktesterNote \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug build CODE_SIGNING_ALLOWED=NO
xcodebuild build-for-testing -project BacktesterNote.xcodeproj -scheme BacktesterNote \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO
```

结果：
- `swift test`：13 个算法测试通过。
- `xcodebuild build`：通过。
- `xcodebuild build-for-testing`：通过，说明 app test target 编译通过。
- `xcodebuild test`：当前 iPhone 17 与 iPhone 17 Pro 模拟器均被 SpringBoard Busy / preflight failure 阻断，未能启动 test runner；不是 Swift 编译失败。

仍留 Ideas：

- `expected_commit.json` 里 `nav_credibility_states` 语义偏元信息，后续可拆 fixture README。
- Elvis 裁完 §4 graph 路径后，把 `enabledOverviewGraphIDs: [String]?` 升 `[OverviewGraphID]` enum。

## Conflict

无新增冲突。既有 scope §7 “8 graph” vs PRD §7.2 “9 指标 3×3” 仍挂在 `docs/project_state.md` §4，本文不解决、不改 PRD。

## Questions for Elvis

无新增。仍等待 `docs/project_state.md` §4 里 8 vs 9 graph + 用户自选路径裁定。

## Ideas

- 下一刀 1d 接官方净值后，把 `NAVCredibility` 从模型预留变成 `NAVService` 输出字段，并让 `NavCard` 图例显示当前范围混入的非 confirmed 状态。
- `PortfolioFileStore` 是 Phase 1c 最小实现；如果后续数据维护页需要复杂查询 / 删除 / 审计，再按 salvage matrix 切到 CoreData store。

## Next

- [ ] Review 本 worklog 与 PortfolioService。
- [ ] Phase 1d：Networking + portfolio/history 真实化前，先确认 Free 不调用自建后端、Pro 才走 `159.75.16.87`。
