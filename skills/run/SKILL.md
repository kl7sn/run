---
name: run
description: Unified workflow entry. Auto-detect phase (explore/plan/execute/recover) with durable state in a configurable Markdown workspace folder (Obsidian optional). Supports nested projects/workstreams, /run init, /run new, /run bind, /run auto. When a repo already has a .run-state binding, follow-up engineering requests in the same session must restore the binding and update the workspace—never fall back to ad-hoc local coding. Triggers: /run, /run auto, /run init, /run new, /run bind, continue work, resume, start implementation, unattended, and follow-up code/bug/feature work on a bound repo.
---

# /run — Unified workflow

## Overview

`/run` is the single entry for complex software work. It detects the current phase and keeps advancing until all tasks are done or a hard block is hit.

**Goal:** advance engineering tasks automatically while enforcing verification for code quality.

Core loop: **read state → choose phase → execute → self-review → update state → continue**

- Plain `/run`: auto-continues when tasks are ready; may still ask on explore ambiguity or design confirmation.
- **`/run auto`**: unattended mode—do not ask “continue to next?”; **design/plan gates** use dual-agent consensus, then continue; only non-decidable hard blocks stop the whole run.

### Session sticky (do not degrade to ad-hoc coding)

**Failure mode:** the repo already has `.run-state` bound to a workstream, but later requests are treated as ordinary local edits—no `/run` restore and no updates to workspace `tasks.md` / `context.md`.

**Hard rule:** if a valid `.run-state` resolves to a **workstream** binding (this session’s `session_id` matches, or top-level `workspace` points at a workstream folder), then any request that changes code / fixes bugs / adds features / lands diagnostics **must**:

1. Run the recover protocol (read `.run-state` → `tasks.md` + `context.md` + homepage)
2. Map the request to an existing ready/doing task, or **add** a `tasks.md` row then claim it (never change code without accounting)
3. Update durable state during/after work (status, Done evidence, decisions/log in `context.md`)

**Forbidden:**

- “Tiny change / quick debug” → skip binding and workspace
- Saying “I’ll fill tasks later” while still editing code
- Starting a new explore doc stream that detaches from the bound workstream

**Only exemptions** (say explicitly “not using /run this turn”):

- User opts out of `/run`, asks concepts only, read-only code review, or a one-off aside
- Pure Q&A with no file writes

If you already skipped accounting: stop ad-hoc work; recover; backfill tasks in real order (label “recovery backfill”); **do not fake** the original ready→doing timeline; then continue.

## Commands

| Command | Purpose |
|---|---|
| `/run init` [projectId] | Create **project container only** (layer 1) |
| `/run new` [workstreamId] | Create nested **workstream** under parent (layer 2); stop by default (no auto execute) |
| `/run bind` | Interactively rebind this session to a workstream / project / new |
| `/run` | Advance explore/plan/execute/recover; auto-continue when ready |
| `/run auto` | **Unattended**: keep ready tasks flowing; design confirmation → dual-agent consensus then continue; true hard blocks stop |

## Workspace (durable state directory)

`/run` stores task state in a normal folder of Markdown files. Obsidian is optional—any Markdown editor works.

Path priority (high → low):

1. `workspace:` in the code repo’s `.run-state`
2. Env `RUN_WORKSPACE`
3. Default: `~/run-workspace`

Recommended layout:

```text
<workspace>/
└── Projects/
    └── <projectId>/
        ├── project.md
        └── <workstreamId>/
            ├── workstream.md
            ├── tasks.md
            ├── context.md   # Handoff / Gotchas
            └── spec.md      # optional
```

Example `.run-state`:

```yaml
workspace: ~/run-workspace
project: 01-demo/01.01-hello
repo: .
```

## Three-layer model (project / workstream / tasks)

