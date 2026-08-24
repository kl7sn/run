---
name: run
description: Unified workflow entry. Auto-detect phase (explore/plan/execute/recover) with durable state in a configurable Markdown workspace folder (Obsidian optional). Supports nested projects/workstreams, /run init, /run new, /run bind, /run lang (en|zh), /run review, /run auto. When a repo already has a .run-state binding, follow-up engineering requests in the same session must restore the binding and update the workspace—never fall back to ad-hoc local coding. Triggers: /run, /run auto, /run init, /run new, /run bind, /run lang, /run review, continue work, resume, start implementation, unattended, and follow-up code/bug/feature work on a bound repo.
---

# /run — Unified workflow

## Overview

`/run` is the single entry for complex software work. It detects the current phase and keeps advancing until all tasks are done or a hard block is hit.

**Goal:** advance engineering tasks automatically while enforcing verification for code quality.

Core loop: **read state → choose phase → execute → self-review → update state → continue**

- Plain `/run`: auto-continues when tasks are ready; may still ask on explore ambiguity or design confirmation.
- **`/run auto`**: unattended mode—do not ask “continue to next?”; **design/plan gates** use dual-agent consensus with a mechanical preflight (recorded verdict + `design-review:` status); only true hard blocks / true product forks stop the whole run.

### Session sticky (do not degrade to ad-hoc coding)

**Failure mode:** the repo already has `.run-state` bound to a workstream, but later requests are treated as ordinary local edits—no `/run` restore and no updates to workspace `tasks.md` / `context.md`.

**Hard rule:** engineering work (code / bugs / features / landed diagnostics / durable architecture decisions) **must** bind an **active execution workstream** (`Handoff status: open`, and `.run-state` `projects[].status` not `completed` / `archived`).

If a valid `.run-state` resolves to a **workstream** binding (this session’s `session_id` matches, or top-level `workspace` points at a workstream folder), then any such request **must**:

1. Run the recover protocol (read `.run-state` → `tasks.md` + `context.md` + homepage)
2. **If that workstream is closed** → treat as **abnormal bind** (see below); do **not** reopen it
3. Otherwise map the request to an existing ready/doing task, or **add** a `tasks.md` row then claim it (never change code without accounting)
4. Update durable state during/after work (status, Done evidence, decisions/log in `context.md`)

**Also forbidden on active lines:**

- “Tiny change / quick debug” → skip binding and workspace
- Saying “I’ll fill tasks later” while still editing code
- Starting a new explore doc stream that detaches from the bound workstream

### Closed workstream = abnormal bind (do not reopen)

A workstream is **closed** when any of:

- `context.md` → `## Handoff` has `status: closed`
- `.run-state` entry has `status: completed` or `archived`
- all tasks `done` and Handoff already closed for that line

**If the session is bound to a closed workstream** (or recover lands there) **and** this turn needs durable landing (decisions, tasks, code, specs that will drive work):

1. This is an **abnormal scenario** — the conversation is not on an execution-ready line
2. **Forbidden:** flip Handoff back to `open`, “recovery backfill” onto the closed line, or pretend the old workstream is still the execution unit
3. **Required:** `/run new` under the parent project (preferred), or `/run bind` to an existing **active** workstream; carry forward a short pointer/wikilink to the closed line in the new `context.md`
4. Then continue sticky rules on the **new/active** bind only

**Only exemptions** (say explicitly “not using /run this turn”):

- User opts out of `/run`
- Pure read-only retrospective about a closed line (no repo writes, no workspace writes)
- Concepts-only Q&A with no file writes

Do **not** use the “concepts-only” exemption when the discussion changes architecture constraints that should land as durable state — that requires an **active** workstream (`/run new` if the previous line is closed).

**Skipped accounting on an active line:** stop ad-hoc work; recover; backfill tasks in real order (label “recovery backfill”); **do not fake** the original ready→doing timeline; then continue. **Never** apply recovery backfill to a closed workstream — open a new one instead.

## Commands

| Command | Purpose |
|---|---|
| `/run init` [projectId] | Create **project container only** (layer 1) |
| `/run new` [workstreamId] | Create nested **workstream** under parent (layer 2); stop by default (no auto execute) |
| `/run bind` | Interactively rebind this session to a workstream / project / new |
| `/run lang` [en\|zh] | Show or set **document language** for durable state + human-facing replies |
| `/run review` [window] | **Retro + maintain**: scan **current project** (default) → report → **`up` phase** |
| `/run review all` [window] | Scan **entire workspace** (all projects) |
| `/run review scan-only` [window] | Scan + report only; no skill edits |
| `/run` | Advance explore/plan/execute/recover; auto-continue when ready |
| `/run auto` | **Unattended**: keep ready tasks flowing; design confirmation → dual-agent consensus then continue; true hard blocks stop |

## Workspace (durable state directory)

`/run` stores task state in a normal folder of Markdown files. Obsidian is optional—any Markdown editor works.

