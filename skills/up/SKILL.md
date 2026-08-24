---
name: up
description: "Use when reviewing a finished work thread for durable skill improvements, overlapping scope, missing reusable knowledge, or a skill name that no longer matches its actual responsibility. Also runs as phase 2 of `/run review` (default) to patch skills from the report Skill backlog. Packaged with kl7sn/run — maintained alongside the `/run` skill. Triggers: up, skill maintenance, 复盘 skill, maintain skills, /run review (phase 2)."
---

# Up

## Overview

Part of the **[kl7sn/run](https://github.com/kl7sn/run)** package (`skills/up`). Canonical source lives next to `skills/run`; install both via `install.sh`. Prefer editing this file in the `kl7sn/run` repo, then sync agent skill roots.

Use this skill to turn one completed work thread (or a `/run review` report) into skill maintenance work.
Default to strengthening existing skills first. Create a new skill only when the learned behavior does not fit cleanly into an existing one.
When target skills are locally available, apply concrete maintenance changes; use a patch draft only for review-only requests or unavailable targets.

## When to Use

- A conversation produced stable operational knowledge
- A debugging or protocol thread exposed reusable patterns
- Multiple nearby skills now overlap or drift
- There is uncertainty whether to add a new skill or extend an old one
- A skill's name still describes an old implementation path, narrower scope, or obsolete responsibility
- `/run review` phase 2 (default) after a protocol retro report

Do not use this for one-off chat cleanup or for project-specific decisions that belong in project docs.

## Input from `/run review`

**Default:** `/run review` runs this skill as **phase 2** in the same turn (unless `scan-only`). Do not ask the user to invoke `up` separately.

When phase 2 runs (or the user provides a review report manually):

1. Read `Projects/<projectId>/_run-review/*.md` from the report path(s) just written → **Findings** + **Skill backlog** — not surrounding chat
2. For protocol violations (R01–R10: auto gate, integration gate, orphan worktree, Handoff/tasks drift), patch **`skills/run/SKILL.md`** in the `kl7sn/run` checkout first (or the synced `run` skill copies)
3. Workspace evidence cited in the report overrides conversational recall
4. Append **Maintenance applied (up)** to the report; sync all configured skill roots
5. Do **not** git commit/push `kl7sn/run` unless the user explicitly asks

**Scan-only:** `/run review scan-only` writes the report only — invoke this skill standalone later if needed.

## Priority Rule

Always evaluate in this order:

1. Can an existing skill absorb the new knowledge with a clear section addition or correction?
2. Can two existing skills be clarified so they divide responsibility better?
3. Only if both fail, propose a new skill.

Working bias:
Prefer fewer, sharper skills over many narrow overlapping ones.

For `/run` protocol findings, prefer patching `skills/run/SKILL.md` (this package) before inventing parallel workflow skills.

## Naming And Scope Rules

When a skill is project-specific, put the project name first in the skill name.
Use this pattern:

```text
<project>-<domain>-<workflow>
```

Examples:

- `doctool-windows-compare-ops`
- `doctool-release-packaging`
- `writer-mow-spec-first`
- `writer-fix-mow`
- `clickvisual-public-docs`

Use no project prefix for general reusable capabilities, such as `windows-manual-debug-loop`, `kl7sn-git-commit`, or `up`.
Use an organization or platform prefix for company-wide workflows that span repositories, such as `shimo-*` or `kl7sn-*`.

When reviewing a project-specific finding:

- first check whether a same-project skill already exists
- if the knowledge is tied to commands, paths, release artifacts, or runtime assumptions of one repository, prefer a project-prefixed skill
- if the knowledge is a generic diagnostic pattern, keep it in a general skill and avoid leaking project-specific commands into it
- if an existing skill has a generic name but has become project-specific, rename or split it before adding more project details

## Automatic Rename Rule

During every review, compare each target skill's directory name and frontmatter `name` with its responsibility **after** the proposed maintenance.

Automatically rename the skill in the same turn when the old name materially misleads discovery, for example when it:

- names a former primary workflow that is now only a fallback
- describes a narrower responsibility than the maintained skill now owns
- uses a generic name after becoming project-specific
- points to an implementation detail that the skill no longer prefers

Do not stop at a recommendation or patch draft unless the user explicitly requested review-only output or an external compatibility constraint makes migration unsafe.

An automatic rename must:

1. Move the skill directory and update frontmatter `name` together.
2. Preserve the skill body except for naming and scope corrections required by the rename.
3. Search all configured skill roots for the old name and update cross-references.
4. Apply the same rename in every synced skill root that has a copy.
5. Verify the new files exist, copies match, and no old-name references remain.
6. Report the old-to-new mapping and any intentionally retained compatibility alias.

Do not rename for a cosmetic wording preference when the current name still accurately supports discovery. Do not leave an alias stub by default; retain one only when a confirmed external caller still depends on the old name.

**Do not rename** `run` or `up` out of this package without an explicit user request — they are the published entry skills of `kl7sn/run`.

## Review Procedure

1. Summarize the thread into durable findings only.
2. List candidate existing skills that are closest in scope.
3. Audit whether each candidate's current name will still match its responsibility after maintenance; apply the Automatic Rename Rule when it will not.
4. For each candidate, classify the finding:
   - missing confirmed fact
   - missing workflow step
   - missing warning / trap
   - missing classification table
   - belongs elsewhere
5. Prefer updating the smallest number of existing skills that preserves clarity.
6. For the best target skill, identify the exact section to update or the exact new section to add.
7. Draft or apply the patch content in the style of the target skill.
8. Propose a new skill only when the thread defines a repeatable workflow that existing skills would become bloated or confused by absorbing.

## What Counts As Durable

Good candidates:

- Confirmed protocol behavior
- Stable error interpretation
- Replayability limits
- Decision checklists
- Evidence-backed distinctions such as page type vs protocol type

Weak candidates:

- One-off values like a specific token or timestamp
- Guesses not validated by traffic or tests
- Narrative details about how the investigation happened

## Output Shape

Produce findings in this order:

1. Existing skills to strengthen
2. Automatic renames performed, if any
3. Exact sections to add or revise
4. Patch draft or applied changes for the preferred update path
5. New skill proposals, only if still needed

For each proposed enhancement, be concrete:

- target skill
- why this belongs there
- exact knowledge to add
- whether it is a fact, workflow rule, or warning

For the preferred update path, include a patch draft that is directly actionable.
The draft can be either:

- a section-by-section insertion plan with exact wording
- or an `apply_patch`-ready diff if the target file is available locally

Default to patching existing skills, not merely describing them.

## Patch Draft Rules

The patch draft should:

- preserve the target skill's existing scope
- merge durable findings, not conversation narrative
- add the minimum text needed to improve future behavior
- avoid duplicating content already covered by nearby skills

If multiple existing skills could absorb the finding, draft only one primary patch and list the others as secondary options.

## Cursor/Codex Sync Rule

After changing `skills/run` or `skills/up` in the `kl7sn/run` checkout (or applying patches via this skill), sync to agent roots:

1. Prefer editing the canonical files under the `kl7sn/run` repo `skills/` tree, then commit/push.
2. End users: `npx skills update` (or re-run `npx skills add kl7sn/run -g -y`).
3. Contributors with a clone: `./install.sh all` (symlinks) or copy into `~/.cursor|claude|codex|agents/skills/{run,up}`.
4. If a root still has an old personal copy of `up` (not from this package), replace it with the packaged skill.

Do not silently update only one root for `run` / `up`. Skill drift between agents should be treated as a maintenance issue.

## Decision Heuristics

Choose enhancement over new skill when:

- The thread extends a skill's current subject rather than changing scope
- The new knowledge is one more section, table, or caution inside an existing workflow
- The user would reasonably expect to find it in the current skill

Choose new skill when:

- The thread defines a distinct reusable task with its own entry trigger
- Reusing an existing skill would make discovery worse
- The work product is an execution workflow, not just another note in a reference skill
- A patch draft for existing skills would create scope confusion or duplicated ownership

## Compression Rule

Do not create a new skill just because the conversation is long.
Extract the minimal reusable rules and merge them into the nearest existing skill unless that causes scope confusion.

## Common Mistakes

- Creating a new skill for every investigation
- Copying the conversation narrative instead of extracting reusable rules
- Updating multiple overlapping skills with the same content
- Stopping at recommendations when a concrete patch draft could have been produced
- Storing unverified inferences as confirmed facts
- Forgetting to state why an existing skill is insufficient before proposing a new one
- Expanding or replacing a skill's responsibility while leaving a materially misleading old name
- Renaming only the frontmatter or directory instead of migrating both roots and all references
- Maintaining a personal fork of `up` outside `kl7sn/run` after this package ships it
