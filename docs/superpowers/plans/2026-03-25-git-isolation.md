# Git Isolation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the nested git repo approach with a branch-and-squash workflow so the syndicate works cleanly inside host project repos with CI/CD.

**Architecture:** The syndicate works on a `syndicate/run-<N>` branch in the host repo. Parallel variants use ephemeral worktrees that are force-cleaned after each generation. The winning variant is squash-merged as one commit per generation. At completion, the branch becomes a PR.

**Spec:** `docs/superpowers/specs/2026-03-25-git-isolation-design.md`

**Note:** All edits use contextual text matching (old_string/new_string), not line numbers. Line numbers are approximate references only. Templates (`.gitkeep` files) are unchanged; Task 7 verifies they are intact.

---

### Task 1: Update SKILL.md Bootstrap Section

**Files:**
- Modify: `plugin/skills/run/SKILL.md` (Setup section, ~line 12)

- [ ] **Step 1: Replace the Setup section**

old_string:
```
## Setup

If `syndicate/` doesn't exist in the project root, bootstrap it by copying this skill's `templates/` directory there, initializing a git repo, creating an initial commit, and tagging it `seed`. If it exists, cd into it and pick up where you left off.
```

new_string:
```
## Setup

If `syndicate/` doesn't exist in the project root, bootstrap it:

1. Copy this skill's `templates/` directory to `syndicate/` in the project root.
2. Detect the PR target branch (`git symbolic-ref refs/remotes/origin/HEAD`, fall back to `main`). If no remote exists, record `none`. Write the result to `syndicate/.pr-target`.
3. Create a branch `syndicate/run-<N>` off the current HEAD (N increments if prior runs exist in the branch namespace).
4. Commit the `syndicate/` directory on that branch.
5. Tag it `syndicate-seed-<N>` (local only).

If `syndicate/` exists, you are resuming. Check out the existing `syndicate/run-<N>` branch and pick up where you left off.
```

- [ ] **Step 2: Verify**

Read `plugin/skills/run/SKILL.md` lines 12-25 to confirm. No references to `git init` or bare `seed` tag should remain.

- [ ] **Step 3: Commit**

```bash
git add plugin/skills/run/SKILL.md
git commit -m "Update SKILL.md bootstrap: branch workflow instead of nested git repo"
```

---

### Task 2: Update SKILL.md Generation Loop Step 6

**Files:**
- Modify: `plugin/skills/run/SKILL.md` (step 6 in "Every Generation After That", ~line 40)

The spec's generation loop design describes squash-merge-and-cleanup. SKILL.md step 6 should reflect this since it is the primary reference the meta-agent reads.

- [ ] **Step 1: Replace step 6**

old_string:
```
6. **Keep best, prune rest.** The highest-scoring variant becomes the parent for the next generation. Other variants are marked pruned in `branches.jsonl`.
```

new_string:
```
6. **Squash-merge best, clean up rest.** Squash-merge the winning variant onto `syndicate/run-<N>` as a single commit: `gen-<G>: <one sentence>`. Mark other variants pruned in `branches.jsonl`. Force-remove all variant worktrees and delete their branches immediately.
```

- [ ] **Step 2: Verify**

Read `plugin/skills/run/SKILL.md` lines 38-42 to confirm.

- [ ] **Step 3: Commit**

```bash
git add plugin/skills/run/SKILL.md
git commit -m "Update SKILL.md step 6: squash-merge and cleanup"
```

---

### Task 3: Add PR Creation to SKILL.md Stopping Conditions

**Files:**
- Modify: `plugin/skills/run/SKILL.md` (stopping conditions, ~line 75)

- [ ] **Step 1: Add PR step and update job mode text**

old_string:
```
On stopping, copy the best attempt to the project root.

**Job mode:** Write a dissolution report to `reports/final.md` summarizing what was accomplished and what was learned. The syndicate dissolves.
```

