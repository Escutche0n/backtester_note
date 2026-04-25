# 回测手记 PRD v2

> **App 名**：`回测手记`（暂用名，后续可能改，改时全局替换）
> **代号**：`backtester_note`
> v1 见 [Backtester_Note_PRD.md](Backtester_Note_PRD.md)。v2 不推翻 v1 愿景，补齐 v1 缺的：红线、可验收口径、可量化的 Free/Pro 边界、JSON schema 骨架、与 `docs/design/` 的映射、与旧 app 的迁移关系。

---

## 0. 关于此版本

**本 PRD 冻结下列内容**。任一项变动都需 Elvis 明确"改 PRD"才可动：

- §1 愿景 / §2 信息架构（2 tab）
- §3 核心数据口径（NAV 可信度 / 快照规则 / 雷达六维）
- §4 Free/Pro 可量化边界
- §5 红线
- §6 JSON schema v1 顶层结构
- §7 与设计稿、旧 app 的映射

具体接口与实现细节放在 `docs/contracts/` 与 `docs/algorithms/`，不在 PRD 里。

---

## 1. 愿景

一款 iOS 原生、面向国内个人基金投资者的**复盘工作台**。

**主体功能只有两件**：
1. **回测** —— 单基金 / 组合 / 定投 / 历史
2. **跟踪持仓** —— 真实账户 NAV / 趋势雷达 / 交易流水

让用户在三个问题上得到明确答案：
1. 我现在到底持有什么，账户真实状态如何？
2. 净值变化来自市场波动还是我自己的操作？
3. 如果继续某种方式定投或调整组合，过去会怎样？

---

## 2. 信息架构（冻结）

**两 Tab**，其他入口收进持仓右上角齿轮的设置面板。

```
[持仓]  [回测]
   └── 右上齿轮 → 设置
                   ├── 账户
                   ├── 数据维护（快照 / 流水 / 对账）
                   ├── 缓存
                   ├── 快捷指令 & JSON 导入
                   ├── Widgets 管理 & 同步状态
                   ├── 外观（Pro：密度 / 图表填充 / 强调色 hue；Free 固定默认）
                   └── 订阅（Phase 1 仅占位"即将推出"，Phase 3 激活）
```

**为什么不是 4 tab**：设计稿原给了 今日/持仓/回测/组件 4 tab。决定合并——"今日"内容并入持仓首屏顶部，"组件"沉到设置。设计稿下一版会顺势改（Claude Design 跟进）。

**默认落地 tab = `持仓`**。

---

## 3. 核心数据口径（冻结）

### 3.1 持仓建模：快照 + 继承流水

**规则**：
- 用户建账号的**最低数据要求** = 一个"起始快照"（日期 + 每只基金的份额/市值）。流水可留空。
- 之后的所有操作以**流水**形式追加（买/卖/分红/转入/转出）。
- **不强迫用户手动输入历史几年的流水**。这是新用户体验的红线。

**向前扩展规则**（Q4 决议：**方案 B**）：
- 允许用户新增一个**更早的**快照 + 其间补录流水。
- 原快照**自动降级为中间 checkpoint**（保留语义、不是起始基数）。
- **最早的那个快照 = 成本基数**，参与持有收益计算。
- 快照日**只能前移，不能后移**。不允许删除已有快照让起始日后退（防止"把 2025 年流水删了"这类数据污染）。
- 前移时 UI 必须弹确认："XIRR 基准日将从 `YYYY-MM-DD` 改为 `YYYY-MM-DD`，历史 NAV 曲线会重算，是否继续？"
- 重算后所有历史 NAV 点、雷达快照、已保存回测都要重新对齐。

### 3.2 NAV 可信度状态机

每条账户净值点必须打一个可信度标签：

| 状态 | 条件 | 展示 |
|---|---|---|
| `confirmed` | 有官方净值 + 流水完整 | 实色 |
| `pending_reconcile` | 有官方净值 + 流水残缺 | 实色 + "⚠ 待对账" |
| `intraday_estimate` | 当日盘中估值 | 半透明 + "估" |
| `snapshot_only` | 仅用户录入快照 | 灰色 + "快照" |
| `flow_only` | 仅流水、无净值 | 隐藏于曲线，列表标"仅流水" |

