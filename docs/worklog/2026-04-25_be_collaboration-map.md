# 2026-04-25 · be · collaboration-map

**Agent**: GPT
**Role**: Dev
**Scope**: 把 Elvis 确认的五方协作地图写入 AGENTS / README / architecture / API contract。

## What changed

- `AGENTS.md`：新增 “Elvis 需要配合的 5 个对象”，明确 Elvis、本仓、后端本地 clone、线上后端、两位 AI 分工。
- `AGENTS.md`：把旧后端读取路径更新为 `/Users/elvischen/Developer/backtester_backend`。
- `README.md`：新增协作地图表。
- `docs/architecture/overview.v1.md`：明确后端 GitHub / 本地 clone 是源码权威，`159.75.16.87` 是部署结果。
- `docs/contracts/api.v1.md`：把后端本地 clone 路径更新为 `/Users/elvischen/Developer/backtester_backend`。

## Contract change

无接口字段变更；仅补充后端源码位置与部署关系。

## Algorithm drift

无。

## Next

- [ ] Elvis push 本次文档更新。
- [ ] Opus 按最新 AGENTS / README 接手 iOS review 与 Phase 1b。
- [ ] GPT 后续在 `/Users/elvischen/Developer/backtester_backend` 优化部署与 `portfolio/history`。