| Layer | Entity | Workspace path | `/run` behavior |
|---|---|---|---|
| 1 | Project | `Projects/<projectId>/project.md` (`type: project`) | Business container; may hold many workstreams |
| 2 | Workstream | `Projects/<projectId>/<workstreamId>/workstream.md` (`type: workstream` + `parent`) | **Normal execution unit**; `.run-state` binds this folder |
| 3 | Fine task | Rows in workstream `tasks.md` (T01 / R5…) | Claim `doing` → verify → `done` |

```text
Projects/
├── 01-demo/                          # project NN-<slug>
│   ├── project.md                    # type: project (fixed name)
│   ├── 01.01-init/                   # workstream NN.MM-<slug>
│   │   ├── workstream.md             # type: workstream, parent: 01-demo
│   │   ├── spec.md / tasks.md / context.md
│   │   └── ...
│   └── 01.02-publish/
└── 02-other-app/
    └── 02.01-bootstrap/
```

### Homepage filenames

| Layer | Fixed filename | Template |
|---|---|---|
| Project | `project.md` | `templates/project.md` |
| Workstream | `workstream.md` | `templates/workstream.md` |

Compatibility: if a legacy homepage file exists, read its `type`; **new work always uses `project.md` / `workstream.md`**.

Resolve homepage in a bound folder (first hit wins):

1. `project.md`
2. `workstream.md`
3. Legacy homepage aliases if present

### Numbered naming (required for new entities)

Folder names / `project` fields start with numbers for sort order and hierarchy:

| Layer | Format | Example | Allocation |
|---|---|---|---|
| Project | `NN-<slug>` | `01-demo` | Scan `Projects/` for `NN-*`, take max NN+1 (two digits from 01) |
| Workstream | `NN.MM-<slug>` | `01.02-publish` | **NN = parent project number**; MM = max `NN.MM-*` under that project + 1 |

Rules:

- `/run init` / `/run new` **must** produce numbered ids; slug-only input gets a number; full ids are validated for conflicts.
- `parent` / `parent_project` store the **full** project id (with number), e.g. `01-demo`.
- Unnumbered legacy folders may keep working; **do not rename** unless the user asks.
- Fine tasks stay as table ids (`T01`), not folder names.

- Optional boards: build your own views (e.g. Obsidian Bases); see `docs/design.md`.
- **One window, one binding:** never advance multiple workstreams in one session. Switch via `/run bind`, a new session, or editing `.run-state`.
- **One repo, many workstreams:** one git repo + one `.run-state`; distinguish with `projects[]` + `session_id`; ambiguity → interactive bind.
- `/run` only advances that workstream’s `tasks.md`; no dependency on a specific notes plugin.
- Flat legacy layouts remain readable; **new work uses nested directories**. Optional archive under `Projects/_archive/`.

### Detect project vs workstream binding

Authoritative signal: homepage frontmatter (`type` / `parent`)—**not** path depth or mere presence of `tasks.md`.

1. Read `.run-state` `workspace` for this session.
2. Resolve homepage; read `type` / `parent` / `title`:
   - **`type: workstream`** → workstream; parent = **`parent`** (required; missing → hard block).
   - **`type: project`** → project; parent = **self**.
3. Missing homepage/`type` → weak inference: if path is `Projects/<a>/<b>/` and `<a>/project.md` exists, treat `<a>` as parent; else ask.

### Read homepage (start / recover)

When a homepage exists:

1. **`type: workstream`:** set/update `parent_project: <parent>` in `context.md` → `## Handoff`.
2. **`type: project`:**
   - If this folder’s `tasks.md` has ready/doing → execute normally (legacy parent-with-tasks).
   - If no ready/doing → **do not** empty-run explore / treat as brand-new repo init. List child workstreams; suggest `/run bind` or `/run new`.
3. Other / missing type: no extra constraints.

## Data sources

The workspace folder is the only durable state (plain Markdown; Obsidian/VS Code/any editor). The code repo keeps only `.run-state` as the session index.

One code repo may map to many workstreams. Each conversation binds one workstream folder.

### `.run-state` (code repo root)