Path priority (high → low):

1. `workspace:` in the code repo’s `.run-state`
2. Env `RUN_WORKSPACE`
3. Default: `~/run-workspace`

Prefer expandable `~/…` or absolute paths. If the path contains spaces (e.g. iCloud `Mobile Documents`), keep the full path consistent across top-level `workspace` and every `projects[].workspace` entry. After moving the vault, rewrite all bound repos’ `.run-state` / legacy `.k-state` paths in one pass.

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
lang: en
project: 01-demo/01.01-hello
repo: .
```

`lang` is `en` or `zh` (see Document language).
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
lang: en | zh
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
   - `/run lang` → document language protocol (show or set `en`/`zh`)
   - `/run review` → retro protocol (scan → report → **`up` maintenance** by default)
   - `/run review scan-only` → retro scan + report only (no skill edits)
   - `/run auto` → recover bind, enter Auto mode, advance
3. Resolve `lang` (see Document language) and keep it for this turn’s durable writes + human-facing prose
4. If `projects[]` matches `session_id` → use it and sync top-level entry
5. If no session bind → unique candidate OK; **≥2 → interactive bind** (in auto, cannot uniquely bind → **full stop**); zero candidates → guide `/run init` or `/run new`
6. Read bound `tasks.md` + `context.md`; homepage rules apply
7. If this turn is `/run auto` (or Handoff `auto_mode: true` and not exited) → keep `auto_mode: true`, follow Auto rules
8. Else route:

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

**Automated gate ≠ human smoke.** Passing `go test`, CI-style suites, or agent-written “smoke tests” may satisfy a **task** row (e.g. T07). It does **not** satisfy the **workstream integration gate** (see below). Do not set `Handoff status: closed` or `.run-state status: completed` based on automated gates alone.

On recover: `done` without verify evidence → verify first.

## Integration gate & worktree lifecycle

A workstream is **not finished** when all `tasks.md` rows are `done`. Closing requires an explicit **integration gate** so branches/worktrees are not orphaned and follow-up defects do not force premature `/run new`.

### Two verification layers

| Layer | Who | Satisfies | May close workstream? |
|---|---|---|---|
| **Automated gate** | Agent (tests, vet, build, scripted checks) | `doing → done` on task rows | **No** |
| **Human smoke** | User on the real worktree / real UI / real doc | `smoke_status: passed` (or `waived-by-user`) | **Yes** (with worktree disposition) |

Human smoke means the user exercises the feature branch as they would before merge (manual or their own checklist). Agent cannot self-approve `smoke_status: passed`.

### Handoff fields (required once a code worktree exists)

When execution uses a git worktree or feature branch, keep these in `## Handoff`:

```markdown
- worktree_path: <absolute path or none>
- worktree_branch: <branch or ->
- worktree_status: none | active | smoke_pending | ready_to_merge | pruned
- smoke_status: pending | passed | waived-by-user
- integration_next: none | merge | pr | keep-branch | prune
```

Rules:

- Creating a worktree → set `worktree_path`, `worktree_branch`, `worktree_status: active`, `smoke_status: pending`
- All tasks `done` but smoke not passed → `worktree_status: smoke_pending`; **keep `Handoff status: open`**
- User confirms smoke OK → `smoke_status: passed`; then record `integration_next` and disposition
- **Forbidden:** `Handoff status: closed` while `worktree_status: active` or `smoke_pending` without explicit `integration_next` and user smoke (`passed` or `waived-by-user`)
- **Forbidden:** close workstream and leave an unregistered orphan worktree

### Close workstream checklist (all required)

Before `Handoff status: closed` **and** `.run-state projects[].status: completed`:

1. All tasks `done` with Done evidence
2. `smoke_status: passed` **or** user explicitly waived (`waived-by-user` in Handoff + Execution Log)
3. `integration_next` chosen and recorded: `merge` | `pr` | `keep-branch` | `prune`
4. Worktree disposition executed or explicitly deferred with `keep-branch` (path + branch still in Handoff — not silent orphan)
5. If `prune`: run `git worktree remove` (or equivalent), set `worktree_status: pruned`, clear or mark path

After close: `next_action` on closed lines should point to integration follow-up (merge/PR), not new feature work.

### `/run new` when the real issue is unmerged work

Before `/run new` under the same parent project:

1. List sibling workstreams with `worktree_status: active` or `smoke_pending` in Handoff
2. If the new work is a defect on an **unmerged branch** from a line that closed too early → **protocol error** on the closer; for the current turn, prefer **reusing that branch/worktree** in the new or current active line rather than spawning another worktree
3. If orphan worktrees exist for this repo, surface them and ask: smoke / merge / prune — do not silently add a third worktree

### Status line (integration)

While smoke is pending:

```text
[/run · auto=off · 01-shimocli/01.03-mixed-rdoc-edit · smoke_pending · feat/mixed-rdoc-edit]
```

## Auto-advance rules

