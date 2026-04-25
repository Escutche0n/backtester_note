# 2026-04-25 · be · commit-gate-rule

**Agent**: GPT
**Role**: Dev
**Scope**: 把 Elvis 确认的“完成一个 commit 再开始下一个功能”原则写入 AGENTS.md。

## What changed

- `AGENTS.md`：在 `## 工作单元原则` 增加 **提交闸门**：
  - 一个小单元完成后必须先 commit，再开始下一个功能/修复/重构。
  - 如已有未提交改动，AI 必须拒绝开始新功能开发，先收口 review / test / commit。
  - 需要 push 时要提醒 Elvis。

## Contract change

无。

## Algorithm drift

无。

## Next

- [ ] 后续所有工作遵守 commit gate。
