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
2. Determine the PR target branch: use the repo's default branch (`git symbolic-ref refs/remotes/origin/HEAD` or fall back to `main`). Record it in `syndicate/.pr-target` so it is stable for the run's duration. If no remote exists, record `none` and skip PR creation at completion.
3. Create a branch `syndicate/run-<N>` off the current HEAD, where N increments if prior syndicate runs exist in the branch namespace
4. Commit the initial `syndicate/` directory on that branch
5. Tag it `syndicate-seed-<N>` on that branch (local only, not pushed)

No `git init`. No nested repo. The `syndicate/` directory is regular files in the host project's git.

### Generation Loop

Each generation follows this cycle:

1. **Dispatch variants.** Each variant gets a task agent with `isolation: "worktree"`. Claude Code creates worktree branches automatically (e.g., `worktree-agent-*`). All variants run simultaneously as background agents.

2. **Score all variants.** Meta-agent checks out each worktree branch to read output and score against criteria.

3. **Squash-merge winner.** The highest-scoring variant is squash-merged onto `syndicate/run-<N>` with a single commit: `gen-<G>: <one sentence description>`. The squash includes everything: deliverable files, `syndicate/attempts/`, and all `syndicate/` state updates. The `attempts/` directory is part of the syndicate record.

4. **Cleanup immediately.** All variant worktrees are removed (`git worktree remove --force`) and their branches deleted (`git branch -D`). Force flags are required because crashed or timed-out agents may leave dirty worktrees. After cleanup, only `syndicate/run-<N>` exists.

`branches.jsonl` still records every variant with its score. The `branch` field stores the logical variant name (`gen-3-b`), not the ephemeral worktree branch name. The git history on the syndicate branch is the winning lineage only, one commit per generation.

### Completion

When the syndicate converges or dissolves:

1. Copy the best attempt to the project root (unchanged)
2. Commit the final state on `syndicate/run-<N>` (deliverable files + full `syndicate/` directory)
3. If a remote exists (`.pr-target` is not `none`): push `syndicate/run-<N>` and open a PR targeting the recorded branch. If no remote exists: tell the user which branch contains the deliverable and skip PR creation.
4. PR description includes: the goal, final scores, generation count, and path to the dissolution/round report

The PR commit history tells the evolution story: seed, gen-1, gen-2, ..., final deliverable.

### Venture Mode

One `syndicate/run-<N>` branch spans all rounds. Round boundaries do not create new branches. The PR is opened at dissolution, not at each round boundary. Round reports are committed to the branch as they are written.

## Files to Change

### SKILL.md

- **Line 14 (bootstrap):** Replace "initializing a git repo, creating an initial commit, and tagging it `seed`" with the branch creation workflow: detect PR target, create `syndicate/run-<N>` branch, commit, tag `syndicate-seed-<N>`
- **Stopping conditions section:** Add PR creation step (with no-remote fallback) after copying best attempt to project root

### references/loop.md

- **Git Workflow section (lines 136-148):** Replace per-variant `git checkout -b gen-<N>-<V>` branching with the squash-merge-and-cleanup flow. Variant branches are ephemeral (created by `isolation: "worktree"`, cleaned up with `--force` after scoring). Winner is squash-merged onto `syndicate/run-<N>`.
- **Line 139 (seed tag):** Replace `seed` tag with `syndicate-seed-<N>` (local only)
- **Parent Selection (lines 149-151):** Simplify. The parent is always the tip of `syndicate/run-<N>` (the last squash-merged winner). `branches.jsonl` still records lineage for the meta-agent's decision-making, but git branching is just "branch from syndicate/run-<N>".
- **branches.jsonl format (lines 129-133):** The `branch` field stores the logical variant name (`gen-3-b`), not the ephemeral worktree branch name. No format change needed.
- **Coherence agent invocation (line 87):** `git diff --stat` runs against the worktree branch during scoring (before cleanup). No change needed to the coherence prompt format.

### Templates

- Keep `.gitkeep` files. Git does not track empty directories, so these are still needed for `metrics/`, `reports/`, `archive/`, `attempts/`, `learned-agents/`, and `skills/domain/` to exist after the initial commit.

## What Doesn't Change

- Three-tier governance, coherence firewall, metrics formats, scoring
- `branches.jsonl` still records every variant (data history is complete, git history is simplified)
- `isolation: "worktree"` still used for parallel dispatch
- Discovery phase, venture mode round transitions, generation numbering
- Learned agents, domain skills, meta-notes distillation