**Batch done ≠ workflow done. If ready tasks exist and no hard block, continue.**

After each task:

1. Update `tasks.md` + `context.md` (evidence + **refresh Handoff**)
2. All-depends-done `todo` → `ready`
3. Blocker upstream done / cleared → `blocked` → `ready`
4. Check hard blocks
5. If ready and no hard block → next immediately
6. All tasks `done` → run **integration gate** (smoke + worktree disposition); **do not** auto-close the workstream
7. Blocked with no ready → report blockers

**Forbidden stop reasons:** “Tn done, Tn+1 ready”, “state synced”, “can continue later” (unless user asks to pause or “only this one”).

## Auto mode (`/run auto` — unattended)

For overnight/unattended runs in **one session + one workstream bind**.

**On:** `/run auto`, or “unattended” / “keep going overnight”. Set Handoff `auto_mode: true`.  
**Off:** “exit auto” / “stop unattended”, or plain `/run` with explicit exit; set `auto_mode: false`.  
**Scope:** no out-of-session heartbeat control plane. If the session dies, user restarts `/run auto`.

### Design-gate preflight (mechanical — `auto_mode: true`)

A **design gate** is any moment you would otherwise ask the human to approve a written design before plan/TDD/code, including:

- explore → plan
- scheme / API / CLI shape choice after a design doc
- **mid-execute** when a new or substantially revised design artifact is written (e.g. `docs/**/…-design.md`) while a task is `doing`

**Before ending a turn that crossed a design gate**, ALL must hold:

1. A reviewer subagent was actually dispatched (not self-approved in the same thought).
2. `context.md` → Execution Log (or Key Decisions) records a design-review line with `verdict`, design path, and one-line summary.
3. Status line tail shows `design-review: pending|approved|revise|escalate` while that gate is active (not only `Tn doing`).
4. The reply does **not** ask the user to reply 确认 / 继续 / “confirm” / “continue” to unlock plan/TDD.

If any check fails → **protocol error**: do not wait; run dual-agent review in this turn (or full-stop on `escalate`). Ending the turn idle at a human design gate is forbidden even if the status line says `auto=on`.

**Protocol correction:** if you already asked for human design confirmation under `auto_mode: true`, immediately withdraw the wait, run dual-agent review, append `protocol-correction: design-gate` to the Execution Log, then continue from the verdict. Do not require the user to re-send `/run auto`.

### In-chat status line (required)

On `/run` recover/advance (including sticky engineering turns), prefix replies:

```text
[/run · lang=zh · auto=on · 01-demo/01.01-hello · T03 doing]
```

or:

```text
[/run · lang=en · auto=on · 01-demo/01.01-hello · design-review: pending]
[/run · lang=en · auto=on · 01-demo/01.01-hello · design-review: approved → plan]
[/run · lang=en · auto=off · 01-demo/01.01-hello · blocked: waiting on design approval]
```

| Segment | Meaning |
|---|---|
| `lang=en` / `lang=zh` | Resolved document language (see Document language) |
| `auto=on` / `auto=off` | Handoff `auto_mode` (default off) |
| Path | `<projectId>/<workstreamId>` |
| Tail | `Tn doing` / `T01+T02 doing` / `design-review: …` / `blocked: …` / `done` / `idle` |

Rules: every code/task-advancing reply; tiny acks may omit; on enter/exit auto, also say “auto enabled/disabled”; full-stop summaries use the same prefix; **design gates under auto must use a `design-review:` tail until the gate clears**.

### vs plain `/run`

| Point | `/run` | `/run auto` |
|---|---|---|
| Continue ready | yes | yes (no “continue Tn+1?”) |
| Optional explore questions | may ask | prefer decide from spec; else dual-agent; else hard stop |
| Design confirmation (“review then reply continue”) | ask user | **forbidden idle wait** → dual-agent consensus then plan/implement |
| Build/test fail | self-fix | same (`revise`) |
| Irreversible git / bind ambiguity / **true** product fork | stop | same full-stop |
| All done / only non-decidable blocked | report | report and end auto wave |

### What counts as a true product fork (human / escalate only)

**Dual-agent may decide** (do not ask the user by default): implementation boundaries, API/CLI shapes, test contracts, failure modes, compatibility within an already agreed goal.

**Human / `escalate` only when** the change alters product direction in a way spec+review cannot settle, e.g.:

- changes target user / business goal / non-goals
- removes a user-facing capability the workstream committed to keep
- irreversible release / data-destruction / compliance / secrets policy without prior authorization

Do **not** treat ordinary design docs for an already-scoped task (flags, date semantics, adapter wiring) as a product fork.

### Dual-agent consensus review (`auto_mode: true` only)

Replaces “design done → wait for human continue” (explore→plan, scheme choice, post-spec gate, **mid-execute design artifacts**).

