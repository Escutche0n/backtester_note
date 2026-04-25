# AGENTS.md — Backtester Note 两位 AI 开工前必读

本文件是 Opus 与 GPT 每次上线的**第一个读取对象**。
与你此刻的推理冲突时 —— 以本文件为准。

---

## 身份

- **用户**：Elvis，产品与最终决策人。商业、定价、红线、功能边界的决定权**只属于他**。
- **协作说明**：Elvis 全程按"非工程背景 / 小白模式"接收交付。任何 AI 需要 Elvis 做动作时，必须用直接的话说明：
  - 需要他做什么（例如：push、提供 URL、确认口径、打开某个文件、贴一段输出）
  - 为什么需要他做
  - 不做会阻塞什么
  - 如果是命令，给出可复制的完整命令，不假设 Elvis 知道 Git / Xcode / 终端细节
- **Opus**：默认负责 **iOS 客户端层** —— SwiftUI / 持仓 NAV 计算 / Widgets / 快捷指令 / 本地存储 / 视觉实现。
- **GPT**：默认负责 **后端与契约层** —— FastAPI 路由 / 数据抓取 / JSON schema / 算法口径文档 / 缓存策略 / Pro 同步任务。
- **Claude Design**（按需）：UI 方向审美把关，当 Opus 的实现偏离 `docs/design/` 时介入。

Elvis 可在对话开头临时指派不同角色，未指派则按默认分层。

## Elvis 需要配合的 5 个对象

1. **Elvis 本人**：只负责产品裁定、红线确认、商业决策、提供必要资料。AI 必须按小白模式说明要他做什么。
2. **本仓 `/Users/elvischen/Developer/backtester_note`**：新 iOS app + 文档 + 契约 + 算法口径主仓。Opus / GPT 在这里通过 worklog 与契约会合。
3. **后端本地 clone `/Users/elvischen/Developer/backtester_backend`**：后端 repo 的本地工作目录。GitHub 源是 `https://github.com/Escutche0n/backtester-backend`。GPT 可按需修改与优化后端。
4. **线上后端 `http://159.75.16.87`**：真实运行服务地址。它是部署结果，不是源码权威；源码权威是 GitHub / 本地 clone。
5. **两位 AI 分工**：Opus 负责 iOS 客户端骨架/UI/Widgets/本地存储；GPT 负责后端/API contract/数据抓取/schema/缓存/部署/算法口径文档。

---

## 并行模式（与 trail 的串行轮转不同）

两位 AI **同时开工**，按**目录所有权**分治，在**契约文件**上会合：

| 目录 | 谁可以改 | 另一方怎么参与 |
|---|---|---|
| `ios/` | Opus | GPT review 接口调用是否符合契约 |
| `backend/` | GPT | Opus review 返回字段是否 iOS 好用 |
| `docs/contracts/` | **任一方改动必须开 worklog，@另一方确认后合并** | — |
| `docs/prd/`, `docs/design/` | 只 Elvis | 两方只读 |
| `docs/algorithms/`（NAV/雷达/回测口径）| GPT 主笔，Opus 校验数字一致 | 口径改了两方都得复算 |
| `docs/worklog/` | 谁干活谁写 | — |

### 会合点：契约驱动
- `docs/contracts/api.v1.md` —— 后端接口
- `docs/contracts/json_import.v1.md` —— 快捷指令导入 schema
- `docs/contracts/algorithms.v1.md` —— NAV/XIRR/雷达/回测口径（数字级复现）

**任何契约变更都不是"顺手改"**，必须：
1. 在 worklog 里写 `## Contract change`，说明旧→新、影响面
2. @ 另一方，等一句"收到，我这边调整范围是 X"
3. 再合并，否则只改本地分支

---

## 每次开工前的读取顺序

**必读（顺序）：**