Session index at the repo root. If a legacy `.k-state` exists and `.run-state` does not, **rename once** to `.run-state` (rename field `obsidian:` → `workspace:` if present); afterwards maintain only `.run-state`.

```yaml
workspace: <workspace>/Projects/<projectId>/<workstreamId>
project: <workstreamId>
repo: <primary-repo-module-path>
binding_policy:
  priority:
    - use_saved_session_project_binding
    - interactive_bind_when_ambiguous
    - infer_from_current_conversation_context
    - create_via_run_new_or_init
  note: One repo may have many workstreams; prefer session_id on recover; if >=2 candidates and no session bind, interactive choose—never silently rebind.
projects:
  - project: <workstreamId>
    session_id: <thread-or-session-id>
    workspace: <workspace>/Projects/<projectId>/<workstreamId>
    parent_project: <projectId>
    repo: <primary-repo-module-path>
    status: current | active | completed | archived
    note: <date + short task summary>
```

Prefer a stable env session id (e.g. `CODEX_THREAD_ID`); if unavailable write `unknown` and fill later.

### Workstream folder (execution unit)

```
.../Projects/<projectId>/<workstreamId>/
├── workstream.md
├── spec.md
├── tasks.md
├── context.md
└── open-review.command
```

Project container:

```
.../Projects/<projectId>/
├── project.md
└── <workstreamId>/
```

## Interactive bind protocol

**Auto-bind (no ask)**

- This `session_id` already matches `.run-state.projects[]`
- User command has a unique target (`/run new billing`, context points at one workstream)

**Must interact (list options)**

- No session bind and ≥2 known workstreams
- `/run new` cannot uniquely resolve parent project
- Top-level bind conflicts with session records
- User runs `/run bind` / “switch workstream”

**Option template:**

```text
Multiple workstreams found for this repo. Choose a bind:

1. <projectId>/<ws-a>  — <summary> (status, last task)
2. <projectId>/<ws-b>  — ...
3. [new] /run new <name>
0. [parent project] <projectId>  — browse only, do not execute
```

After choice → write `.run-state` (top-level + `projects[]`) → continue. Inference may sort/highlight only—**never silent rebind**. Remember for the session; switch again with `/run bind`.

## Startup flow

1. Read repo `.run-state`; get session id
2. **Subcommands first:**
   - `/run init` → project init protocol
   - `/run new` → new workstream protocol
   - `/run bind` → interactive bind, then stop or continue
   - `/run auto` → recover bind, enter Auto mode, advance
3. If `projects[]` matches `session_id` → use it and sync top-level entry
4. If no session bind → unique candidate OK; **≥2 → interactive bind** (in auto, cannot uniquely bind → **full stop**); zero candidates → guide `/run init` or `/run new`
5. Read bound `tasks.md` + `context.md`; homepage rules apply
6. If this turn is `/run auto` (or Handoff `auto_mode: true` and not exited) → keep `auto_mode: true`, follow Auto rules
7. Else route:

| Condition | Phase |
|---|---|
| Explicit `/run init` | Create project container |
| Explicit `/run new` | Create nested workstream |
| No bind but need to advance | Interactive bind or guide init/new |
| Bound project with no ready/doing | **Guide**: list child workstreams |
| `tasks.md` all todo | **Plan** |
| Ready tasks | **Execute** |
| Blocked only | **Report** blockers |
| All done | **Complete** |
| Workstream without `tasks.md` | **Explore/plan** (do not run project-only init) |

> Compat: bare `/run` on a brand-new repo → ask “`/run init` project or `/run new` under existing?”. Never treat “existing project, new line of work” as full init.

## Three phases

### Explore

Trigger: new work described; design missing/incomplete; workstream already bound.

Deliver `spec.md` (or link). Self-review: core coverage, unresolved ambiguity, clear constraints.

### Plan

Trigger: design exists but no `tasks.md`, or all rows are todo.

Split into executable tasks with bounds, depends, acceptance, optional blockers; write `tasks.md`; ensure ≥1 ready.