| Role | Duty | Workspace |
|---|---|---|
| **Author agent** | Produce/revise design; apply review issues | Do not race-write; parent records |
| **Reviewer agent** (subagent) | Read-only: goals/non-goals, safety, testability, tasks acceptance fit, hidden tradeoffs | **Must not** write workspace / `.run-state` |
| **Parent `/run`** | Dispatch, round limits, write `context.md`, unlock tasks, continue | **Sole writer** |

Flow:

1. Author states design path + task to unlock (if any). Status line → `design-review: pending`.
2. Parent dispatches reviewer with the **fixed prompt** below; required output:

```yaml
verdict: approve | revise | escalate
issues: []
blocking_reasons: []
summary: "one line"
```

3. **`approve`:** parent records consensus in `context.md`; design-wait `blocked` → `ready` if needed; **do not** ask “continue”; status → `design-review: approved → plan` (or execute); enter plan/TDD.
4. **`revise`:** author updates; max **2** revise cycles; still revise → `escalate` full-stop.
5. **`escalate`** or deadlock: full-stop with blocker (both sides’ points)—morning human gate.

#### Fixed reviewer prompt (copy into subagent)

```text
You are the /run design reviewer. Read-only. Do not edit files or workspace state.

Design path: <path>
Workstream / task: <projectId/workstreamId · Tn>
Acceptance / goal context: <short paste from tasks.md or Handoff>

Check at minimum:
1) Goals vs non-goals — no silent scope creep
2) Safety/privacy — secrets never logged or echoed; constraints testable
3) Failure modes and compatibility stated
4) Test contracts are concrete enough for TDD
5) Any true product fork (target user/business goal/non-goal change, capability removal, irreversible release/compliance) → verdict escalate

Return ONLY:
verdict: approve | revise | escalate
issues: []          # required if revise — actionable
blocking_reasons: [] # required if escalate
summary: "one line"
```

Reviewer minimum checks match the prompt. Product forks disguised as settled tech → `escalate`.

Forbidden: idle “please review, reply continue”; coding before approve; fake “default scheme A” consensus; reviewer writing tasks/context; showing `auto=on` while waiting on a human design confirmation.

### Full-stop (required)

1. Update `tasks.md` (blocked/machine-readable Blocker)
2. Write/refresh **Handoff** (`auto_mode`, blocker, next, `resume_hint`, `review_status: escalate`)
3. Reply: status line + scannable Handoff summary
4. **Stop**—no next claim; do not skip the gate to other ready tasks

Still full-stop (no dual-agent auto-approve): irreversible git/PR/release, bind ambiguity, illegal multi-`doing`, dual-agent `escalate`/exhausted rounds, unapproved secrets/compliance choices, verification environment impossible, **true product forks** (see above).

### Auto forbidden

- Asking the user to 确认 / 继续 / confirm / continue to pass a design gate
- Ending a turn at a design gate without a recorded dual-agent verdict
- Product forks that meet the true-fork criteria above
- push / merge / open PR / release
- Inventing directories without a workstream bind
- Using auto to skip session sticky / workspace accounting
- Full-stop without a Handoff block

## Handoff protocol (where you left off)

Like ai-memory: on cross-session / cross-vendor resume, **read a bounded handoff first**, not the whole chat or full log.

**Writer:** parent `/run` only.  
**Where:** workstream `context.md` → sole runtime section `## Handoff` (plus Gotchas / decisions / log). **No parallel “Current status” section** (migrate legacy if found, then delete).  
**Split:** Handoff = breakpoint + next (keep updating while advancing); Execution Log = historical evidence; Gotchas = long-lived constraints.

### When Handoff is mandatory

1. Full-stop (hard block / escalate / auto stop)
2. User ends session / switches window / switches vendor
3. All tasks done **and integration gate satisfied** (`status: closed`)
4. Long pause after a parallel wave finishes

Optional short refresh after a `done` if the session is about to end.

### Handoff block shape

```markdown
## Handoff

- status: open | closed
- updated: <ISO-8601 or YYYY-MM-DD HH:mm>
- workstream: <projectId>/<workstreamId>
- parent_project: <projectId>
- lang: en | zh
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
- worktree_path: <absolute path or none>
- worktree_branch: <branch or ->
- worktree_status: none | active | smoke_pending | ready_to_merge | pruned
- smoke_status: pending | passed | waived-by-user
- integration_next: none | merge | pr | keep-branch | prune
- notes: <optional one line>
```

Rules:

- Single source of runtime truth; keep bounded—link out to tasks/spec/log; never paste whole chats
- Never store secrets/cookies/tokens/real UUIDs
- Migrate legacy current-status sections into Handoff then delete them
- Keep `lang` in sync with `.run-state` (repo default) when the workstream follows the repo setting
- `status: closed` ends the wave only after the **integration gate** (smoke + worktree disposition) — **do not reopen** for new durable work; use `/run new` (or bind another active workstream) and optionally wikilink the closed line

### Gotchas (optional, recommended)

```markdown
## Gotchas

- <date>: <long-lived contract or pitfall>
```

