# Parallel Branching

Replace the serial one-branch-per-generation loop with parallel branching. The meta-agent proposes multiple alternative changes, runs them simultaneously in separate worktrees, scores the batch, and keeps the best. Inspired by TurkoMatic's (2011) parallel subtask model, adapted to the syndicate's evolutionary approach.

## The Generation Loop

Each generation step:

1. **Diagnose.** What's weakest? (Same as now.)
2. **Propose changes.** The meta-agent proposes 1 to N alternative changes, each targeting the diagnosed weakness from a different angle. It decides how many based on its confidence: 1 if the path is obvious, 3 to 4 if stuck or exploring.
3. **Attempt all in parallel.** Each proposed change gets its own task agent, running in a separate git worktree via `isolation: "worktree"`. All run simultaneously as background agents.
4. **Score all.** The meta-agent scores each branch's output against current criteria.
5. **Coherence check on batch.** One coherence call sees all branch results together: scores, complexity growth, and the spread across branches.
6. **Keep best, prune rest.** The highest-scoring branch becomes the parent for the next generation. Other branches are recorded as pruned in `branches.jsonl`.
7. **Record what was learned.** Meta-notes capture what was tried, what worked, and why.

The generation number increments once per step, not once per branch. If generation 3 tries 3 parallel branches, they are gen-3-a, gen-3-b, gen-3-c. Generation 4 branches from the winner.

## Git Workflow Changes

### Branch naming

`gen-N-a`, `gen-N-b`, `gen-N-c` for parallel variants within a generation. The winner is noted in `branches.jsonl` so parent selection knows which one to branch from.

### Worktrees and output directories

Each parallel task agent runs with `isolation: "worktree"`, which gives it an isolated copy of the repo. The agent creates its branch, makes its changes, and commits.

Each variant writes to its own output directory: `syndicate/attempts/gen-N-a/`, `syndicate/attempts/gen-N-b/`, etc. The invocation prompt specifies the exact path, same as single-branch mode but with the variant suffix.

After all parallel agents complete, the meta-agent accesses each variant's output by checking out the corresponding branch (`gen-N-a`, `gen-N-b`, etc.) and reading its `syndicate/attempts/` directory. The meta-agent scores each variant, picks the provisional winner by score, then runs the coherence check.

### branches.jsonl

Currently one line per generation. Now one line per branch:

```jsonl
{"generation": 3, "variant": "a", "branch": "gen-3-a", "parent": "gen-2-a", "score": 3.2, "pruned": true, "change": "switched to grid layout"}
{"generation": 3, "variant": "b", "branch": "gen-3-b", "parent": "gen-2-a", "score": 4.1, "pruned": false, "change": "added responsive breakpoints"}
{"generation": 3, "variant": "c", "branch": "gen-3-c", "parent": "gen-2-a", "score": 3.8, "pruned": true, "change": "rewrote hero section copy"}
```

New fields: `variant` (letter within the generation) and `change` (one sentence describing what this branch tried). The `change` field gives the coherence agent and meta-agent a quick summary without reading code.

### Parent selection

Same rule as before (70% best-scoring non-pruned, 30% random non-pruned), but selecting from winning variants only, not from every branch that was tried.

## Coherence Agent Batch Evaluation

The coherence agent sees the full picture of what the syndicate explored in one call per generation step.

### Prompt changes