Self-review: clear boundaries, acyclic depends, at least one ready, no hidden product forks inside tasks.

### Execute

Trigger: ready tasks exist.

- Choose the wave via parallel protocol (serial one or parallel many)
- Parent claims `ready → doing` (**parent alone writes workspace**)
- Implement: parent solo, or **subagents** (prefer worktree isolation for code)
- Force `verification-before-completion` before each done
- Parent records `doing → done` + Done evidence
- Recompute depends/blockers; continue next wave if ready and no hard block

Per-task self-review: verification passed; no silent scope creep; evidence written; durable state updated.

## Parallel execution (subagents + single workspace writer)

Inspired by Claude: isolate code in parallel; **only parent `/run` writes workspace**, so agents do not race `tasks.md` / `context.md`.

### Who writes what

| Role | Allowed | Forbidden |
|---|---|---|
| **Parent `/run`** | Read/write `.run-state`, `tasks.md`, `context.md`, homepages; dispatch/collect subagents; merge verification | Letting a subagent “also update workspace state” |
| **Subagent** | Edit code, run tests, return summary (paths, verify cmds/results, failures) | Write workspace; edit `.run-state`; claim/edit other task rows |

### When to parallelize

On the workstream’s ready set:

1. Dependency graph: if A depends (directly/indirectly) on B, they cannot share a wave.
2. **Parallel candidates:** pairwise independent ready tasks.
3. **Conservative serial** even without depends: same package/dir/entry file, or unclear boundaries—default serial without worktrees.
4. Auto mode may parallelize eligible sets; human gates / hard blocks still **full-stop** (no skipping).

### One parallel wave (parent)

1. Pick `T_a, T_b, …` (usually 2–4)
2. Mark all `doing` in `tasks.md` first; update Handoff `current_tasks` / `updated`
3. One subagent per task; prompt = that row + acceptance + file bounds; fixed result shape
4. Code-changing agents: prefer worktree isolation; else **degrade to serial**—do not multi-write one tree
5. After collect, parent **serially** writes workspace: verify → done/blocked/revise + evidence
6. Failed branch → revise/blocked; successful ones may still done; then next wave
7. Merge worktrees/branches in order; conflict → hard block / escalate

### When multiple `doing` is illegal

- **Legal:** current parallel wave claims
- **Illegal / hard block:** multiple `doing` without wave record; `doing` rows depend on each other; recover finds multiple `doing` without parallel-wave note → ask how to converge

## Execute load protocol

`phase: execute` is **read-only by default**:

1. Current task row in `tasks.md` (+ direct depends if needed)
2. `## Handoff` + `## Gotchas` + recent related execution log
3. Code/config **required** for this task

**Forbidden:** reread full `spec.md` / whole project every turn. Open spec sections only when acceptance cites them or implementation conflicts with spec.

## Quality gate (Done evidence)

Before `doing → done`:

1. Follow `verification-before-completion` (or equivalent compile/test/checks).
2. Append evidence to `context.md` → Execution Log:

```markdown
- <task-id> done: <one-line summary> | paths: <changed paths> | verify: <cmd or check> → <result>
```

3. Verify fail / cannot verify → `review_status: revise`; **must not** mark done or claim next task.
4. No tests but repo norms require them → escalate.

On recover: `done` without verify evidence → verify first.

## Auto-advance rules

**Batch done ≠ workflow done. If ready tasks exist and no hard block, continue.**

After each task:

1. Update `tasks.md` + `context.md` (evidence + **refresh Handoff**)
2. All-depends-done `todo` → `ready`
3. Blocker upstream done / cleared → `blocked` → `ready`
4. Check hard blocks
5. If ready and no hard block → next immediately
6. All done → report complete
7. Blocked with no ready → report blockers

**Forbidden stop reasons:** “Tn done, Tn+1 ready”, “state synced”, “can continue later” (unless user asks to pause or “only this one”).

## Auto mode (`/run auto` — unattended)

