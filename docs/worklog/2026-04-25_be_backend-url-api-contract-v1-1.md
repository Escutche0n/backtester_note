# 2026-04-25 · be · backend-url-api-contract-v1-1

**Agent**: GPT
**Role**: Dev
**Scope**: Elvis 提供后端 GitHub URL 后，核对后端真实 FastAPI schema，并更新本仓 API contract v1.1。

## What changed

- `docs/contracts/api.v1.md`：标题从 stub 更新为 v1.1。
- `docs/contracts/api.v1.md`：记录后端 GitHub URL `https://github.com/Escutche0n/backtester-backend`。
- `docs/contracts/api.v1.md`：记录已核对后端 commit `926c912 add portfolio realtime endpoint`。
- `docs/contracts/api.v1.md`：修正 `GET /api/fund/search` response 为真实 `keyword/source/items` 结构。
- `docs/contracts/api.v1.md`：修正 `GET /api/fund/realtime` 为单 `code` 参数，response 为 `{ data: FundRealtimeData }`。
- `docs/contracts/api.v1.md`：修正 `GET /api/fund/history` response 为 `fund_code/fund_name/fund_type/source/points` 结构。
- `docs/contracts/api.v1.md`：新增 `POST /api/portfolio/realtime` schema。
- `docs/contracts/api.v1.md`：标记 `POST /api/portfolio/history` 当前仍是 mock，iOS 不得用于生产展示。
- `docs/contracts/api.v1.md`：补充当前部署现状：Elvis 手动下载后端文件上传服务器运行，后续应优化为可重复部署流程。

## Contract change

- 契约：`docs/contracts/api.v1.md`
- 旧 → 新：
  - `fund/realtime`：多 `codes` 参数 → 单 `code` 参数。
  - response wrapper：旧文档假设 `{ code, data }` → 真实后端 schema。
  - 新增 `portfolio/realtime`。
  - `portfolio/history` 明确为 mock。
- 影响面：
  - Opus 实现 `ios/Networking/Endpoints.swift` 时必须按 v1.1，不要按旧 stub。
  - Holdings Pro 盘中估值应优先考虑 `portfolio/realtime`，或并发调用单基金 `fund/realtime`。
  - 回测 / 组合历史不能依赖后端 `portfolio/history`，直到 GPT 替换 mock。
- 通知对方状态：⏳ 待 Opus review。

## Algorithm drift

无。

## Review

- ⏳ 等 Opus review：
  - v1.1 schema 是否方便 iOS Codable 建模。
  - `portfolio/realtime` 是否满足 Holdings 首屏盘中估值需要。

## Questions for Elvis

后端部署目前是手动上传服务器。建议后续让 GPT 在后端 repo 做第一轮部署优化，目标是让你只需要执行一条明确命令或直接 `git pull` 后重启服务，而不是手动传文件。

## Next

- [ ] GPT 后续进入 `backtester-backend` repo，优先补部署文档 / systemd 或 Docker 方案。
- [ ] GPT 后续把 `POST /api/portfolio/history` 从 mock 替换成真实基金历史聚合。
- [ ] Phase 3 前补 HTTPS 与认证方案。
