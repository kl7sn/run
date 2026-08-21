# /run design notes

Public summary of the workflow. Full rules live in `skills/run/SKILL.md`.

## Model

1. **Project** — `Projects/<NN-slug>/project.md`
2. **Workstream** — nested `Projects/<NN-slug>/<NN.MM-slug>/` with `workstream.md` + `tasks.md` + `context.md`
3. **Tasks** — rows in `tasks.md` (`todo` / `ready` / `doing` / `blocked` / `done`)

## Durable state

- **Workspace folder**: Markdown only. Obsidian optional.
- **`.run-state`**: per code-repo session index (`workspace`, `project`, `projects[]`, `session_id`).

## Quality

- Done requires verification evidence in `context.md` execution log.
- Illegal multiple `doing` (no parallel wave) is a hard block.
- Independent ready tasks may run in parallel via subagents; **only the parent writes workspace files**. Prefer worktree isolation for code edits.

## Auto mode

- `/run auto` keeps advancing ready work.
- Design-approval gates use dual-agent consensus (author + reviewer), not “please reply continue”.
- Irreversible git / true product forks still stop the whole run.

## Handoff

`context.md` uses **`## Handoff` as the only runtime section** (no separate “Current status”). Optional `## Gotchas` for long-lived constraints; `## Key Decisions` for decision history; `## Execution Log` for evidence.