For overnight/unattended runs in **one session + one workstream bind**.

**On:** `/run auto`, or “unattended” / “keep going overnight”. Set Handoff `auto_mode: true`.  
**Off:** “exit auto” / “stop unattended”, or plain `/run` with explicit exit; set `auto_mode: false`.  
**Scope:** no out-of-session heartbeat control plane. If the session dies, user restarts `/run auto`.

### In-chat status line (required)

On `/run` recover/advance (including sticky engineering turns), prefix replies:

```text
[/run · auto=on · 01-demo/01.01-hello · T03 doing]
```

or:

```text
[/run · auto=off · 01-demo/01.01-hello · blocked: waiting on design approval]
```

| Segment | Meaning |
|---|---|
| `auto=on` / `auto=off` | Handoff `auto_mode` (default off) |
| Path | `<projectId>/<workstreamId>` |
| Tail | `Tn doing` / `T01+T02 doing` / `blocked: …` / `done` / `idle` |

Rules: every code/task-advancing reply; tiny acks may omit; on enter/exit auto, also say “auto enabled/disabled”; full-stop summaries use the same prefix.

### vs plain `/run`

| Point | `/run` | `/run auto` |
|---|---|---|
| Continue ready | yes | yes (no “continue Tn+1?”) |
| Optional explore questions | may ask | prefer decide from spec; else dual-agent; else hard stop |
| Design confirmation (“review then reply continue”) | ask user | **forbidden idle wait** → dual-agent consensus then plan/implement |
| Build/test fail | self-fix | same (`revise`) |
| Irreversible git / bind ambiguity / true product fork | stop | same full-stop |
| All done / only non-decidable blocked | report | report and end auto wave |

### Dual-agent consensus review (`auto_mode: true` only)

Replaces “design done → wait for human continue” (explore→plan, scheme choice, post-spec gate).

| Role | Duty | Workspace |
|---|---|---|
| **Author agent** | Produce/revise design; apply review issues | Do not race-write; parent records |
| **Reviewer agent** (subagent) | Read-only: goals/non-goals, safety, testability, tasks acceptance fit, hidden tradeoffs | **Must not** write workspace / `.run-state` |
| **Parent `/run`** | Dispatch, round limits, write `context.md`, unlock tasks, continue | **Sole writer** |

Flow:

1. Author states design path + task to unlock (if any).
2. Parent dispatches reviewer; required output:

```yaml
verdict: approve | revise | escalate
issues: []
blocking_reasons: []
summary: "one line"
```

3. **`approve`:** parent records consensus; design-wait `blocked` → `ready`; **do not** ask “continue”; enter plan/TDD.
4. **`revise`:** author updates; max **2** revise cycles; still revise → `escalate` full-stop.
5. **`escalate`** or deadlock: full-stop with blocker (both sides’ points)—morning human gate.

Reviewer minimum checks: goals vs non-goals; secrets never logged; failure modes; TDD-ready contracts; product forks disguised as settled tech → `escalate`.

Forbidden: idle “please review, reply continue”; coding before approve; fake “default scheme A” consensus; reviewer writing tasks/context.

### Full-stop (required)

1. Update `tasks.md` (blocked/machine-readable Blocker)
2. Write/refresh **Handoff** (`auto_mode`, blocker, next, `resume_hint`, `review_status: escalate`)
3. Reply: status line + scannable Handoff summary
4. **Stop**—no next claim; do not skip the gate to other ready tasks

Still full-stop (no dual-agent auto-approve): irreversible git/PR/release, bind ambiguity, illegal multi-`doing`, dual-agent escalate/exhausted rounds, unapproved secrets/compliance choices, verification environment impossible.

### Auto forbidden

- Product forks that spec+review cannot decide
- push / merge / open PR / release
- Inventing directories without a workstream bind
- Using auto to skip session sticky / workspace accounting
- Waiting on human “continue” for design gates instead of dual-agent review
- Full-stop without a Handoff block

## Handoff protocol (where you left off)

