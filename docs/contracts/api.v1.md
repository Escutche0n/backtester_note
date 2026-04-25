# Backend API Contract v1（STUB）

> ⚠️ **本文件是 stub**。
>
> 完整 schema 待 GPT 反推线上后端 `http://159.75.16.87` 实际响应或读旧后端代码后补完。
> 已知接口结构来自旧 app `FundMVP/Networking/` 与旧后端 README，可信但未对齐字段细节。
>
> 实现锚点：`ios/Networking/Endpoints.swift`
> 后端代码访问路径：**待 Elvis 在 worklog 提供**（`Phase0` worklog `## Questions for Elvis` 已挂）。

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
| GET | `/api/fund/realtime?codes=xxx&codes=yyy` | 多基金实时估值 | ❌ | ✅（≤ 5 min/次）|
| GET | `/api/fund/history?code=xxx&start_date=YYYY-MM-DD&end_date=YYYY-MM-DD` | 单基金历史净值 | ❌ | ✅ |
| POST | `/api/portfolio/history` | 多基金组合历史聚合 | ❌ | ✅ |

**v1 决议**：Free 完全不调用本后端（PRD §4.1）。任何 Free 路径出现对 159.75.16.87 的请求 = bug。

---

## 3. 字段细节（待 GPT 补完）

### 3.1 `GET /api/fund/search`

```http
GET /api/fund/search?keyword=华夏
```

预期响应（旧 app `EastMoneySearchResponse` 模型反推）：

```json
{
  "code": 0,
  "data": [
    { "code": "000001", "name": "华夏成长混合", "type": "混合型" }
  ]
}
```

**TBD**：错误码、`data` 是否分页、`type` 枚举完整列表。GPT 起草 v1.1。

### 3.2 `GET /api/fund/realtime`

```http
GET /api/fund/realtime?codes=000001&codes=110011
```

```json
{
  "code": 0,
  "data": [
    {
      "code": "000001",
      "estimated_nav": 1.2345,
      "estimated_at": "2026-04-25T14:30:00+08:00",
      "official_nav": 1.2300,
      "official_date": "2026-04-24",
      "change_rate": 0.0036
    }
  ]
}
```

**TBD**：`change_rate` 基准（vs 昨收 / vs 官方）；停盘 / 数据缺失返回；交易时段外的行为。

### 3.3 `GET /api/fund/history`

```http
GET /api/fund/history?code=000001&start_date=2024-01-01&end_date=2026-04-25
```

```json
{
  "code": 0,
  "data": {
    "code": "000001",
    "records": [
      { "date": "2024-01-02", "unit_nav": 1.0234, "accumulated_nav": 1.5678, "growth_rate": 0.0012 }
    ]
  }
}
```

**TBD**：分红事件如何标注；日期空缺（停盘 / 节假日）的标准；`growth_rate` 定义。

### 3.4 `POST /api/portfolio/history`

请求体（来自旧 app `CommonModels.swift::PortfolioHistoryRequest`）：

```json
{
  "items": [
    { "code": "000001", "weight": 60 },
    { "code": "110011", "weight": 40 }
  ],
  "start_date": "2024-01-01",
  "end_date": "2026-04-25",
  "benchmark": "csi300"
}
```

**TBD**：`benchmark` 枚举；权重归一化规则；缺失成分基金的处理；返回结构。

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
    case fundRealtime(codes: [String])
    case fundHistory(code: String, range: ClosedRange<Date>)
    case portfolioHistory(items: [(String, Int)], range: ClosedRange<Date>, benchmark: String)
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

- **GitHub URL**：`<<TODO: Elvis 在第一次让 Codex 进 backend 工作时贴 URL>>`
- **本地 clone 路径**：建议 `~/Developer/backtester_backend_readonly/`
- **关系**：只读参考，不进本仓 submodule。改 backend 直接在 GitHub repo 提 PR；本仓不收 backend 源代码。
- **理由**：单人项目避免 submodule 复杂度；契约（本文件）+ 线上服务（159.75.16.87）才是 iOS 客户端的依赖面，源码只是参考。

## 7. 开放问题（GPT 起草 v1.1 时回答）

1. **HTTPS**：Phase 4 上架前必须有 TLS。GPT 评估自签 / Let's Encrypt / Cloudflare。
2. **认证方案**：Pro StoreKit receipt → 后端验证 → 短期 token。具体协议 v1.1。
3. **TuShare / 数据源限流**：旧后端代理的下游 API 限流参数。
4. **数据源数据缺失策略**：基金停牌 / 节假日 / 数据延迟时返回什么。
5. **新基金未收录**：后端是否做 graceful 404；客户端如何展示。

---

## 8. Changelog

- v1 stub (2026-04-25) — 仅冻结路由 + Free/Pro 边界。字段 schema 待 GPT 补完 v1.1。
- v1 stub (2026-04-25) — 后端代码访问规则确定（§6）：GitHub URL 只读 clone，不进本仓 submodule。等 Elvis 贴 URL。
