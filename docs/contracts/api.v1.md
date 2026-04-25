# Backend API Contract v1.1

> ⚠️ `POST /api/portfolio/history` 仍是 mock；其余已知接口已按后端源码反推到 v1.1。
>
> schema 已按 GitHub 后端 `https://github.com/Escutche0n/backtester-backend` commit `926c912` 反推到 v1.1。
> `POST /api/portfolio/history` 仍是后端 mock，iOS 端不得当作真实回测/组合历史数据源。
>
> 实现锚点：`ios/Networking/Endpoints.swift`
> 后端代码访问路径：`https://github.com/Escutche0n/backtester-backend`

---

## 1. 服务地址与认证

- **生产**：`http://159.75.16.87`（注意：HTTP，非 HTTPS。Phase 4 上架前必须切 HTTPS — `## Questions for Elvis`）
- **认证**：Phase 1/2 无认证（仅自用）；Phase 3 引入 Pro 时按 StoreKit 收据验证（具体方案 GPT 起草 v1.1）
- **CORS**：旧后端开放所有 origins（开发期 OK，上线前收紧）
- **限流**：服务端无限流；客户端 Free 自行节流（PRD §4 ≤ 50 次/日）

---

## 2. 已知路由（来自旧后端 README）

| Method | Path | 用途 | Free 可调？ | Pro 可调？ |
|---|---|---|---|---|
| GET | `/health` | 存活探测 | ✅ | ✅ |
| GET | `/api/fund/search?keyword=xxx` | 基金模糊搜索 | ❌（Free 走本地或快捷指令）| ✅ |
| GET | `/api/fund/realtime?code=xxx` | 单基金实时估值 | ❌ | ✅（App 内主动刷新可控；后台刷新尽力而为）|
| GET | `/api/fund/history?code=xxx&start_date=YYYY-MM-DD&end_date=YYYY-MM-DD` | 单基金历史净值 | ❌ | ✅ |
| POST | `/api/portfolio/realtime` | 真实持仓盘中估值聚合 | ❌ | ✅ |
| POST | `/api/portfolio/history` | 多基金组合历史聚合 | ❌ | ⚠️ 当前 mock，不可用于生产 |

**v1 决议**：Free 完全不调用本后端（PRD §4.1）。任何 Free 路径出现对 159.75.16.87 的请求 = bug。

---

## 3. 字段细节（待 GPT 补完）

### 3.1 `GET /api/fund/search`

```http
GET /api/fund/search?keyword=华夏
```

响应：

```json
{
  "keyword": "华夏",
  "source": "eastmoney",
  "items": [
    { "code": "000001", "name": "华夏成长混合", "fund_type": "混合型", "currency": "CNY" }
  ]
}
```

字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| `keyword` | string | 原查询词 |
| `source` | string | 当前为 `eastmoney` |
| `items[].code` | string | 基金代码 |
| `items[].name` | string | 基金名称 |
| `items[].fund_type` | string | 基金类型，上游字符串 |
| `items[].currency` | string | 默认 `CNY` |

### 3.2 `GET /api/fund/realtime`

```http
GET /api/fund/realtime?code=006195
```

```json
{
  "data": {
    "code": "006195",
    "name": "国金量化多因子股票A",
    "fund_type": "股票型",
    "nav": 3.5202,
    "nav_date": "2026-04-22 15:00",
    "change_percent": 1.32,
    "value_kind": "estimated",
    "source": "eastmoney"
  }
}
```

实际后端 response model 是 `{ "data": FundRealtimeData }`，不是数组。iOS 端如需多基金，应并发请求单基金接口或优先使用 `POST /api/portfolio/realtime`。

字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| `data.code` | string | 基金代码 |
| `data.name` | string | 基金名称 |
| `data.fund_type` | string | 基金类型 |
| `data.nav` | number | 当前用于估值的净值 |
| `data.nav_date` | string | 上游时间字符串，当前不保证 ISO 8601 |
| `data.change_percent` | number? | 估算涨跌幅；fallback 到确认净值时可能为空 |
| `data.value_kind` | string | `estimated` 或 `unit_nav` |
| `data.source` | string | 当前为 `eastmoney` |

### 3.3 `GET /api/fund/history`

```http
GET /api/fund/history?code=000001&start_date=2024-01-01&end_date=2026-04-25
```

```json
{
  "fund_code": "000001",
  "fund_name": "华夏成长混合",
  "fund_type": "混合型",
  "source": "eastmoney",
  "start_date": "2024-01-01",
  "end_date": "2026-04-25",
  "points": [
    { "date": "2024-01-02", "unit_nav": 1.0234, "accumulated_nav": 1.5678 }
  ]
}
```

字段：

| 字段 | 类型 | 说明 |
|---|---|---|
| `fund_code` | string | 基金代码 |
| `fund_name` | string | 基金名称 |
| `fund_type` | string | 基金类型 |
| `source` | string | 当前为 `eastmoney` |
| `start_date` / `end_date` | string? | 请求范围，可能为空 |
| `points[].date` | string | `YYYY-MM-DD` |
| `points[].unit_nav` | number | 单位净值 |
| `points[].accumulated_nav` | number | 累计净值 |

