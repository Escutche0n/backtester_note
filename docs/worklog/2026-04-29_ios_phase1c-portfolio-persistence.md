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

⏳ 等另一方 review，重点看：

- `PortfolioService.commit(_:)` 的 baseline 前移 / 后移规则是否符合 PRD §3.1。
- `PortfolioPreferences.enabledOverviewGraphIDs` 作为可选预留是否足够承接 Elvis 后续 8 vs 9 graph 裁定。
- 持仓页“真实数据第一刀”是否清楚地区分 snapshot 汇总与仍未接入的 NAV / 雷达 mock。

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
