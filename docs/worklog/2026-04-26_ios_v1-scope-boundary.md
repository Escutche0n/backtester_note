# 2026-04-26 · ios · v1-scope-boundary

**Agent**: GPT
**Role**: Dev
**Scope**: Elvis 裁定 1.0 上架范围后，新增独立 scope 文档记录边界；不修改 PRD。

## What changed

- `docs/scope/v1_0_app_store_scope.md`
  - 新增 1.0 上架范围边界。
  - 明确 1.0 是本地优先、手动数据、国内公募基金复盘工具。
  - 明确必须有 JSON 导入、手动 4 位净值、真实持仓、影子持仓、完整历史回测四模式、持仓页 8 个状态 graph。
  - 明确 8 个 graph 是 App 内持仓页组件，不是桌面 WidgetKit。
  - 明确 Pro 自动拉取、后台同步、云备份、桌面 WidgetKit 等不进 1.0。
- `docs/project_state.md`
  - 决议簿追加 1.0 scope 裁定。
  - 下一步仍指向 Phase 1c Persistence / PortfolioService。

**未触动**：`docs/prd/`、`docs/design/`、`docs/contracts/`、`docs/algorithms/`、iOS 代码、权限声明、网络代码。

## Contract change

无。本文只冻结产品范围，不改 API / JSON / 算法契约。

## Algorithm drift

无。未改算法代码。

## Verification

文档变更，无需 build。已确认未修改 `docs/prd/`。

## Review

Claude review（2026-04-29）：

- ✅ **1.0 scope 准确反映 Elvis 2026-04-26 裁定**。scope §2~§8 八章逐项对得上 `project_state.md` §2 决议簿那条（国内公募 / 支付宝覆盖 / JSON 导入 / 4 位手动净值 / 真实持仓 / 影子持仓 / 四模式回测 / 8 graph / Pro & WidgetKit & 云备份不进 1.0），无遗漏。
- ✅ **"8 graph 不是桌面 WidgetKit" 表述足够明确**。scope §7 明说"App 内持仓页面的小状态组件，不是 iOS 桌面 WidgetKit"，§8 又把"桌面 WidgetKit 的 8 个系统小组件"列入不进 1.0，双重确认。
- ⚠️ **与 PRD §7.2 存在硬冲突**：PRD §7.2 冻结的是 `OverviewPanel` "9 指标 3×3 网格 + 失衡 mini-bar"，scope §7 列的是 8 项。Elvis 2026-04-29 口头补充倾向"可让用户自选 graph、不强制 3×3"，软化了冲突但未消除（PRD 仍冻 9 指标 3×3）。已按 scope §0 自己设定的冲突规则升级到 `project_state.md` §4 挂起，等 Elvis 显式裁定是否改 PRD §7.2。本次 review **不动 PRD**。
- 🟡 三处 gap 落本工作日志 `## Ideas`，留给后续 1c / 1d 自己看：
  1. scope 没提 PRD §9 Phase 1 的 Golden fixture CI（1.0 上架前防算法漂移 > 0.01% 的红线门槛）。
  2. scope §4 没复述 PRD §3.1 快照前移规则（"只能前移不能后移" + 弹确认）。
  3. scope §3.2 没指向 PRD §3.2 冻结的 NAV 5 状态机（confirmed / pending_reconcile / intraday_estimate / snapshot_only / flow_only），而 graph 颜色 / 透明度规则正是从这条来。

整体 ✅ 通过，仅一项硬冲突挂起 Elvis；scope 文档不改、PRD 不动。

## Conflict

- ⚠️ scope §7 "8 个状态 graph" vs PRD §7.2 `OverviewPanel` "9 指标 3×3 网格"。Elvis 倾向"用户自选、不强制 3×3"，但 PRD 冻结，需 Elvis 显式说"改 PRD §7.2"才生效。已挂起到 `project_state.md` §4。

## Questions for Elvis

- 8 vs 9 + 用户自选 graph 的 PRD §7.2 修订路径：是直接改 PRD §7.2（OverviewPanel 改成"用户自选 N≤?，默认 8"），还是在 scope 注脚说明"以 PRD §7.2 9 指标 3×3 为准、用户自选作为 1.0 之后增量"？

## Ideas

- 若 Elvis 后续确认这就是正式 1.0 PRD，可由 Elvis 明确说"改 PRD"后再把本文合并进 `docs/prd/`。
- **Gap 1**（Golden fixture CI）：1c 接入真实数据前，按 PRD §9 Phase 1 要求建一份 fixture（旧 app 真实账户的 NAV / XIRR / 雷达期望值），CI 比对 > 0.01% 视为漂移。落地时机建议在 1c persistence + 1d networking 之间，趁还没接 mock-out 真实数据前。
- **Gap 2**（快照前移规则）：1c persistence 写 PortfolioService 时要把 PRD §3.1 "快照只能前移不能后移 + UI 弹确认"实装到 API 层，禁掉 delete-baseline 这条路径。
- **Gap 3**（NAV 5 状态机）：8 graph 落 UI 时颜色 / 透明度 / "⚠ 待对账"标签都从 PRD §3.2 5 状态来；当前 mock UI 还没体现状态机，等 1d 接真实数据时一刀做。
- 若 Elvis 最终裁定 graph "用户自选"，需要新增一份持久化项（用户偏好"启用了哪些 graph、顺序"）—— 这条直接影响 1c persistence 的 schema 设计，越早裁越好。

## Next

- [ ] Phase 1c 下一刀：最小 Persistence / PortfolioService，接入“确认写入”。
