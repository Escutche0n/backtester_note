# 2026-04-25 · 雷达六维审查 · 工作笔记

> 非 commit log，纯讨论记录。Elvis 的问题 + 我的分析，供后续决策参考。

---

## 背景

Elvis 问：当前六维窗口期是否合理。

---

## Elvis 的两个判断

### 判断 1：三快照锚点用交易日，而非日历天数

当前 radar.v1.md 定义：
- `lastWeek` → today − 7 days（日历）
- `lastMonth` → today − 30 days（日历）

**Elvis 倾向改为：**
- `lastWeek` → today − 5 trading days
- `lastMonth` → today − 22 trading days

**分析：** 合理。国内 A 股每年约 240-250 个交易日，5 ≈ 一周、22 ≈ 一月。这个锚点决定了"截取哪段历史数据来算这一期快照"，用交易日比日历更稳定——不会因为五一/端午/国庆长假导致"上周"截了 9-12 个日历天。

**影响范围：**
- `StrategyRadarSnapshot.anchorDate` 语义从"具体日期"改为"往前推 N 个交易日"
- `BNCalendar` 需要新增 `往前推N个交易日` 方法（当前只有日历偏移）
- 文档 `radar.v1.md` §2 需要更新

---

### 判断 2：六维窗口期统一为 90 天

当前 radar.v1.md §3：

| 维度 | 当前窗口 |
|---|---|
| excessQuality | 180 天 |
| strategyExecution | 90 天 |
| tradingDiscipline | 90 天 |
| riskControl | 180 天 |
| styleStability | 180 天 |
| sustainability | 180 天 |

**Elvis 倾向：统一 90 天（所有维度）。**

**分析：**
- **支持统一的理由**：用户理解成本低、六个维度的评估周期一致、不需要在 UI 上解释"此维看半年、此维看三个月"
- **反对 180 天的理由**：新账户前 90 天也能跑满所有维度，不需要等半年才有"完整雷达"

**对各维度的影响（潜在问题）：**

| 维度 | 改为 90 天后的风险 |
|---|---|
| excessQuality | 超额年化需要年化（annualize = 收益 / (90/365)），样本更少波动更大 |
| riskControl | 最大回撤/波动率在 90 天内可能比 180 天表现更好（运气成分更多），区分度下降 |
| styleStability | 风格漂移 90 天内观测窗口短，偶发调仓会被放大 |
| sustainability | 滚动正收益窗口用 90 天基数，结果更不稳定 |

**建议：** 可以统一为 90 天，但需要接受上述权衡。如果担心区分度，可以在 `RadarConfig` 里把各维度窗口做可配置参数（Phase 2+），而不是硬编码。

---

## 决策待确认

| # | 事项 | 待确认人 | 状态 |
|---|---|---|---|
| 1 | 三快照锚点改为 5/22 交易日 | Elvis | ⏳ |
| 2 | 六维窗口统一 90 天 | Elvis | ⏳ |
| 3 | BNCalendar 是否需要 `往前推N交易日` | Opus（实现层）| 待1确认后处理 |
| 4 | sustainability 公式补完（P0 阻塞）| GPT port 时补 | ⏳ |

---

## 涉及文件（不改，仅记录）

- `docs/algorithms/radar.v1.md` §2（三快照定义）、§3（各维窗口）
- `ios/Sources/BacktesterNoteAlgorithms/Radar.swift`（anchorDate 语义）
- `ios/Sources/BacktesterNoteAlgorithms/BNCalendar.swift`（工具方法）
