# Git Isolation: Host Repo Compatibility

## Problem

When the syndicate runs inside a project that has its own git repo with CI/CD (e.g., GitHub Pages), it causes two problems:

1. **Nested `.git` breaks CI.** The bootstrap step runs `git init` inside `syndicate/`, creating an embedded repo. GitHub Pages (and similar CI) treats this as a submodule without a `.gitmodules` entry, failing the build.
2. **Orphaned worktrees and branches.** Variant branches (`gen-1-a`, `gen-1-b`, etc.) and their worktrees linger in the host repo after the run, polluting the branch namespace.

Observed in `~/vex_events/`: GitHub Pages build failed, requiring manual removal of the nested `.git` and recommit of `syndicate/` as regular files (commit `bb5e5d6`). Four orphaned worktrees remain.

## Constraints

- The final deliverable must be proposed as a PR to the host project
- The `syndicate/` directory (metrics, meta-notes, reports) ships with the PR for context
- Worktrees during the run are acceptable (local only), but must be cleaned up
- Intermediate variant branches must not persist after each generation
- No nested `.git` directory

## Design: Branch and Squash

### Bootstrap

1. Copy `templates/` to `syndicate/` in the project root (unchanged)
2. Create a branch `syndicate/run-<N>` off the current HEAD, where N increments if prior syndicate runs exist in the branch namespace
3. Commit the initial `syndicate/` directory on that branch
4. Tag it `syndicate-seed-<N>` on that branch

No `git init`. No nested repo. The `syndicate/` directory is regular files in the host project's git.

### Generation Loop

Each generation follows this cycle:

1. **Dispatch variants.** Each variant gets a task agent with `isolation: "worktree"`. Claude Code creates worktree branches automatically (e.g., `worktree-agent-*`). All variants run simultaneously as background agents.

2. **Score all variants.** Meta-agent checks out each worktree branch to read output and score against criteria.

3. **Squash-merge winner.** The highest-scoring variant is squash-merged onto `syndicate/run-<N>` with a single commit: `gen-<G>: <one sentence description>`.

4. **Cleanup immediately.** All variant worktrees are removed and their branches deleted. After cleanup, only `syndicate/run-<N>` exists.

`branches.jsonl` still records every variant with its score, so no data is lost. The git history on the syndicate branch is the winning lineage only, one commit per generation.

### Completion

When the syndicate converges or dissolves:

1. Copy the best attempt to the project root (unchanged)
2. Commit the final state on `syndicate/run-<N>` (deliverable files + full `syndicate/` directory)
3. Open a PR from `syndicate/run-<N>` to the host project's main branch
4. PR description includes: the goal, final scores, generation count, and path to the dissolution/round report

The PR commit history tells the evolution story: seed, gen-1, gen-2, ..., final deliverable.

## Files to Change

### SKILL.md

- **Line 14 (bootstrap):** Replace "initializing a git repo, creating an initial commit, and tagging it `seed`" with the branch creation workflow: create `syndicate/run-<N>` branch, commit, tag `syndicate-seed-<N>`
- **Stopping conditions section:** Add PR creation step after copying best attempt to project root

### references/loop.md

- **Git Workflow section (lines 136-148):** Replace per-variant `git checkout -b gen-<N>-<V>` branching with the squash-merge-and-cleanup flow. Variant branches are ephemeral (created by `isolation: "worktree"`, cleaned up after scoring). Winner is squash-merged onto `syndicate/run-<N>`.
- **Line 139 (seed tag):** Replace `seed` tag with `syndicate-seed-<N>`
- **Parent Selection (lines 149-151):** Simplify. The parent is always the tip of `syndicate/run-<N>` (the last squash-merged winner). `branches.jsonl` still records lineage for the meta-agent's decision-making, but git branching is just "branch from syndicate/run-<N>".

### Templates

- Remove `.gitkeep` files. They were needed for the nested repo's initial commit to capture empty directories. With the branch approach, the initial commit on `syndicate/run-<N>` captures the directory structure directly. Empty directories that need to exist can use placeholder files if git requires it, but `.gitkeep` specifically is no longer motivated by a nested repo bootstrap.

## What Doesn't Change

- Three-tier governance, coherence firewall, metrics formats, scoring
- `branches.jsonl` still records every variant (data history is complete, git history is simplified)
- `isolation: "worktree"` still used for parallel dispatch
- Discovery phase, venture mode, round transitions
- Learned agents, domain skills, meta-notes distillation