Cross-task constraints only; one-off failures go to `failed_approaches` or Execution Log.

### Using Handoff on recover

1. Open Handoff → align `current_tasks` / `blocker` / `next_action` / `resume_hint`
2. If `status: closed` and this turn needs durable landing → **abnormal bind**; do not reopen — `/run new` or bind active (Session sticky)
3. Conflict with `tasks.md` → hard block (**tasks win**; fix Handoff or ask)
4. Missing Handoff on legacy workstream → infer, then write one before ending the turn
5. Cross-vendor: workspace Handoff is the minimum packet; tasks remain authoritative

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
2. **True product direction change** (see Auto mode · true product fork) — not routine design for an already-scoped task
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
13. **Auto design-gate protocol breach left unresolved** (asked human to confirm design under `auto_mode: true` and did not run dual-agent correction)
14. **Closed workstream bind with durable work** — session points at completed/archived/closed line but the turn needs tasks/decisions/code; require `/run new` or bind active (do not reopen)
15. **Premature workstream close** — `Handoff status: closed` or `completed` while `smoke_status: pending` or `worktree_status: active|smoke_pending` without disposition; treat as protocol error on recover

**Not hard blocks:** task done with automated evidence, review/verify passed, durable state updated, compile/test fails (self-fix), legal parallel multi-`doing`, ordinary mid-task design docs under auto (those use dual-agent). **All tasks done** with smoke still pending is **not** “workflow complete” — stay open at integration gate.

Missing `/run` in the prompt / “small change” / prior ad-hoc edits / debug follow-ups are **not** reasons to skip `/run` when bound.

## Mid-execution design revision

If the user changes design during execute, or the agent writes a new/substantially revised design artifact while a task is `doing`:

1. **Do not** roll back to a blank plan phase unless task decomposition is invalidated
2. Assess blast radius; update design artifacts, then propagate to code
3. Keep verification evidence for revised done work
4. Record in Key Decisions
5. **If `auto_mode: true`:** treat the new design as a **design gate** — dual-agent preflight required; **do not** ask the user to 确认/继续 before plan/TDD
6. Continue remaining tasks after approve (or full-stop on escalate)

Only when task decomposition is fully invalidated, return to plan and rewrite `tasks.md`.

## Init protocol (`/run init` — project only)

1. Resolve id (see numbered naming)
2. Path `Projects/<projectId>/`; if already a project → report and guide `/run new` or `/run bind`
3. Create folder + `project.md` from `templates/project.md`
4. Do **not** create workstream `tasks.md` here
5. Optionally bind `.run-state` to the project folder (browse only); tell user next is `/run new`
6. If `.run-state` has no `lang`, ask once: `en` or `zh` (or use `RUN_LANG` / default `en`); write `lang:` into `.run-state`
7. **Stop by default**

If a project already exists and user says init → use `/run new`.

## New workstream protocol (`/run new`)

1. Resolve parent project (workstream→`parent`, project→self, else ask)
2. Parse parent `NN`; ask about migrating unnumbered parents if needed
3. Allocate `NN.MM-<slug>`
4. Path under parent; if exists → offer `/run bind`
5. Create `workstream.md` from template (match resolved `lang`)
6. Create empty `tasks.md` / `context.md` with Handoff + Gotchas using the **resolved lang** (section titles and table headers); put `lang:` in Handoff; `spec.md` optional later
7. Append parent “Workstreams” table link
8. Point this session’s `.run-state` at the new workstream; ensure top-level `lang` is set
9. **Do not auto-execute** by default; ask whether to `/run` now
10. **Orphan check:** if this repo already has worktrees from sibling workstreams (`worktree_status: active|smoke_pending`), list them and recommend smoke / merge / prune before allocating another worktree

## Document language protocol (`/run lang`)

1. Resolve current `lang` (see Document language · resolution)
2. `/run lang` with no args → report current value and source (`.run-state` / Handoff / env / default)
3. `/run lang en` or `/run lang zh` (aliases: `english`/`中文`/`cn`→`zh`):
   - Write `.run-state` top-level `lang:`
   - If a workstream is bound and Handoff is `open`, set Handoff `lang:` to the same value
   - **Do not** bulk-translate existing historical Markdown; only **new** durable writes and human-facing replies use the new lang
   - Confirm with status line `lang=…`
4. Invalid value → ask `en` or `zh`; do not guess

## Review protocol (`/run review` — retro + integrated `up`)

**Purpose:** evaluate whether `/run` protocol held up over a time window, using **bounded durable artifacts only** — not full agent chat transcripts. Default flow is **two phases**:

1. **Scan + report** — heuristics R01–R10 → `Projects/<projectId>/_run-review/YYYY-MM-DD-review.md`
2. **Maintain (`up`)** — apply skill patches from the report’s Skill backlog (follow personal **`up`** skill inline)

**Does not** modify workstream state (`tasks.md`, Handoff), code repos, or `.run-state`. **Does** modify skill files in phase 2 unless `scan-only`.

