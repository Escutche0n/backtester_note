# 2026-04-29 · ios · phase1d-2-nav-maintenance-ui

**Agent**: GPT
**Role**: Dev
**Scope**: Phase 1d-2：Settings → 数据维护 → 单条手动日净值录入 UI。无网络、无算法改动。

## What changed

- `ios/Features/Settings/DataMaintenanceView.swift`
  - 新增「数据维护」页面，支持从已导入持仓 / 流水中抽取 unique 基金代码。
  - 表单支持基金代码、日期、4 位日净值输入；提交前拦截超过 4 位小数或无效 Decimal。
  - 已录入列表支持点按回填编辑，同基金同日保存会覆盖原记录。
  - 删除已录入日净值前弹确认；删除后写回 `fund_nav.v1.json`。
- `ios/Features/Settings/SettingsSheet.swift`
  - 「数据维护」section 新增「手动日净值」入口，进入 `DataMaintenanceView`。
- `ios/App/RootTabView.swift`
  - 注入 app 级 `FundNAVService`，与 `PortfolioService` 并列，不污染 Portfolio 层。
- `ios/Services/FundNAV/FundNAVService.swift`
  - 新增 `delete(code:date:) -> Bool`，按基金代码 + Asia/Shanghai 自然日删除单条记录。
  - 保持 load failure 默认拒绝覆盖；只有显式 `allowOverwriteAfterLoadFailure` 才能覆盖损坏 store。
- `ios/Tests/BacktesterNoteAppTests/FundNAVServiceTests.swift`
  - 新增删除测试，覆盖删除目标日期、保留其他日期、重复删除返回 `false`。

## Contract change

无。未修改 `docs/contracts/*`；本刀只消费 1d-1 本地 `FundNAVService`。

## Algorithm drift

无。未修改 NAV / XIRR / 雷达 / 回测算法实现与算法契约。

说明：UI 只录入基金日净值并持久化为 `Decimal` 4 位字符串；尚未把这些数据接入 `NavCard` 或账户 NAV 算法。

## Verification

工作目录 `ios/`：

```bash
swift test
xcodebuild build -project BacktesterNote.xcodeproj -scheme BacktesterNote \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO
xcodebuild build-for-testing -project BacktesterNote.xcodeproj -scheme BacktesterNote \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO
xcrun simctl shutdown all && xcrun simctl erase all && \
xcodebuild test -project BacktesterNote.xcodeproj -scheme BacktesterNote \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug CODE_SIGNING_ALLOWED=NO
```

结果：
- `swift test`：13 个算法测试通过。
- `xcodebuild build`：通过。
- `xcodebuild build-for-testing`：通过。
- 首次 `xcodebuild test` 仍遇到 iPhone 17 模拟器 `SpringBoard Busy / preflight`；清模拟器后重跑通过。
  - `FundNAVServiceTests`：7 tests passed。
  - `PortfolioServiceTests`：5 tests passed。
- 手写代码文件行数均 ≤ 450。

## Review

待 review。

## Conflict

无新增。既有 scope §7 “8 graph” vs PRD §7.2 “9 指标 3×3” 仍挂 `docs/project_state.md` §4，本文不解决、不改 PRD。

## Questions for Elvis

无新增。

## Ideas

- 1d-3 接 `NavCard` 时需要把手动基金净值序列与持仓 / 流水完整性合并，输出 PRD §3.2 的账户级 NAV 5 状态。
- 后续如果手动录入量变大，再考虑把 `FundNAVService` 同步文件 IO 挪到后台 actor。

## Next

- [ ] Review 本 worklog 与 1d-2 代码。
- [ ] Phase 1d-3：让 `NavCard` 消费手动基金日净值，缺失区间不能静默插值。
