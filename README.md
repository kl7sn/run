# `/run`

### Durable execution for coding agents

Agents are good at writing code. They are bad at **remembering where they left off**, **proving work is done**, and **not quietly abandoning the plan**.

`/run` is a skill protocol for Cursor, Claude Code, and Codex that turns multi-step engineering into a recoverable loop:

**bind a workstream → keep state in Markdown → verify before done → hand off cleanly.**

No control plane. No SaaS. One workspace folder. Optional Obsidian.

<br>

```text
  ┌─────────────────────────────────────────────────────────────┐
  │  project          workstream           tasks                │
  │  01-demo/    →    01.01-hello/    →    T01 · T02 · T03…     │
  │  project.md       workstream.md        tasks.md             │
  │                   context.md           Handoff · evidence   │
  └─────────────────────────────────────────────────────────────┘
                         ▲
                         │  .run-state  (session bind in the git repo)
                         │
                    your codebase
```

<br>

[![License: MIT](https://img.shields.io/badge/license-MIT-0a0a0a?style=flat-square)](LICENSE)
[![Agents](https://img.shields.io/badge/agents-Cursor%20·%20Claude%20·%20Codex-111111?style=flat-square)](#install)
[![State](https://img.shields.io/badge/state-Markdown%20workspace-222222?style=flat-square)](#workspace)
[![中文](https://img.shields.io/badge/docs-%E4%B8%AD%E6%96%87-333333?style=flat-square)](README_CN.md)

---

## Positioning

| `/run` is | `/run` is not |
| --- | --- |
| A **session-sticky** workflow skill | A hosted agent platform |
| Durable state in **plain Markdown** | Another issue tracker you must live in |
| Verification before `done` | “Looks good” vibes |
| Unattended advance with hard stops | Blind overnight force-push |

Built for people who already use agents daily — and keep losing the thread between chats, tools, and weekends.

---

## Core ideas

**Three layers.** Project → workstream → fine tasks. The workstream is the execution unit; the project is the container.

**Single writer.** Parallel subagents may change code (preferably in worktrees). Only the parent `/run` writes `tasks.md` / `context.md` / `.run-state`.

**Handoff over chat archaeology.** Resume from a bounded `## Handoff` block — not from scrolling yesterday’s transcript.

**Auto with teeth.** `/run auto` keeps ready tasks moving. Design gates go through dual-agent consensus. Irreversible git, product forks, and true ambiguity still hard-stop.

**Session sticky.** If the repo is already bound, follow-up “quick fixes” stay inside `/run`. No silent fall-back to ad-hoc coding.

---

## Install

```bash
git clone https://github.com/kl7sn/run.git
cd run
```

Symlink the skill into your agent:

| Agent | Command |
| --- | --- |
| **Cursor** | `ln -sf "$(pwd)/skills/run" ~/.cursor/skills/run` |
| **Claude Code** | `ln -sf "$(pwd)/skills/run" ~/.claude/skills/run` |
| **Codex** | `ln -sf "$(pwd)/skills/run" ~/.codex/skills/run` |

Or use [`install.sh`](install.sh).

Then in a repo: `/run init` → `/run new` → `/run`.

---

## Workspace

State lives in a normal directory. Obsidian is optional.

**Resolution order**

1. `workspace:` in the repo’s `.run-state`
2. `RUN_WORKSPACE`
3. `~/run-workspace`

```text
~/run-workspace/
└── Projects/
    └── 01-demo/                 # project  NN-<slug>
        ├── project.md
        └── 01.01-hello/         # workstream  NN.MM-<slug>
            ├── workstream.md
            ├── tasks.md
            ├── context.md       # Handoff · Gotchas · decisions · evidence
            └── spec.md          # optional
```

Minimal sample: [`examples/01-demo/`](examples/01-demo/).  
Templates: [`templates/`](templates/).

---

## Commands

| | |
| --- | --- |
| `/run init` | Create the project container |
| `/run new` | Nest a workstream under the project |
| `/run bind` | Rebind this session interactively |
| `/run` | Advance explore → plan → execute |
| `/run auto` | Unattended advance |

Status line (every advancing reply):

```text
[/run · auto=off · 01-demo/01.01-hello · T01 ready]
```

Repo index (git root):

```yaml
workspace: ~/run-workspace
project: 01.01-hello
repo: .
```

---

## Protocol depth

The README is the front door. The skill is the law.

| Document | Role |
| --- | --- |
| [`skills/run/SKILL.md`](skills/run/SKILL.md) | Full agent protocol |
| [`docs/design.md`](docs/design.md) | Design notes & tradeoffs |
| [`README_CN.md`](README_CN.md) | 中文说明 |

---

## License

[MIT](LICENSE) · [kl7sn/run](https://github.com/kl7sn/run)