Standalone **`up`** remains valid for thread retros without a review report.

### Invocation

```text
/run review              # default: current project + time window + report + up
/run review all          # entire workspace (all projects under Projects/)
/run review scan-only    # current project, report only; no skill edits
/run review all scan-only
/run review yesterday
/run review 7d
/run review 2026-08-20..2026-08-24
/run review 01-shimocli                    # explicit project scope
/run review 01-shimocli/01.04-empty-paragraph-projection   # single workstream
```

**Scope resolution (phase 1, before scan):**

| Priority | Source | Scope |
|---|---|---|
| 1 | User names `NN-<slug>` or `NN-<slug>/NN.MM-<slug>` in command | That project or workstream |
| 2 | User says `all` / `workspace` / `--all` | `Projects/**` (full workspace) |
| 3 | **Default** — repo `.run-state` bind | **Current project only** |
| 4 | No bind, `RUN_WORKSPACE` set | Ask: pick project, `/run review all`, or `/run bind` first |

**Current project** from bind:

- Bound **workstream** → `parent_project` from Handoff / homepage / `.run-state projects[].parent_project` (e.g. `01-shimocli`)
- Bound **project** folder → that project id (e.g. `01-shimocli`)
- Scan path: `Projects/<projectId>/**/{tasks,context,workstream,project}.md` only
- `.run-state`: only `projects[]` entries whose workstream lives under that project (same repo if known)

Aliases for scan-only: `scan-only`, `--scan-only`, `no-up`, `--no-up`.

Status line prefix:

```text
[/run · review · up · project=01-shimocli · lang=en · 2 workstreams · 1 finding · 1 patched]
[/run · review · scan-only · project=01-shimocli · lang=en · 2 workstreams · 1 finding]
[/run · review · up · scope=all · lang=en · 5 workstreams · 3 findings]
```

### Data sources (authoritative)

Scan only within **resolved scope** (default: one project):

1. **Workspace** → `Projects/<projectId>/**/{tasks,context,workstream,project}.md` (or `Projects/**/…` when `scope=all`)
2. **Repo** `.run-state` / legacy `.k-state` — **`projects[]` entries for this scope** (and this repo when inferrable)
3. **Optional corroboration:** `git worktree list` in bound repos (orphan / drift vs Handoff `worktree_path`)

**Do not** scrape Cursor/Claude/Codex session exports by default. If the user pastes a transcript excerpt, treat it as **supplemental evidence** only — workspace wins on conflict.

### Time window

- Default: **previous local calendar day 00:00 → now** (or “since last `/run review` report” for the **same scope** under `Projects/_run-review/`)
- Filter workstreams by `Handoff updated`, `Execution Log` dates, `.run-state projects[].note`, or file `mtime` inside the window
- Include workstreams with **any** activity in window, even if created earlier
- **Within scope only** — default scope is one project, not the whole vault

### Heuristic rules (check each hit workstream)

| ID | Signal | Likely protocol gap | Suggested action |
|---|---|---|---|
| R01 | `auto_mode: true` in Handoff or status line, and Execution Log / chat summary mentions 确认/继续/confirm/continue to pass design | Auto design-gate leak | Strengthen design-gate preflight; add `protocol-correction` if missing |
| R02 | All tasks `done` + `Handoff status: closed` while `smoke_status: pending` or `worktree_status: active\|smoke_pending` | Integration gate skipped | Enforce close checklist; reopen is forbidden — note for **future** lines |
| R03 | Closed workstream + sibling `/run new` within 48h on same parent (note in Key Decisions / new workstream links closed line) | Premature close | Recommend smoke before close; reuse branch/worktree |
| R04 | `Handoff` vs `tasks.md` conflict (e.g. `current_tasks` vs no `doing`, or `last_completed` not `done`) | Recover / single-writer breach | Hard-block pattern; fix Handoff on next `/run` |
| R05 | Multiple `doing` without `parallel_wave: true` or Execution Log parallel-wave note | Illegal multi-doing | Converge tasks; record wave in Handoff |
| R06 | `protocol-correction:` lines in Execution Log | Known violation occurred | Count frequency; prioritize skill edit |
| R07 | `worktree_path` set but path missing on disk, or `git worktree list` shows unregistered trees for this repo | Orphan worktree | merge / prune / update Handoff |
| R08 | `.run-state status: completed` but Handoff still `status: open` (or reverse) | State index drift | Sync on next bind |
| R09 | Durable engineering work described in Execution Log with no matching task row | Session sticky skip | Backfill policy reminder |
| R10 | `design-review: pending` in logs with no following `verdict=approve\|revise\|escalate` line | Incomplete auto gate | Finish dual-agent review or escalate |

Severity: **high** (R02,R04,R05,R09) · **medium** (R01,R03,R07,R10) · **low** (R06,R08 — unless repeated).

### Output

Write report to:

```text
<workspace>/Projects/_run-review/YYYY-MM-DD-review.md
```