Like ai-memory: on cross-session / cross-vendor resume, **read a bounded handoff first**, not the whole chat or full log.

**Writer:** parent `/run` only.  
**Where:** workstream `context.md` → sole runtime section `## Handoff` (plus Gotchas / decisions / log). **No parallel “Current status” section** (migrate legacy if found, then delete).  
**Split:** Handoff = breakpoint + next (keep updating while advancing); Execution Log = historical evidence; Gotchas = long-lived constraints.

### When Handoff is mandatory

1. Full-stop (hard block / escalate / auto stop)
2. User ends session / switches window / switches vendor
3. All tasks done (`status: closed`)
4. Long pause after a parallel wave finishes

Optional short refresh after a `done` if the session is about to end.

### Handoff block shape

```markdown
## Handoff

- status: open | closed
- updated: <ISO-8601 or YYYY-MM-DD HH:mm>
- workstream: <projectId>/<workstreamId>
- parent_project: <projectId>
- auto_mode: true | false
- phase: explore | plan | execute
- review_status: good | revise | blocked | escalate
- parallel_wave: false | true
- current_tasks: []
- last_completed: <task-id or ->
- blocker: none | <machine-readable short>
- open_questions:
  - <question>
- failed_approaches:
  - <tried → why rejected>
- next_action: <one executable next step>
- resume_hint: <e.g. continue or /run auto>
- key_paths:
  - <design/code paths>
- notes: <optional one line>
```

Rules: single source of runtime truth; keep bounded—link out to tasks/spec/log; never paste whole chats; never store secrets/cookies/tokens/real UUIDs; migrate legacy current-status sections into Handoff then delete them.

### Gotchas (optional, recommended)

```markdown
## Gotchas

- <date>: <long-lived contract or pitfall>
```

Cross-task constraints only; one-off failures go to `failed_approaches` or Execution Log.

### Using Handoff on recover

1. Open Handoff → align `current_tasks` / `blocker` / `next_action` / `resume_hint`
2. Conflict with `tasks.md` → hard block (**tasks win**; fix Handoff or ask)
3. Missing Handoff on legacy workstream → infer, then write one before ending the turn
4. Cross-vendor: workspace Handoff is the minimum packet; tasks remain authoritative

### Chat display

On full-stop or “pause here”: status line + short Handoff summary + note that `context.md` Handoff was written.

## Self-review schema

```yaml
review_status: good | revise | blocked | escalate
issues: []
recommended_action: "continue Tn"
ask_user: false
auto_mode: true | false
```

- `good` + `ask_user: false` → continue
- `revise` → fix and re-review
- `blocked` → record machine-readable blocker; plain mode may try other ready; **auto: design gates → dual-agent first; only escalate/non-decidable → full-stop**
- `escalate` → ask user (auto: try dual-agent for design gates first)

Switching to an unbound workstream mid-session → `escalate` (suggest `/run bind`).

## Hard blocks

**Stop and ask only for:**

1. Cross-repo dependency needing confirmation
2. Product direction change
3. Irreversible ops: git push, merge, PR, production release
4. State contradiction
5. Recover anomaly
6. **Illegal multi-`doing`**
7. Quality gate cannot be satisfied
8. Mixing workstreams / bind ambiguity
9. Workstream missing `parent`
10. **Unbound session risk:** `.run-state` workstream bind exists but this turn’s code changes are not mapped to a `tasks.md` row
11. Parallel merge conflict
12. Subagent wrote workspace—stop path, parent repairs

**Not hard blocks:** task done with evidence, review/verify passed, durable state updated, compile/test fails (self-fix), legal parallel multi-`doing`.

Missing `/run` in the prompt / “small change” / prior ad-hoc edits / debug follow-ups are **not** reasons to skip `/run` when bound.

## Mid-execution design revision

If the user changes design during execute: handle in place (no plan rollback) unless task decomposition is invalidated; update artifacts then code; keep verification evidence; record in Key Decisions.