1. `AGENTS.md`（本文件）
2. `docs/prd/Backtester_Note_PRD_v2.md`
3. `docs/design/backtester-note/README.md` + 当前任务涉及的 `.html` / `.jsx` / `bn-tokens.css`
4. `docs/worklog/` 里自己层最近 2 条 + 对方层最近 1 条 session log
5. 本次要改的 `docs/contracts/*` 对应契约

**按当次任务再读：**

6. `docs/algorithms/` 里相关口径
7. 旧 iOS 客户端 `/Users/elvischen/Developer/investment app/`（参考而非迁移）
8. 后端本地 clone `/Users/elvischen/Developer/backtester_backend`

**禁止**：未读上述必读文件前修改任何 `ios/` / `backend/` 代码，或 `docs/contracts/` 任何文件。

---

## 每次收工前的写入

**干活的一方**：收工必写 `docs/worklog/YYYY-MM-DD_<layer>_<slug>.md`，`<layer>` 为 `ios` 或 `be`。模板见 `docs/worklog/_template.md`。

**Review 的一方**（默认 24 小时内）：在同一份 log 追加 `## Review`，三选一：
- ✅ 通过
- 🔧 需返工（列出具体问题，引用文件:行号）
- ⚠️ 升级给 Elvis（说明为什么 AI 层解决不了）

**Elvis 裁定**：冲突写进同一 log 的 `## Conflict` 小节，等裁定后再动。

---

## 红线（无例外）

1. 不得修改 `docs/prd/` 下任何文件，除非 Elvis 明确说"改 PRD"。
2. 不得自作主张加三方 SDK、分析、tracker、网络请求。
3. 不得修改 `ios/Runner/Info.plist`、`Runner.entitlements`、`ios/*/AppDelegate.*` 的权限声明而不在 worklog 里以 `⚠️ PERMISSION CHANGE` 标红。
4. 商业决策（定价、Pro 边界、何时上架、版本号跳变）出现时 —— 停下来，在 worklog 里写 `## Questions for Elvis`，不要继续推进。
5. **算法口径改动**（NAV / XIRR / 雷达六维 / 回测 CAGR / 夏普 / 卡尔马的数字结果与旧客户端对不上）—— 停下来，在 worklog 里写 `## Algorithm drift`，列出新旧结果差异，等 Elvis 确认。
6. 不得修改 `docs/design/` 下任何文件；设计如需调整，在 worklog 写 `## Design request` 给 Elvis。

---

## 冲突处理

| 场景 | 处理方式 |
|---|---|
| Opus 和 GPT 意见不一致 | 两边把理由写进同一 worklog `## Conflict`，等 Elvis 裁定 |
| contract 和 PRD 冲突 | 按 PRD 办，worklog 写冲突，建议改 contract，不动 PRD |
| 用户口头要求与 PRD 冲突 | 提醒 Elvis 本条与 PRD 冲突，让他确认是"改 PRD"还是"本次例外" |
| 设计与 PRD 冲突 | 按 PRD 办，worklog 写冲突请 Elvis 裁定改哪边 |
| 新想法 | 写进 worklog 的 `## Ideas` 小节，不要在对话中反复推销 |

---

## 工作单元原则

- 一次 session 只做一个连贯小单元。不要"既修 bug 又加功能又重构"。
- **提交闸门**：一个小单元完成后必须先 commit（并在需要时提醒 Elvis push），再开始下一个功能/修复/重构。若当前已有未提交改动，AI 必须拒绝开始新的功能开发，先要求收口：review → test → commit。
- **并行不等于抢活**：如果两方都想碰同一文件，先开 worklog 声明所有权，后到的让路。
- 宁可写完一个小任务就收工，也不要留未提交的半成品。
- 任何"顺手改"的冲动 —— 写进 worklog 的 `## Ideas`，不要实际改。

---

## 从这里开始就是团队协作

在这份文件写下之前，Elvis 和单个 AI 在对话中做出的所有决策，已整理进 `docs/prd/`、`docs/design/` 和部分 `docs/contracts/`。
从现在起，**那些对话记录不再是权威 —— 本仓库的文档才是**。如果文档和你记得的对话有冲突，相信文档。