**规则**：
- 盘中估值**永不覆盖**历史 `confirmed`
- 同日 `snapshot_only` 与 `confirmed` 并存，`confirmed` 优先
- 曲线图例旁必须标明当前范围内混入了哪些非 `confirmed` 点

### 3.3 账户 NAV 与衍生指标

- **账户 NAV** = 剔除外部申赎现金流后账户自身表现折算的单位净值（TWRR 口径）
- **XIRR 起点** = 第一笔**有效流水**的日期（不是快照日）。快照日至首笔流水之间的持有，用快照市值作为 `t0` 上一期的余额参与，但不算进 XIRR 的现金流序列。
- **持有收益** = 当前市值 − (最早快照市值 + 快照后所有流水净投入)。展示处小字注明"自 YYYY-MM-DD 起计"。
- **夏普 / 卡尔马 / 回撤 / 沪深300 基准对齐日历**：全部写入 [docs/algorithms/nav.v1.md](../algorithms/nav.v1.md)（GPT 起草）。

**数字级要求**：NAV / XIRR / 回测全套指标必须与旧 app（[/Users/elvischen/Developer/investment app/](file:///Users/elvischen/Developer/investment%20app/)）在同一份 input fixture 上数字一致，差异 > 0.01% 视为口径漂移，按 [AGENTS.md](../../AGENTS.md) 红线 5 处理。

### 3.4 趋势雷达六维（冻结）

与设计稿 [bn-holdings.jsx](../design/backtester-note/project/lib/bn-holdings.jsx) 及旧 app `HoldingsHomeFeature.swift:3-95` 对齐：

| 维度 | 旧 app 字段 | 含义 |
|---|---|---|
| 超额收益 | `excessQuality` | 账户 vs 沪深 300 的超额质量 |
| 执行程度 | `strategyExecution` | 计划定投/再平衡完成度 |
| 投资纪律 | `tradingDiscipline` | 频繁交易、追涨杀跌反向扣分 |
| 风险控制 | `riskControl` | 回撤 / 波动率 / 集中度 |
| 风格 | `styleStability` | 组合风格漂移 |
| 收益 | `sustainability` | 绝对收益（滚动窗口） |

**总分权重**：六维简单平均，每维 `1/6`。与旧 app `HoldingsHomeFeature.swift:20-24` 一致。
**策略执行子分权重**：`0.22 / 0.22 / 0.18 / 0.14 / 0.14 / 0.10`，仅用于 `strategyExecution` 维度内部子分（旧 app `HoldingsHomeFeature.swift:84-95`），不得当作六维总分权重。
**展示**：支持 当前 / 上周 / 上月 三快照叠加。
**重构要求**：权重与阈值必须从旧 app 抽到 `docs/algorithms/radar.v1.md` 单一 config，不再散落代码。

**修改记录**：2026-04-25 09:19 CST，由 GPT 根据 Elvis 明确裁定修正本小节权重口径；原 PRD 文案误把 `strategyExecution` 子分权重写成六维总分权重。

### 3.5 回测口径

保留 v1 §8.3 / §8.4 全部能力。旧 app 的 XIRR（Newton-Raphson 40 iter / tol 1e-7 / init 0.12）数字必须保留。口径写入 [docs/algorithms/backtest.v1.md](../algorithms/backtest.v1.md)。

---

## 4. Free / Pro 边界（可量化）

| 能力 | Free | Pro |
|---|---|---|
| 手动录入持仓 / 流水 | ✅ | ✅ |
| 快捷指令 + JSON 导入 | ✅ | ✅ |
| 基金搜索 / 历史净值 | ✅ 每日 ≤ 50 次（本地节流，不调后端）| 调用自建 FastAPI（`http://159.75.16.87`），无限 |
| 实时估值 | 用户手动下拉刷新 | 后台自动 ≤ 5 分钟一次（交易时段）|
| 历史缓存 | 最近 1 年 | 全量 |
| Widget 自动刷新 | iOS 默认（~每小时）| 附加后端 snapshot 推送，≤ 30 分钟 |
| 历史回测保存 | ≤ 10 条 | ≤ 200 条 |
| 组合数 | ≤ 3 | ≤ 20 |
| 每日异常提醒 | ≤ 3 条 | 无上限 |
| 外观自定义（密度 / 填充 / hue）| 固定默认 | 可调（对应设计稿 Tweaks Panel）|
| 云备份 | JSON 手动 | 自动（TBD，上架前决定）|

**红线**：Free 必须能完整体验所有核心算法结果（不阉割口径），Pro 只买"省心 + 规模 + 自定义"。

### 4.1 后端对接分工

- **Free**：App 不调用自建后端。基金搜索 / 历史净值可选两条路——(a) 用户用快捷指令调外部 API 存进 JSON 再导入，(b) App 调公开公共源。走哪条看旧 app 现状再定（GPT 起草时确认）。
- **Pro**：App 调 `http://159.75.16.87` 自建 FastAPI，路由来自旧 `backend/`（`/api/fund/search` / `/api/fund/realtime` / `/api/fund/history` / `/api/portfolio/history`）。新 repo 的 `backend/` 暂不新写，复用旧后端 + 加 `.env` 和请求校验（salvage matrix Q3）。

---

## 5. 红线

见 [AGENTS.md §红线](../../AGENTS.md)。重申：

1. 不得把核心算法（NAV / 雷达 / 回测）阉割进 Pro。
2. 不得未经 Elvis 同意加三方 SDK、analytics、tracker、任何外发请求（自建 159.75.16.87 除外）。
3. 不得修改权限声明而不在 worklog 标红。
4. 不得让核心算法数字与旧客户端漂移 > 0.01%。Phase 1 必须建 golden fixture 做 CI 校验。
5. 商业决策（定价、Pro 边界、上架时点、版本号跳变）—— 停下来问 Elvis。
6. 不强迫新用户手动回补历史流水。快照 + 继承流水是红线路径。

---

## 6. JSON 导入 Schema v1（顶层冻结）

详见 [docs/contracts/json_import.v1.md](../contracts/json_import.v1.md)。顶层结构：

```json
{
  "schema": "backtester-note/import/v1",
  "exported_at": "2026-04-25T00:00:00+08:00",
  "accounts": [
    {
      "account_id": "default",
      "snapshots": [
        {
          "date": "2024-01-01",
          "is_baseline": true,
          "holdings": [
            {"code": "000001", "name": "...", "shares": 1234.56, "value": 1500.00}
          ]
        }
      ],
      "flows": [
        {
          "date": "2024-02-15",
          "code": "000001",
          "type": "buy|sell|dividend|transfer_in|transfer_out",
          "amount": 500.00,
          "shares": 400.12,
          "fee": 0.6
        }
      ]
    }
  ]
}
```

**规则**：
- `schema` 字段是版本号，永不删字段，只加（Additive-only）
- 恰有一个 snapshot 的 `is_baseline: true`（最早那个）
- 导入前必须预览 + 对账，用户点"确认"才落地
- 导入器只读 `backtester-note/import/v1`。旧 app 如需迁移，必须反向新增"导出为 Backtester Note JSON v1"能力；新 app 不兼容旧 app 私有 persistence 格式。

---

## 7. 映射关系

### 7.1 设计 tokens → SwiftUI 常量

视觉以 [bn-tokens.css](../design/backtester-note/project/lib/bn-tokens.css) 为准，一对一映射为 SwiftUI 常量：

| 设计 token | SwiftUI | 说明 |
|---|---|---|
| `--bn-bg` `#0B0B0D` | `BNColor.bg` | 深色底 |
| `--bn-up` `#F6465D` | `BNColor.up` | 红（涨，默认）|
| `--bn-down` `#2EBD85` | `BNColor.down` | 绿（跌，默认）|
| `--bn-accent` `#E3B15C` | `BNColor.accent` | 失衡 / Pro 强调 |
| `--bn-benchmark` `#7A8AA8` | `BNColor.benchmark` | 沪深 300 基准线 |
| `.bn-glass` | `BNGlassModifier()` | iOS 26 Liquid Glass |
| `.bn-frost` | `BNFrostModifier()` | 卡片内嵌轻量毛玻璃 |
| `.bn-mono` | SF Mono / tabular-nums | 所有数字 |
| `--bn-r-lg` 20pt | `BNRadius.lg = 20` | 卡片圆角 |

**默认配色**：红涨绿跌（`invertPnlColor = false`），用户可在设置里切换，`@AppStorage("pnlColorInvert")`。

### 7.2 持仓 Tab 页面结构（冻结顺序）

对应设计稿 [bn-holdings.jsx](../design/backtester-note/project/lib/bn-holdings.jsx)：

1. `TotalHeader` —— 总市值 + 今日盈亏 + 单位净值 + 右上设置齿轮
2. `OverviewPanel` —— 9 指标 3×3 网格 + 失衡 mini-bar
3. `NavCard` —— 净值曲线 + 沪深300 + 1M/3M/6M/1Y/自定义
4. `RadarCard` —— 六维 + 当前/上周/上月叠加 + 总分 + 分项 delta
5. `HoldingsList` —— 基金卡片列表
6. **（新增）异常 banner**：失衡 > 10% / 连续 N 天待对账 / Pro 同步失败

**点 HoldingCard → 单基金详情页**：个体净值曲线 / 交易流水 / 成本 / 个体雷达。

### 7.3 回测 Tab 页面结构

对应 [bn-backtest.jsx](../design/backtester-note/project/lib/bn-backtest.jsx)：

- 顶部分段：`单基金 / 组合 / 定投 / 历史`
- `ConfigCard`（按模式切换参数）
- `ResultPreview`（CAGR/XIRR/回撤/夏普/超额 + 图）
- `HistoryList` + 对比按钮（最多选 2 个 diff）
- 右上"新建"按钮 → 一键从当前持仓带入参数

### 7.4 与旧 app 的迁移关系

详见 [docs/algorithms/salvage_matrix.md](../algorithms/salvage_matrix.md)。大原则：

- **Port as-is**：XIRR / TWRR / 单基金 DCA / Widget 数据通道 / Persistence facade / Backend
- **Port + 重写 wrapper**：TWRR NAV 的 API 表面、Widget refresh 职责拆分
- **Rewrite**：`HoldingsHomeFeature.swift` 3797 行 god file、组合再平衡阈值散落、雷达权重硬编码

旧 `prd/` 的 75 份 session log 不迁移，不索引。旧 app 如需迁移真实账户，应新增"按新 schema 导出"能力；新 app 不读取旧 app 私有格式。此决议由 Elvis 于 2026-04-25 裁定，目的是保持新 app 导入器干净、单一、可测试。

---

## 8. 成功指标与埋点

本地 SQLite 埋点 + Pro 开启云同步才上传自建后端，**永不接入三方 analytics**。

| 指标 | 事件 |
|---|---|
| 首次快照建立 / 首次导入 | `snapshot_created` / `import_succeeded` |
| 7 日复访 | `app_launch_daily` |
| 任一 widget 启用 | `widget_installed` |
| 完成一次回测 | `backtest_ran` |
| Free → Pro 转化 | `pro_purchased`（Phase 3 激活）|
| Pro 同步成功率 | `sync_succeeded` / `sync_attempted` |
| Widget snapshot 刷新 | `widget_snapshot_ok` / `widget_snapshot_attempted` |

---

## 9. 分阶段路线图

### Phase 1 · 骨架（Elvis 自用）
- 2 Tab 壳 + 持仓 Tab 完整（设计 1:1）+ 设置面板
- JSON 导入 v1 + 快照前移规则 UI + 对账预览
- 端上 NAV / 雷达算法从旧 app 抽干净（拆出 config，去 god file）
- **Golden fixture CI**：用旧 app 真实账户跑一遍，锁定期望值，新代码比对
- 订阅入口占位"即将推出"

### Phase 2 · 回测与 Widgets
- 回测 Tab 四模式完整 + 历史对比
- 三个核心 widget（净值曲线 / 雷达 / 今日收益）
- 快捷指令模板

### Phase 3 · Pro 自动化
- Pro 内购 + 后端同步任务（调 `http://159.75.16.87`）
- Widget snapshot 推送
- 失败回退 / 离线策略
- 订阅卡片激活

### Phase 4 · 上架
- 合规 / 隐私协议 / 评级
- TestFlight → App Store

### Phase 5 · 平台扩展（不阻塞上架）
- Mac（Catalyst 或原生）

---

## 10. 一句话

> 回测手记是一款以真实基金持仓为核心、以账户净值与回测复盘为主线、以快照 + 继承流水为友好入口、以自建后端自动同步为 Pro 核心卖点、通过 iOS 26 原生体验和 Widgets 形成日常习惯的个人基金投资工作台。