new_string:
```
On stopping, copy the best attempt to the project root. Commit the final state on `syndicate/run-<N>`. Read `syndicate/.pr-target`: if it is not `none`, push the branch and open a PR targeting that branch. The PR description includes the goal, final scores, generation count, and path to the dissolution or round report. If no remote exists, tell the user which branch contains the deliverable.

**Job mode:** Write a dissolution report to `reports/final.md` summarizing what was accomplished and what was learned. The syndicate dissolves.
```

- [ ] **Step 2: Verify**

Read `plugin/skills/run/SKILL.md` lines 75-90 to confirm the PR step is between the stopping copy and the mode-specific behavior.

- [ ] **Step 3: Commit**

```bash
git add plugin/skills/run/SKILL.md
git commit -m "Add PR creation step to SKILL.md stopping conditions"
```

---

### Task 4: Replace Git Workflow Section in loop.md

**Files:**
- Modify: `plugin/skills/run/references/loop.md` (Git Workflow section, ~line 135)

This is the largest edit. It replaces the old per-variant branching, the seed tag, and the parent selection subsection. The `syndicate-seed-<N>` tag rename is part of this replacement.

- [ ] **Step 1: Replace the entire Git Workflow section including Parent Selection**

old_string:
```
## Git Workflow

Each generation step may produce multiple variant branches (`gen-N-a`, `gen-N-b`, etc.). The winning variant becomes the parent for the next generation. Commit messages should be a single sentence.

At bootstrap, the initial commit is tagged `seed`. Generation 1 branches from `seed`.

```bash
# For each variant in parallel:
git checkout -b gen-<N>-<V> <parent-branch>
# ... make changes, produce attempt ...
git add -A
git commit -m "gen-<N>-<V>: <one sentence>"
```

### Parent Selection

Read `archive/branches.jsonl`. Select from winning variants only (non-pruned branches). Highest-scoring ~70% of the time. Random ~30% for exploration.
```

new_string:
```
## Git Workflow

### Bootstrap

At bootstrap, detect the PR target branch (`git symbolic-ref refs/remotes/origin/HEAD`, fall back to `main`). If no remote, record `none`. Write the result to `syndicate/.pr-target`.

Create `syndicate/run-<N>` off the current HEAD (N increments if prior runs exist). Commit the initial `syndicate/` directory. Tag it `syndicate-seed-<N>` (local only, not pushed).

### Generation Branches

Variant branches are ephemeral. Claude Code's `isolation: "worktree"` creates them automatically when dispatching task agents. After scoring:

Squash-merge the winning variant onto `syndicate/run-<N>`:

    git checkout syndicate/run-<N>
    git merge --squash <worktree-branch>
    git commit -m "gen-<G>: <one sentence>"

Force-remove all variant worktrees and delete their branches:

    git worktree remove --force <worktree-path>
    git branch -D <worktree-branch>

After cleanup, only `syndicate/run-<N>` exists. The parent for the next generation is always the tip of this branch.

### Completion

On stopping, commit the final state (deliverable + `syndicate/` directory) on `syndicate/run-<N>`. If `syndicate/.pr-target` is not `none`, push the branch and open a PR targeting that branch. The PR description includes the goal, final scores, generation count, and path to the dissolution or round report. If no remote, tell the user which branch contains the deliverable.
```

- [ ] **Step 2: Verify**

Read `plugin/skills/run/references/loop.md` lines 135-175. Confirm:
- No references to `seed` (bare), `git checkout -b gen-<N>-<V>`, or parent selection by random sampling
- `syndicate-seed-<N>` tag is present
- Squash-merge and force-cleanup commands are present
- Completion PR step matches spec

- [ ] **Step 3: Commit**

```bash
git add plugin/skills/run/references/loop.md
git commit -m "Replace loop.md git workflow: branch-and-squash with cleanup"
```

---

### Task 5: Clarify branches.jsonl Documentation in loop.md

**Files:**
- Modify: `plugin/skills/run/references/loop.md` (branches.jsonl section, ~line 126)

