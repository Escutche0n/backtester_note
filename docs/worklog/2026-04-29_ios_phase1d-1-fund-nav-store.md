# 2026-04-29 · ios · phase1d-1-fund-nav-store

**Agent**: GPT
**Role**: Dev
**Scope**: Phase 1d 方向调整后的第一刀：纯本地 Fund NAV 数据层 + 本地 JSON persistence + tests。无 UI、无网络。

## What changed

- Phase 1d 从原 `Networking + portfolio/history` 改为 `1d-local · 手动日净值录入 + 持久化`；原 Networking / Pro 后端接入整体推到 Phase 3。
- `ios/Services/FundNAV/`
  - 新增 `FundDailyNAVRecord { code, date, nav }`，按基金代码 + Asia/Shanghai 自然日做 account-agnostic 记录。
  - 新增 `FundNAVStore`，独立本地文件 `Application Support/BacktesterNote/fund_nav.v1.json`，不污染 `PortfolioService`。
  - 新增 `FundNAVService`，支持 upsert 单条净值、列出某基金全部净值、按日查询、查询某日前最近有效净值。
  - `FundNAVService` 通过 `FundNAVStoring` 注入 store，后续 UI / tests 可替换实现。
  - 用户录入的官方基金日净值在 fund-source 层输出 `FundNAVObservation.credibility = .confirmed`；账户级流水完整性检查由后续账户 `NAVService` 结合 holdings / flows 再决定是否降为 `.pendingReconcile`，没有新增第六状态。
- NAV 存储精度决策：
  - 本地 persistence 使用 `Decimal`，写 JSON 时编码为固定四位字符串，例如 `"4.1235"`。
  - 当前 `docs/algorithms/nav.v1.md` 与 `ios/Sources/BacktesterNoteAlgorithms/` 仍是 `Double` 计算入口；后续 1e/1f 如继续复用现有算法，建议在 service 边界把 `Decimal` 官方净值转成 `Double`，算法内部继续按 `navPrecision = 4` 每步 round，避免扩大本刀范围。
- `ios/Tests/BacktesterNoteAppTests/FundNAVServiceTests.swift`
  - 覆盖 upsert、同基金同日覆盖、4 位精度 JSON round-trip、Asia/Shanghai 日期键稳定、最近有效净值、损坏 store 默认拒绝覆盖。
- `docs/algorithms/golden_fixtures/synthetic/fund_nav_minimal/`
  - 新增最小 synthetic fixture，固定本地 `fund_nav.v1.json` 语义、4 位字符串、Asia/Shanghai 日期键。
- `docs/project_state.md`
  - §1 把 1d 重命名为 `1d-local · 手动日净值录入 + 持久化`。
  - §2 追加 1d 方向调整决议。
  - §5 下一步改为 1d-2 单条录入 UI；Networking / `portfolio/history` 标记为 Phase 3 Pro。

## Contract change

无。未修改 `docs/contracts/*`；`fund_nav.v1.json` 是本地 persistence 文件，不是 public import contract。

## Algorithm drift

无。未修改 NAV / XIRR / 雷达 / 回测算法实现与算法契约。

说明：本刀只定义官方基金日净值的持久化边界。NAV 计算仍按 `docs/algorithms/nav.v1.md` 的 `navPrecision = 4` 与 Asia/Shanghai date key 规则；没有拿新输出替换任何旧 app 数字结果。

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
```

结果：
- `swift test`：13 个算法测试通过。
- `xcodebuild build`：通过。
- `xcodebuild build-for-testing`：通过，含新增 app unit test target 编译。
- 开工前与收尾时各跑过 `xcodebuild test`，仍被 iPhone 17 模拟器 `SpringBoard Busy / preflight` 阻断，未进入 XCTest runner；与 1c 收尾现象一致，不是 Swift 编译失败。
- 手写代码文件行数均 ≤ 450。

## Review

Elvis review（2026-04-29）：⚠️ 有条件通过。

必修：
- `fund_nav_minimal/fund_nav.v1.json` 记录顺序与 `FundNAVService.sorted` 写盘顺序不一致，必须改成 code/date 升序，避免后续 round-trip diff 炸掉。

GPT fixup：
- ✅ `fund_nav.v1.json` 改成 `000001/2024-01-02` → `510300/2024-01-02` → `510300/2024-01-03`，与真实 store 输出顺序一致。
- ✅ `expected.json` 重命名为 `metadata.json`，README 明确它是 fixture invariant 元信息，不是 service round-trip expected output。
- ✅ 补 `allowOverwriteAfterLoadFailure: true` happy-path 测试：损坏文件经显式允许后能写入，并清空 `loadError`。

未处理 / 留 Ideas：
- `FundNAVService.defaultStore()` 初始化失败仍是 `fatalError`，与 `PortfolioService` 一致暂不扩本刀；未来 UI 层需要更完整错误恢复时可改 throwing init。
- 主线程同步 IO、`NumberFormatter` 格式化、删除 / 编辑 service API 留到 1d-2 / 后续数据量变大时处理。

## Conflict

无新增。既有 scope §7 “8 graph” vs PRD §7.2 “9 指标 3×3” 仍挂 `docs/project_state.md` §4，本文不解决、不改 PRD。

## Questions for Elvis

无新增。

## Ideas

- 1d-2 UI 层需要限制输入为 4 位小数；service 目前会按 schoolbook `.plain` round 到四位，UI 应在提交前把用户意图显示清楚。
- 1d-3 账户 `NAVService` 需要把 `FundNAVObservation.confirmed` 与账户流水完整性合并，输出 PRD §3.2 的账户级 `confirmed / pending_reconcile / snapshot_only / flow_only / intraday_estimate`。

## Next

- [ ] Review 本 worklog 与 1d-1 代码。
- [ ] Phase 1d-2：Settings → 数据维护 → 单条手动日净值录入 UI。