## Init protocol (`/run init` — project only)

1. Resolve id (see numbered naming)
2. Path `Projects/<projectId>/`; if already a project → report and guide `/run new` or `/run bind`
3. Create folder + `project.md` from `templates/project.md`
4. Do **not** create workstream `tasks.md` here
5. Optionally bind `.run-state` to the project folder (browse only); tell user next is `/run new`
6. **Stop by default**

If a project already exists and user says init → use `/run new`.

## New workstream protocol (`/run new`)

1. Resolve parent project (workstream→`parent`, project→self, else ask)
2. Parse parent `NN`; ask about migrating unnumbered parents if needed
3. Allocate `NN.MM-<slug>`
4. Path under parent; if exists → offer `/run bind`
5. Create `workstream.md` from template
6. Empty `tasks.md` / `context.md` with Handoff + Gotchas; `spec.md` optional later
7. Append parent “Workstreams” table link
8. Point this session’s `.run-state` at the new workstream
9. **Do not auto-execute** by default; ask whether to `/run` now

## Recover protocol

When `/run` resumes or sticky engineering continues:

1. Read `.run-state`
2. Match `session_id` in `projects[]`
3. Sync top-level on match
4. Else interactive bind if ambiguous
5. Read tasks/context; legal parallel `doing` OK; illegal multi-`doing` → hard block
6. Read open Handoff + Gotchas
7. Homepage rules
8. Keep Handoff `review_status` if set
9. Map user intent to a task row (create if needed)—never code without a row
10. Continue from breakpoint / new claim (parallel waves allowed)
11. Keep refreshing Handoff; confirm completeness before pause/switch

Safety: session bind over same-repo overwrite; tasks vs Handoff conflict → hard block (tasks authoritative); done without verify → verify first; no “code first, state later”; parent-only workspace writes; checkout/tests beat stale Gotchas (then update Gotchas); migrate legacy current-status sections into Handoff.

## `tasks.md` format

```markdown
---
project: <workstreamId>
parent_project: <projectId>
repos:
  - <primary-repo>
  - <related-repo-1>
design: "[[design]]"
created: <date>
---

| ID | Task | Status | Depends | Blocker | Acceptance |
|---|---|---|---|---|---|
| T01 | ... | done | - | - | ... |
| T02 | ... | ready | T01 | - | ... |
| T03 | ... | blocked | T01 | T02 or waiting on user approval | ... |
| T04 | ... | todo | T01,T02 | - | ... |
```

- `Blocker` column optional.
- Statuses: `todo` / `ready` / `doing` / `blocked` / `done`
- Transitions as in parallel/quality sections; parent claims and writes Done evidence.

## `context.md` format

```markdown
## Handoff

- status: open | closed
- updated: <date-time>
- workstream: <projectId>/<workstreamId>
- parent_project: <projectId>
- auto_mode: true | false
- phase: explore | plan | execute
- review_status: good | revise | blocked | escalate
- parallel_wave: false | true
- current_tasks: []
- last_completed: <task-id or ->
- blocker: none | <short>
- open_questions: []
- failed_approaches: []
- next_action: <one step>
- resume_hint: <hint>
- key_paths: []
- notes: <optional>

## Gotchas

- <date>: <long-lived contract>

## Key Decisions

- <date>: <decision>

## Execution Log

- <task-id> done: <summary> | paths: a.go,b.go | verify: go test ./... → ok
```

**Handoff is the only runtime section.** New workstreams start with empty open Handoff + Gotchas.

## Multi-repo projects

When `repos` lists 2+ paths: write `.code-workspace` at primary root; optional `open-review.command` in the workstream; link from `context.md`. Update when plan adds repos.

## Relationship to other skills

`/run` orchestrates: `brainstorming`, `test-driven-development` (when applicable), `systematic-debugging`, **always** `verification-before-completion` before done, `using-git-worktrees` when applicable.

## Document language

Durable-state files default to **English**. Keep code identifiers, APIs, and machine status values in English.