This task targets lines above Task 4's edit region, so it is unaffected by Task 4's changes.

- [ ] **Step 1: Add clarification after the branches.jsonl format**

old_string:
```
One line per variant. New fields: `variant` (letter within the generation), `change` (one sentence describing what this branch tried). Only the winning variant has `pruned: false`.
```

new_string:
```
One line per variant. The `branch` field stores the logical variant name (e.g., `gen-3-b`), not the ephemeral worktree branch name. The `parent` field references the previous generation's winning variant. Since squash-merges land on `syndicate/run-<N>`, the parent for all variants in a generation is the tip of that branch. Only the winning variant has `pruned: false`.
```

- [ ] **Step 2: Verify**

Read `plugin/skills/run/references/loop.md` lines 126-140 to confirm.

- [ ] **Step 3: Commit**

```bash
git add plugin/skills/run/references/loop.md
git commit -m "Clarify branches.jsonl: logical variant names, not worktree branch names"
```

---

### Task 6: Add .pr-target to Project Structure in loop.md

**Files:**
- Modify: `plugin/skills/run/references/loop.md` (Project Structure tree, near end of file)

- [ ] **Step 1: Insert .pr-target as first entry in the tree**

old_string:
```
syndicate/
├── goal.md              # User's goal (written gen 1, fixed)
```

new_string:
```
syndicate/
├── .pr-target           # PR target branch (detected at bootstrap)
├── goal.md              # User's goal (written gen 1, fixed)
```

- [ ] **Step 2: Verify**

Read the Project Structure section to confirm `.pr-target` appears and all other entries are preserved.

- [ ] **Step 3: Commit**

```bash
git add plugin/skills/run/references/loop.md
git commit -m "Add .pr-target to project structure in loop.md"
```

---

### Task 7: Add Venture Mode Branch Lifetime to loop.md Round Transitions

**Files:**
- Modify: `plugin/skills/run/references/loop.md` (Round Transitions section, ~line 285)

- [ ] **Step 1: Add branch lifetime note**

old_string:
```
**What persists:** `goal.md` (fixed forever), `meta-notes.md` (distilled at round boundaries), `learned-agents/` (evolving), all `metrics/*`, `archive/branches.jsonl`, `venture.jsonl`.
```

new_string:
```
**What persists:** `goal.md` (fixed forever), `meta-notes.md` (distilled at round boundaries), `learned-agents/` (evolving), all `metrics/*`, `archive/branches.jsonl`, `venture.jsonl`.

**Branch lifetime:** One `syndicate/run-<N>` branch spans all rounds. Round boundaries do not create new branches. The PR is opened at dissolution, not at each round boundary. Round reports are committed to the branch as they are written.
```

- [ ] **Step 2: Verify**

Read `plugin/skills/run/references/loop.md` lines 285-300 to confirm the new paragraph follows the "What persists" line.

- [ ] **Step 3: Commit**

```bash
git add plugin/skills/run/references/loop.md
git commit -m "Add venture mode branch lifetime note to loop.md"
```

---

### Task 8: Final Verification

- [ ] **Step 1: Read both modified files in full**

Read `plugin/skills/run/SKILL.md` and `plugin/skills/run/references/loop.md` end to end. Check for:
- No remaining references to `git init`, bare `seed` tag, or `git checkout -b gen-<N>-<V>`
- Coherence agent prompt (~loop.md line 65-90) still works: it references worktree branches during scoring, which happens before cleanup. No change needed.
- All cross-references between SKILL.md and loop.md are consistent

- [ ] **Step 2: Verify templates are unchanged**

List files in `plugin/skills/run/templates/` and confirm `.gitkeep` files still exist in `archive/`, `attempts/`, `learned-agents/`, `metrics/`, `reports/`, `skills/domain/`.

- [ ] **Step 3: Commit fixups if any old-workflow references remain**

Only if issues found in steps 1-2.