These changes are to the dynamic invocation prompt in loop.md (what the meta-agent passes in the Agent tool's `prompt` parameter), not the static system prompt in `agents/coherence.md`. The coherence firewall is not affected.

The meta-agent picks a provisional winner by score before the coherence call. The coherence agent prompt adds batch context:

```
Generation: 3
Branch: gen-3-a (best), gen-3-b, gen-3-c
Variants tried: 3

Scores:
  gen-3-a: 4.1 (responsive breakpoints)
  gen-3-b: 3.2 (grid layout)
  gen-3-c: 3.8 (hero copy rewrite)

Recent score trajectory:
<last 10 lines of scores.jsonl, showing winning variants only>

Complexity trend:
<last 10 lines of complexity.jsonl>

Git log (last 10):
<git log --oneline -10>

Last change (file stats only, provisional winner by score):
<git diff of highest-scoring branch --stat>

Respond as JSON only.
```

### What the coherence agent gains

The spread across variants. If the syndicate tried 3 things and they scored 4.1, 3.2, 3.8, that's a healthy spread with a clear winner. If they scored 2.1, 2.0, 2.2, that's a plateau regardless of how many branches were tried. If none beat the parent, that's a strong signal to flag or prune.

### Prune behavior for batches

A `prune` response from the coherence agent means the entire generation step is pruned: all variants are marked pruned in `branches.jsonl`. The next generation branches from the previous generation's winner (the parent of the pruned batch). The "all branches pruned" stopping condition triggers when there are no non-pruned branches left across all generations, same as before.

### Flag and plateau counter

One coherence call per generation step means one counter increment per step. Each `flag` increments the plateau counter; `continue` or `prune` resets it. This is unchanged from serial mode. Individual branch results do not contribute to the counter separately.

### What doesn't change

The coherence agent's system prompt (`agents/coherence.md`) doesn't change. It already evaluates trajectories and makes continue/flag/prune decisions. The richer input gives it better signal. The `tools: []` firewall stays intact.

### scores.jsonl

Record only the winning variant's score in the main trajectory. The batch details go in `branches.jsonl`. This keeps the coherence agent's score trajectory clean: one score per generation step, not N.

### Model for parallel branches

All parallel branches within a generation use the same model. The meta-agent selects the model once per generation step (same decision it makes now), and all variants run with that model. The `model` field in `scores.jsonl` records this single model. Mixed-model generations are not supported.

## Complexity and Cost

### Token cost

Parallel branches multiply the task agent cost per generation. If the meta-agent runs 3 branches, that's 3x the task agent tokens for that step. But the coherence check stays 1x (batch evaluation). If parallel exploration converges faster, the total cost could be lower.

### When to go wide vs. narrow

The meta-agent's judgment call. Signals to explore widely (3 to 4 branches): low scores, unclear direction, first few generations, just changed criteria. Signals to go narrow (1 to 2 branches): scores improving steadily, clear next step, approaching convergence.

### Convergence threshold

No changes. Average score 4.5+ for 2 consecutive generations still triggers convergence. The score is from the winning variant each generation.

### complexity.jsonl

Add a `variants_tried` field:

```jsonl
{"generation": 3, "skill_tokens": 45, "prompt_tokens": 12, "file_count": 3, "learned_agent_count": 0, "learned_agent_invocations": 0, "variants_tried": 3}
```

## Files Changed

**`plugin/skills/run/SKILL.md`**: Rewrite "Every Generation After That" section. Step 2 becomes "Propose 1 to N changes." Step 3 becomes "Attempt all in parallel." Steps 4 and 5 become batch scoring and batch coherence. Add guidance on when to go wide vs. narrow.

**`plugin/skills/run/references/loop.md`**: Update Task Agent invocation to show parallel dispatch with `isolation: "worktree"` and `run_in_background`. Update `branches.jsonl` format with `variant` and `change` fields. Update Coherence Agent invocation to show batch prompt format. Add `variants_tried` to `complexity.jsonl`. Update parent selection to select from winning variants. Update Git Workflow with `gen-N-a/b/c` naming.

**`plugin/agents/coherence.md`**: No changes. System prompt is generic enough. Firewall intact.

**`CLAUDE.md`**: Update Key Conventions to mention parallel branching with worktrees.

**`docs/superpowers/plans/2026-03-24-venture-cron-jobs.md`**: The cron runner runs one generation step per tick. A generation step now potentially dispatches multiple parallel task agents. Update the cron runner prompt (Task 3, lines 120-176) to support parallel dispatch within a single tick. The shell wrapper (`cron-runner.sh`) does not change.