当前不返回 `growth_rate` / 分红事件。iOS 端不要依赖这些字段。

### 3.4 `POST /api/portfolio/realtime`

请求体：

```json
{
  "holdings": [
    { "fund_code": "006195", "shares": 1000 },
    { "fund_code": "008163", "shares": 2000 }
  ]
}
```

响应：

```json
{
  "summary": {
    "base_value": 5645.6,
    "estimated_value": 5662.0,
    "estimated_profit": 16.4,
    "estimated_return": 0.002905
  },
  "items": [
    {
      "fund_code": "006195",
      "fund_name": "国金量化多因子股票A",
      "fund_type": "股票型",
      "shares": 1000.0,
      "base_date": "2026-04-22",
      "base_nav": 3.5038,
      "estimated_time": "2026-04-22 15:00",
      "estimated_nav": 3.5202,
      "value_kind": "estimated",
      "base_value": 3503.8,
      "estimated_value": 3520.2,
      "estimated_profit": 16.4,
      "estimated_return": 0.004681
    }
  ],
  "disclaimer": "估算结果仅供个人记录，不代表确认净值或投资建议。"
}
```

### 3.5 `POST /api/portfolio/history`

请求体：

```json
{
  "holdings": [
    { "fund_code": "000001", "weight": 0.6 },
    { "fund_code": "110011", "weight": 0.4 }
  ],
  "start_date": "2024-01-01",
  "end_date": "2026-04-25",
  "rebalance": "none"
}
```

响应：

```json
{
  "start_date": "2024-01-01",
  "end_date": "2026-04-25",
  "rebalance": "none",
  "points": [
    { "date": "2026-04-18", "portfolio_nav": 1.0, "daily_return": 0.0 }
  ],
  "warnings": ["mock implementation: portfolio history is not using real fund data yet"]
}
```

**当前状态**：mock implementation。iOS 不得把该接口结果用于真实回测、持仓 NAV 或生产展示。

---

## 4. 错误处理

| 状态 | 含义 | 客户端行为 |
|---|---|---|
| 200 + `code:0` | 成功 | 解析 data |
| 200 + `code≠0` | 业务错误 | 弹 banner，记 worklog |
| 4xx | 请求错误 | 不重试，展示给用户 |
| 5xx | 服务端故障 | 指数退避，最多 3 次；失败标 `sync_failed` |
| 超时 | 默认 10s | 同 5xx |

**铁律**：网络错误**不能**让 UI 卡死。Holdings 页必须能用本地缓存渲染 + banner 提示"数据未刷新"。

---

## 5. iOS 客户端契约

`ios/Networking/Endpoints.swift`：

```swift
enum Endpoint {
    case fundSearch(keyword: String)
    case fundRealtime(code: String)
    case fundHistory(code: String, range: ClosedRange<Date>)
    case portfolioRealtime(holdings: [(fundCode: String, shares: Double)])
    case portfolioHistory(holdings: [(fundCode: String, weight: Double)], range: ClosedRange<Date>, rebalance: String)
    case health

    var path: String { /* … */ }
    var method: HTTPMethod { /* … */ }
    var body: Data? { /* … */ }
}
```

`APIClient` 必须：
- 默认 base = `http://159.75.16.87`，可被 `EnvConfig` 覆盖
- 所有调用是 async / Result-based
- 每个调用前检查 `Entitlement.current == .pro`（除 health）

---

## 6. 后端代码访问

**线上 = GitHub 100% 镜像**。GPT 拿源码方式：

- **GitHub URL**：`https://github.com/Escutche0n/backtester-backend`
- **已核对 commit**：`926c912 add portfolio realtime endpoint`
- **本地 clone 路径**：`/Users/elvischen/Developer/backtester_backend`
- **关系**：后端独立 repo，不进本仓 submodule。本仓只保存 iOS 依赖的 API contract。
- **部署现状**：Elvis 当前手动下载后端文件并上传服务器运行。GPT 可后续在后端 repo 内优化部署流程，优先目标是减少手动上传。

## 7. 开放问题（GPT 起草 v1.1 时回答）

1. **HTTPS**：Phase 4 上架前必须有 TLS。GPT 评估 Let's Encrypt / Cloudflare。
2. **认证方案**：Pro StoreKit receipt → 后端验证 → 短期 token。具体协议 v1.2。
3. **部署流程**：从手动上传改为 git pull + systemd / Docker / GitHub Actions 之一。
4. **数据源数据缺失策略**：基金停牌 / 节假日 / 数据延迟时返回什么。
5. **Portfolio history**：替换 mock，实现真实基金历史聚合。

---

## 8. Changelog

- v1 stub (2026-04-25) — 仅冻结路由 + Free/Pro 边界。字段 schema 待 GPT 补完 v1.1。
- v1 stub (2026-04-25) — 后端代码访问规则确定（§6）：GitHub URL 只读 clone，不进本仓 submodule。等 Elvis 贴 URL。
- v1.1 (2026-04-25) — 按 `backtester-backend` commit `926c912` 反推真实 schema：修正 fund realtime 为单 code，补 `portfolio/realtime`，标记 `portfolio/history` 仍为 mock。