Template:

```markdown
# /run review — YYYY-MM-DD

- scope: project 01-shimocli | workstream 01-shimocli/01.04-… | all
- window: <range>
- workspace: <path>
- repos scanned: <list>
- workstreams in window: <count>

## Summary

- high: N · medium: N · low: N
- top themes: <bullets>

## Findings

### [R02 high] 01-shimocli/01.03-mixed-rdoc-edit

- evidence: context.md Handoff `smoke_status: pending`, `status: closed`
- impact: follow-up defect forced `/run new` (01.04)
- suggested skill change: integration gate — block close until smoke passed

## Workstreams touched

| workstream | last activity | open/closed | findings |
|---|---|---|---|

## Skill backlog

- [ ] <action item → skills/run/SKILL.md section>

## Maintenance applied (up)

- mode: apply | skipped (scan-only) | none (empty backlog)
- patched:
  - skills/run/SKILL.md § <section> — <one line>
- synced: cursor, codex, claude, agents
- deferred:
  - [ ] <item needing human triage or repo commit>
```

### Phase 2: Skill maintenance (`up`)

Run **in the same turn** after the report is written, unless invocation was `scan-only`.

Follow the personal **`up`** skill (`~/.codex/skills/up/SKILL.md` or synced copy). Inline checklist:

1. Read **Findings** + **Skill backlog** from the report just written — not surrounding chat
2. **Priority:** protocol findings (R01–R10) → patch `skills/run/SKILL.md` first; then other skills if backlog names them
3. Apply **minimum** durable patches (facts, workflow rules, warnings — not conversation narrative)
4. **Sync** shared skills to all roots: `~/.cursor/skills`, `~/.codex/skills`, `~/.claude/skills`, `~/.agents/skills`
5. Append **Maintenance applied (up)** to the report file; update backlog checkboxes for items patched
6. Reply with scannable summary: findings count, patches applied, sync roots, deferred items

**Up phase rules:**

- Workspace evidence in the report **wins** over chat recall
- Do **not** auto git commit/push `kl7sn/run` unless the user explicitly asks
- Skip patch when finding is ambiguous — list under `deferred` with reason
- Empty Skill backlog → write `mode: none`; stop phase 2
- Renames / new skills: follow `up` Automatic Rename Rule and Priority Rule

### Rules (both phases)

- **No execution** this turn: no task claims, no Handoff edits, no workstream code changes
- Phase 1 always runs; phase 2 runs by default
- Reply with scannable summary + path to report file
- If zero workstreams in window → say so; suggest widening window, explicit project id, or `/run review all`
- Repeat findings across reviews → bump priority in Summary

### Relationship to execution

- `/run review` is **meta** — not a substitute for `/run` on an active line
- Run from any repo with `.run-state` (default scope = that bind’s **project**), or with `RUN_WORKSPACE` + explicit project / `all`
- Safe to run in a **fresh session** (no workstream bind required)
- Workstream fixes from findings → next `/run` on the affected line (review does not reopen closed workstreams)

## Recover protocol

When `/run` resumes or sticky engineering continues:

1. Read `.run-state`
2. Match `session_id` in `projects[]`
3. Sync top-level on match
4. Else interactive bind if ambiguous
5. Read tasks/context; legal parallel `doing` OK; illegal multi-`doing` → hard block
6. Read Handoff + Gotchas
7. **Closed-line check:** if Handoff `status: closed` and/or bind `status: completed|archived`, and this turn needs durable landing → **abnormal bind**; stop recover-onto-closed; require `/run new` or `/run bind` to an **active** workstream (see Session sticky). Do not reopen.
8. Homepage rules
9. Keep Handoff `review_status` if set (open lines only)
10. Map user intent to a task row (create if needed)—never code without a row
11. Continue from breakpoint / new claim (parallel waves allowed)
12. Keep refreshing Handoff; confirm completeness before pause/switch

Safety: session bind over same-repo overwrite; tasks vs Handoff conflict → hard block (tasks authoritative); done without verify → verify first; no “code first, state later”; parent-only workspace writes; checkout/tests beat stale Gotchas (then update Gotchas); migrate legacy current-status sections into Handoff; **never reopen a closed workstream for backfill**.

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
- lang: en | zh
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
- worktree_path: <absolute path or none>
- worktree_branch: <branch or ->
- worktree_status: none | active | smoke_pending | ready_to_merge | pruned
- smoke_status: pending | passed | waived-by-user
- integration_next: none | merge | pr | keep-branch | prune
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

`/run` is the **orchestration layer** (bind → advance → verify → hand off). Companion skills supply discipline for a phase; they **must not** own a parallel workflow, skip workspace accounting, or close a workstream.

### Built-in defaults (superpowers / already local)

