# `/run`

### 面向 Coding Agent 的可恢复执行协议

Agent 擅长写代码。它们不擅长：**记住做到哪了**、**证明做完了**、**不悄悄丢掉计划**。

`/run` 是给 Cursor / Claude Code / Codex 用的 skill 协议，把多步工程收成可恢复闭环：

**绑定 workstream → 状态落在 Markdown → done 前验证 → 干净交接。**

没有控制面，没有 SaaS。一个 workspace 文件夹。Obsidian 可选。

<br>

```text
  ┌─────────────────────────────────────────────────────────────┐
  │  project          workstream           tasks                │
  │  01-demo/    →    01.01-hello/    →    T01 · T02 · T03…     │
  │  project.md       workstream.md        tasks.md             │
  │                   context.md           Handoff · evidence   │
  └─────────────────────────────────────────────────────────────┘
                         ▲
                         │  .run-state  （代码仓内的会话绑定）
                         │
                    your codebase
```

<br>

[![License: MIT](https://img.shields.io/badge/license-MIT-0a0a0a?style=flat-square)](LICENSE)
[![Agents](https://img.shields.io/badge/agents-Cursor%20·%20Claude%20·%20Codex-111111?style=flat-square)](#安装)
[![State](https://img.shields.io/badge/state-Markdown%20workspace-222222?style=flat-square)](#workspace)
[![English](https://img.shields.io/badge/docs-English-333333?style=flat-square)](README.md)

---

## 定位

| `/run` 是 | `/run` 不是 |
| --- | --- |
| **会话粘性**工作流 skill | 托管 Agent 平台 |
| 写在**纯 Markdown**里的 durable state | 又一个必须常住的 Issue 系统 |
| `done` 前的验证门禁 | 「看起来没问题」 |
| 带硬停机的无人值守推进 | 盲目连夜 force-push |

给已经天天用 Agent、却总在聊天窗口之间丢线的人用。

---

## 核心主张

**三层模型。** Project → workstream → 细任务。执行单元是 workstream；项目只是容器。

**单写者。** 并行 subagent 可改代码（优先 worktree）；只有父 `/run` 写状态。**关线前须在 worktree 上人工冒烟**——仅靠自动化测试不够。

**集成闸。** 全部 task `done` ≠ workstream 可关。须登记 worktree 路径/分支、通过人工冒烟（或明确豁免），再选 merge / PR / 保留 / prune——禁止静默遗留 orphan worktree。

**Handoff 优于考古聊天记录。** 续跑先读有界的 `## Handoff`，而不是翻昨天的 transcript。

**带硬停机的 Auto。** `/run auto` 持续推进 ready；设计闸必须双 agent 共识并留下 verdict 记录（禁止干等「请确认」）；仅不可逆 git、真产品分叉、真歧义整段停。

**会话粘性。** 后续工程必须绑在 **active** workstream 上。已关闭的线禁止撬开补录——应 `/run new`（或绑定其他 active 线）。禁止静默降级成普通局部开发。

---

## 安装

```bash
git clone https://github.com/kl7sn/run.git
cd run
```

软链到各端：

| Agent | 命令 |
| --- | --- |
| **Cursor** | `ln -sf "$(pwd)/skills/run" ~/.cursor/skills/run` |
| **Claude Code** | `ln -sf "$(pwd)/skills/run" ~/.claude/skills/run` |
| **Codex** | `ln -sf "$(pwd)/skills/run" ~/.codex/skills/run` |

或使用 [`install.sh`](install.sh)。

然后在仓库里：`/run init` → `/run new` → `/run`。

---

## Workspace

状态在普通目录里。不强制 Obsidian。

**路径优先级**

1. 代码仓 `.run-state` 的 `workspace:`
2. `RUN_WORKSPACE`
3. `~/run-workspace`

```text
~/run-workspace/
└── Projects/
    └── 01-demo/                 # 项目  NN-<slug>
        ├── project.md
        └── 01.01-hello/         # 任务包  NN.MM-<slug>
            ├── workstream.md
            ├── tasks.md
            ├── context.md       # Handoff · Gotchas · 决策 · 证据
            └── spec.md          # 可选
```

示例：[`examples/01-demo/`](examples/01-demo/)  
模板：[`templates/`](templates/)（`*.md` 英文，`*.zh.md` 中文）。用 `/run lang en|zh` 切换文档语言。

---

## 命令

| | |
| --- | --- |
| `/run init` | 建项目容器 |
| `/run new` | 在项目下建 workstream |
| `/run bind` | 交互重绑本会话 |
| `/run lang` [en\|zh] | 查看或设置文档语言 |
| `/run` | 推进 explore → plan → execute |
| `/run auto` | 无人值守推进 |

状态行（每次推进回复开头）：

```text
[/run · lang=zh · auto=off · 01-demo/01.01-hello · T01 ready]
```

代码仓索引（git 根目录）：

```yaml
workspace: ~/run-workspace
lang: zh
project: 01.01-hello
repo: .
```

---

## 协议深度

README 是门面。Skill 才是完整法则。

| 文档 | 作用 |
| --- | --- |
| [`skills/run/SKILL.md`](skills/run/SKILL.md) | 完整 Agent 协议（英文） |
| [`docs/design.md`](docs/design.md) | 设计说明与取舍 |
| [`README.md`](README.md) | English |

---

## License

[MIT](LICENSE) · [kl7sn/run](https://github.com/kl7sn/run)
