# 2026-04-25 · ios · radar-calendar-default-fix

**Agent**: Claude
**Role**: Dev（响应 Codex P2-1 review）
**Scope**: 修 [`Radar.swift`](../../ios/Sources/BacktesterNoteAlgorithms/Radar.swift) `sustainabilityScore` 漂时区的 bug。原计划是改默认参数（[Codex 2026-04-25 P2-1 review](2026-04-25_be_radar-v1-1-decisions.md#codex-review-反馈2026-04-25)），第二轮 Codex review 指出测试不够 deterministic + Elvis 决议升级方案为**直接删除 calendar 参数硬编码 Asia/Shanghai**。本 worklog 反映最终态。

## What changed

### `ios/Sources/BacktesterNoteAlgorithms/Radar.swift`

**两轮迭代**：

**第一轮**（响应 Codex P2-1）：把 `sustainabilityScore` 默认参数 `calendar: Calendar = .current` 改成 `calendar: Calendar = BNCalendar.calendar`。

**第二轮（本最终态，Elvis 2026-04-25 决议）**：直接**删除 `calendar` 参数**。理由：产品是国内基金复盘工具，按非 CN 时区看盘没有合法语义；保留 calendar 参数 = 给未来漂移留口子。彻底锁死优于设默认值。

```diff
-    /// 收益质量（sustainability）打分。
-    public static func sustainabilityScore(
-        currentPoints: [RadarNAVPoint],
-        previousPoints: [RadarNAVPoint] = [],
-        calendar: Calendar = .current,
-        config: RadarConfig = .default
-    ) -> Double {
+    /// 收益质量（sustainability）打分。
+    ///
+    /// 月度分桶**强制**用 ``BNCalendar/calendar``（固定 Asia/Shanghai TimeZone）。
+    /// 产品定位是国内基金复盘工具，按非 CN 时区看盘没有合法语义；为防止
+    /// "传错 calendar" 这类漂移在调用方发生，本方法**不暴露** `calendar` 参数。
+    public static func sustainabilityScore(
+        currentPoints: [RadarNAVPoint],
+        previousPoints: [RadarNAVPoint] = [],
+        config: RadarConfig = .default
+    ) -> Double {
```

```diff
-    private static func monthlyReturns(points: [RadarNAVPoint], calendar: Calendar) -> [Double] {
-        let grouped = Dictionary(grouping: points) { point in
-            calendar.dateComponents([.year, .month], from: point.date)
-        }
+    /// 月度收益分桶。强制 Asia/Shanghai 自然月。
+    private static func monthlyReturns(points: [RadarNAVPoint]) -> [Double] {
+        let grouped = Dictionary(grouping: points) { point in
+            BNCalendar.calendar.dateComponents([.year, .month], from: point.date)
+        }
```

仓库内 `Algorithms/` 全量 `grep "Calendar.current"` 已无任何漏网。

### `ios/Tests/BacktesterNoteAlgorithmsTests/RadarTests.swift`

- 旧测 `sustainabilityFormula`：去掉 `calendar: BNCalendar.calendar` 显式传参（API 已无此参数）；期望值 `0.6833` 不变。
- 新测 `sustainabilityIsTimezoneStable`（替代第一轮的 `sustainabilityDefaultCalendarIsShanghai`）：用月末跨 UTC/Shanghai 边界的合成点，断言**确定性**输出 `0.5833 ± 0.005`。
  - 期望值按 Asia/Shanghai 分桶手算（推导写在测试注释里）
  - 任何回退到 `Calendar.current` 的修改在非 CN 时区 CI 上必挂（UTC 下 `2026-02-01` 上海凌晨会落进 UTC 1 月，桶结构变化 → 分数变化）
  - 不需要切 process 时区

## Contract change

`docs/algorithms/radar.v1.md` v1.1 → v1.2：§3.6 加"时区策略"段落明示 `sustainabilityScore` **不暴露 calendar 参数**；公式本身不变。算法契约改动按 [AGENTS.md §会合点](../../AGENTS.md#会合点契约驱动) 流程算改动，但**决议人 = Elvis**（最高权威），仍走 review 门：本 worklog `## Review` 必须由 Codex 显式填 ✅/🔧/⚠️ 才算合并完成。

⚠️ **API 表面缩窄**：`sustainabilityScore` 删掉 `calendar` 参数。这是 source-incompat 改动，但当前调用方仅有 `RadarTests`（已同步修），无外部 caller。Phase 1c 后任何新调用方将**再也不能**传 calendar。

## Algorithm drift

**预防、不漂**。修复对：

- 在 CN 时区设备上 → 行为完全不变（`Calendar.current` 在 CN 设备上恰好等于 `BNCalendar.calendar`）
- 在非 CN 时区设备 / CI 上 → 修复月度分桶错位，**这恰恰是把以前隐式漂移消除掉**

不存在与旧 app 的对账问题（旧 app 同样依赖 `Calendar.current`，本身也有这个 bug；新 app 用固定 Asia/Shanghai 是受 [PRD §3 / nav.v1.md §0](../prd/Backtester_Note_PRD_v2.md) 显式授权的纠偏）。

## Review

✅ 通过（Codex 复审第二轮，2026-04-25）。

复审结论：
- `Radar.swift` `sustainabilityScore` 与 `monthlyReturns` 的 `calendar` 参数均已删除，`monthlyReturns` 内部固定使用 `BNCalendar.calendar.dateComponents([.year, .month], from:)`，符合 Asia/Shanghai 自然月口径。
- `Radar.swift` doc comment 指向 `docs/algorithms/nav.v1.md` §0，说明"全 App 统一 Asia/Shanghai 自然日"红线，且解释了不暴露 `calendar` 参数的 API 设计理由。
- `RadarTests.sustainabilityIsTimezoneStable` 的 `0.5833 ± 0.005` 期望值手算成立：5 个 daily returns、`positiveDayRatio = 3/5 = 0.60`、三个月全部为正、`topFiveShare = 1.0`、空 previous window 下 `improvementScore = 0.5`。
- 旧测 `sustainabilityFormula` 已去掉显式 `calendar:` 参数，期望值 `0.6833` 不变。
- `radar.v1.md` v1.2 changelog 与实现一致。
- 仓库 `ios/` 内无真实 `Calendar.current` 调用；剩余命中均为注释或 enum case `.current`。

验证：
- `swift test` 通过：13 tests / 4 suites。

## Conflict

无。

## Questions for Elvis

无（本次修复来自已 ✅ 的 Codex review，不引入新决策）。

## Ideas

- AGENTS.md §并行模式表写的是"Opus=iOS / GPT=backend / Claude Design=按需"，但实际工作流是"Claude 干 / Codex 审"。本 worklog 用 `Agent: Claude` 反映真实状态。**建议** Elvis 在合适时机更新 AGENTS.md 把这条对齐——避免下次 review agent 看到目录所有权表跟实际分工不一致而误判。本次不动。
- 可以扫一遍 backend repo（`/Users/elvischen/Developer/backtester_backend`）看有没有同类 `datetime.now()` / `tz.utc` 漂时区的隐患。**本次不动**，下一刀 backend 维护时顺手做。

## Next

- [ ] **Codex** 复审本刀（P2-1 修复）
- [ ] **Elvis** Codex ✅ 后 commit & push
- [ ] **Opus / Claude（同人）** 在本 worklog `## Review` 显式填 ✅ 关闭 [`radar-v1-1-decisions worklog`](2026-04-25_be_radar-v1-1-decisions.md) 的待 review 状态——P2-1 已修，那条 worklog 才能算彻底闭环