| Phase | Prefer | Notes |
|---|---|---|
| Explore | `brainstorming` | Align before design artifacts |
| Plan | `writing-plans` | Decompose into `tasks.md` rows |
| Execute | `test-driven-development`, `systematic-debugging` | When applicable |
| Pre-done | **always** `verification-before-completion` | Required for `doing → done` |
| Isolation | `using-git-worktrees` | Prefer when spawning code-changing subagents |

### Optional companions ([mattpocock/skills](https://github.com/mattpocock/skills))

Composable engineering skills. **Cherry-pick 2–3**; do **not** install the whole pack alongside an existing superpowers set (duplicate triggers). Do **not** run `setup-matt-pocock-skills` if it would move durable state into a separate issue-tracker workflow — keep authority in workspace `tasks.md` / `context.md`.

| `/run` phase | Optional skill | Use for | Skip if you already have |
|---|---|---|---|
| Explore | `grill-with-docs` (+ deps `grilling`, `domain-modeling`) | Shared domain language (`CONTEXT.md`) + ADRs while grilling | `brainstorming` alone is enough for small scopes |
| Explore / plan | `to-spec` | Turn an already-aligned chat into a written spec | Spec already written under `/run` explore |
| Plan | `to-tickets` | Break work into tracer tickets with blocking edges | Prefer writing edges into `tasks.md` Depends/Blocker columns |
| Execute | `tdd` | Red-green-refactor loop at agreed seams | `test-driven-development` |
| Execute | `diagnosing-bugs` | Phased diagnosis (feedback → minimise → hypothesise → fix) | `systematic-debugging` |
| Pre-done / design-review | `code-review` | Parallel Standards + Spec review subagents | Dual-agent design-review already covers design gates; still useful for post-diff review |
| Architecture health | `improve-codebase-architecture` | Periodic deepening survey (not a rescue) | Outside a bound workstream → open `/run new` first |

**Recommended local cherry-pick (when installed):** `grill-with-docs` + `grilling` + `domain-modeling`, `code-review`, `to-tickets`. Parent `/run` invokes them by phase; ticket edges still land in workspace `tasks.md` unless the user asks for a tracker.

**Do not install / do not dual-run**

- Their `handoff` skill — superseded by `context.md` → `## Handoff`
- Their `implement` as a second entry — `/run` owns claiming tasks and writing workspace
- Full pack + `setup-matt-pocock-skills` that rebinds docs/tickets away from the workspace folder

**Invocation rule:** parent `/run` may invoke a companion for the current phase; the companion returns results to the parent; **only the parent** updates `.run-state`, `tasks.md`, and `context.md`.

### Meta maintenance (`up`)

| When | Skill | Role |
|---|---|---|
| **`/run review` (default)** | `up` (phase 2, inline) | Apply patches from report Skill backlog; sync skill roots |
| `/run review scan-only` | — | Findings only; run `up` manually later if needed |
| Finished thread without review | `up` (standalone) | Thread retro → skill patches when no review report exists |

Default loop: **`/run review` = scan → report → up`**. `up` does not replace review heuristics and does not advance workstreams.


`/run` supports **`en`** and **`zh`** for durable-state prose and human-facing replies. Machine literals stay English.

### Resolution (high → low)

1. Bound workstream Handoff `lang:` (if set)
2. Code repo `.run-state` top-level `lang:`
3. Env `RUN_LANG` (`en` or `zh`)
4. Default: `en`

On `/run init` / first bind when unset → ask once, then persist to `.run-state`. Change later with `/run lang en|zh`.

### What `lang` controls

| Surface | `en` | `zh` |
|---|---|---|
| Human-facing chat (status explanations, Handoff summaries) | English | 中文 |
| Durable prose in `tasks.md` / `context.md` / `spec.md` / design docs written by `/run` | English | 中文 |
| `tasks.md` column headers | `ID \| Task \| Status \| Depends \| Blocker \| Acceptance` | `ID \| 任务 \| 状态 \| 依赖 \| 阻塞 \| 验收条件` |
| `context.md` section titles | `## Handoff` / `## Gotchas` / `## Key Decisions` / `## Execution Log` | `## Handoff` / `## Gotchas` / `## 关键决策` / `## 执行日志` |
| Status / task enums, YAML keys, paths, APIs, commits | English literals | English literals (unchanged) |
| Status line `/run · lang=…` | always include | always include |

Keep `## Handoff` and `## Gotchas` headings in English in both modes so recover parsers stay stable. Translate only the Key Decisions / Execution Log headings (and table headers) when `lang: zh`.

### Switching

- `/run lang` — show current lang + source
- `/run lang zh` / `/run lang en` — set repo default; update open Handoff `lang:` if bound
- Do **not** rewrite historical entries when switching; new writes follow the new lang
- Mixed files are OK (old English rows + new Chinese rows) until the user asks to normalize

### Templates

- `templates/project.md` / `templates/workstream.md` — English base; when `lang: zh`, fill new files with Chinese body text and zh `tasks.md` headers (see examples)
- Skill protocol file itself stays English (this `SKILL.md`); product READMEs remain `README.md` + `README_CN.md`

