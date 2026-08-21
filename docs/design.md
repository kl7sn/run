# /run design notes

Public summary of the workflow. Full rules live in `skills/run/SKILL.md`.

## Model

1. **Project** — `Projects/<NN-slug>/project.md`
2. **Workstream** — nested `Projects/<NN-slug>/<NN.MM-slug>/` with `workstream.md` + `tasks.md` + `context.md`
3. **Tasks** — rows in `tasks.md` (`todo` / `ready` / `doing` / `blocked` / `done`)

## Durable state

- **Workspace folder**: Markdown only. Obsidian optional.
- **`.run-state`**: per code-repo session index (`workspace`, `project`, `projects[]`, `session_id`).
- Prefer `~/…` or absolute paths; keep spaced paths (e.g. iCloud) consistent across all bind entries. After moving a vault, rewrite every bound repo’s state file.

## Quality

- Done requires verification evidence in `context.md` execution log.
- Illegal multiple `doing` (no parallel wave) is a hard block.
- Independent ready tasks may run in parallel via subagents; **only the parent writes workspace files**. Prefer worktree isolation for code edits.

## Auto mode

- `/run auto` keeps advancing ready work.
- Design gates (explore→plan, scheme choice, **mid-execute design docs**) use dual-agent consensus with a **mechanical preflight**: recorded verdict, `design-review:` status line, no idle “please confirm / continue”.
- Asking for human design confirmation under `auto=on` is a protocol error → correct in-turn via dual-agent review.
- True product forks (goal/non-goal change, capability removal, irreversible release/compliance) still full-stop; routine scoped design does not.

## Handoff

`context.md` uses **`## Handoff` as the only runtime section** (no separate “Current status”). Optional `## Gotchas` for long-lived constraints; `## Key Decisions` for decision history; `## Execution Log` for evidence.

`status: closed` ends the workstream. New durable work must **not** reopen it — `/run new` under the parent (or bind another active line). Binding a closed line while needing tasks/decisions/code is an abnormal bind / hard block.
