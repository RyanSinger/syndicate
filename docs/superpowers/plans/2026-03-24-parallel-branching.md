# Parallel Branching Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the serial one-branch-per-generation loop with parallel branching. Multiple task agents run simultaneously in separate worktrees, the meta-agent scores the batch, and the coherence agent evaluates the spread.

**Architecture:** Changes to SKILL.md (the generation loop), loop.md (invocation patterns, metrics formats, git workflow), CLAUDE.md (conventions), and the cron plan. The coherence agent system prompt does not change. The spec is at `docs/superpowers/specs/2026-03-24-parallel-branching-design.md`.

**Tech Stack:** Markdown

---

### Task 1: Update SKILL.md generation loop

**Files:**
- Modify: `plugin/skills/run/SKILL.md`

**Context:** The "Every Generation After That" section (lines 33-42) needs to describe parallel branching instead of serial single-branch execution. Read the full file before starting. The user's global rule: NEVER use dashes (em dashes, en dashes, or hyphens as separators/punctuation) in any written content.

- [ ] **Step 1: Replace the generation loop steps**

Replace lines 35-40 (the six numbered steps) with:

```
1. **Diagnose.** What's weakest in the last attempt? Are the criteria still measuring the right things?
2. **Propose 1 to N changes.** Each targets the diagnosed weakness from a different angle. Decide how many based on confidence: 1 if the path is obvious, 3 to 4 if stuck or exploring early. State what each change is expected to improve and why.
3. **Attempt all in parallel.** Each proposed change gets its own task agent running in a separate git worktree (`isolation: "worktree"`). All run simultaneously as background agents. Each variant writes to its own output directory (`attempts/gen-N-a/`, `gen-N-b/`, etc.).
4. **Score all.** Evaluate each variant honestly against current criteria. Record the winning variant's score in `scores.jsonl`. Record all variants in `branches.jsonl`.
5. **Coherence check on batch.** A separate agent reviews the batch: all variant scores, the spread, complexity growth, and the provisional winner's diff stats. It decides: continue, flag, or prune. On `flag`, you must change your approach. Each `flag` increments the plateau counter; `continue` or `prune` resets it. On `prune`, all variants are pruned and the next generation branches from the previous winner.
6. **Keep best, prune rest.** The highest-scoring variant becomes the parent for the next generation. Other variants are marked pruned in `branches.jsonl`.
7. **Record what you learned.** Write observations in `meta-notes.md`. Note what was tried in parallel, what worked, what didn't. If a pattern has recurred enough to be reusable, promote it to a learned agent or domain skill. Distill meta-notes when they get too long.
```

- [ ] **Step 2: Add wide vs. narrow guidance**

After line 42 ("The syndicate governs itself. No generation count from the user."), add:

```
When to go wide (3 to 4 variants): low scores, unclear direction, first few generations, criteria just changed. When to go narrow (1 to 2 variants): scores improving steadily, clear next step, approaching convergence. All variants in a generation use the same model.
```

- [ ] **Step 3: Commit**

~~~
git add plugin/skills/run/SKILL.md
git commit -m "Update generation loop for parallel branching"
~~~

### Task 2: Update loop.md invocations, metrics, and git workflow

**Files:**
- Modify: `plugin/skills/run/references/loop.md`

**Context:** Multiple sections need updating: Task Agent invocation (parallel dispatch), Coherence Agent invocation (batch prompt), metrics formats (new fields), branches.jsonl format, git workflow (branch naming), and parent selection. Read the full file before starting. The spec is at `docs/superpowers/specs/2026-03-24-parallel-branching-design.md`.

- [ ] **Step 1: Update Task Agent invocation for parallel dispatch**

In the Task Agent subsection (around line 11), replace the intro paragraph and the Agent tool invocation block. The new intro should explain parallel dispatch: each variant gets its own task agent with `isolation: "worktree"` and `run_in_background: true`. The output directory uses the variant suffix (`syndicate/attempts/gen-N-a/`). Show the Agent tool invocation with these additions:

```
Agent tool:
  description: "Gen <N> variant <V>: produce deliverable"
  subagent_type: "syndicate:task"
  isolation: "worktree"
  run_in_background: true
  prompt: |
    <contents of prompts/task.md>

    Skills:
    <concatenated contents of all files in skills/*.md and skills/domain/*.md>

    Goal:
    <contents of goal.md>

    Output directory: syndicate/attempts/gen-<N>-<V>/
    Put all output files in the output directory above. Create it if needed.
```

After the invocation block: "Dispatch all variants simultaneously. After all complete, check out each variant's branch to read its output for scoring."

- [ ] **Step 2: Update Coherence Agent invocation for batch prompt**

In the Coherence Agent subsection (around line 56), update the intro to mention batch evaluation. Replace the Agent tool invocation block with the batch prompt format from the spec:

```
Agent tool:
  description: "Gen <N>: coherence check (batch)"
  subagent_type: "syndicate:coherence"
  prompt: |
    Generation: <N>
    Branch: gen-<N>-a (best), gen-<N>-b, gen-<N>-c
    Variants tried: <count>

    Scores:
      gen-<N>-a: <score> (<change description>)
      gen-<N>-b: <score> (<change description>)
      gen-<N>-c: <score> (<change description>)

    Recent score trajectory:
    <last 10 lines of scores.jsonl, winning variants only>

    Complexity trend:
    <last 10 lines of complexity.jsonl>

    Git log (last 10):
    <git log --oneline -10>

    Last change (file stats only, provisional winner by score):
    <git diff of highest-scoring branch --stat>

    Respond as JSON only.
```

Add a note: "These changes are to the dynamic invocation prompt, not the static system prompt in `agents/coherence.md`. The coherence firewall is not affected."

Keep the three existing notes after the invocation (generation field, invalid JSON recovery, flag handling).

- [ ] **Step 3: Update branches.jsonl format**

In the archive/branches.jsonl section (around line 107), replace the example with:

```jsonl
{"generation": 3, "variant": "a", "branch": "gen-3-a", "parent": "gen-2-a", "score": 3.2, "pruned": true, "change": "switched to grid layout"}
{"generation": 3, "variant": "b", "branch": "gen-3-b", "parent": "gen-2-a", "score": 4.1, "pruned": false, "change": "added responsive breakpoints"}
```

Add a note: "One line per variant. New fields: `variant` (letter within the generation), `change` (one sentence describing what this branch tried). Only the winning variant has `pruned: false`."

- [ ] **Step 4: Add variants_tried to complexity.jsonl**

In the complexity.jsonl section (around line 96), add `variants_tried` to the example:

```jsonl
{"generation": 1, "skill_tokens": 45, "prompt_tokens": 12, "file_count": 3, "learned_agent_count": 0, "learned_agent_invocations": 0, "variants_tried": 1}
```

- [ ] **Step 5: Add winning-variant-only note to scores.jsonl**

In the scores.jsonl section (around line 96), add a note after the example: "Only the winning variant's score is appended per generation step. All variant scores are recorded in `branches.jsonl`. This keeps the coherence agent's score trajectory clean: one entry per generation, not one per variant."

- [ ] **Step 6: Update Git Workflow section**

In the Git Workflow section (around line 113), update the branch naming and example:

Replace the bash example block with:

```bash
# For each variant in parallel:
git checkout -b gen-<N>-<V> <parent-branch>
# ... make changes, produce attempt ...
git add -A
git commit -m "gen-<N>-<V>: <one sentence>"
```

Update the intro to mention variant suffixes: "Each generation step may produce multiple variant branches (`gen-N-a`, `gen-N-b`, etc.). The winning variant becomes the parent for the next generation."

- [ ] **Step 7: Update Parent Selection**

In the Parent Selection subsection (around line 128), change:

"Read `archive/branches.jsonl`. Highest-scoring non-pruned branch ~70% of the time. Random non-pruned branch ~30% for exploration."

to:

"Read `archive/branches.jsonl`. Select from winning variants only (non-pruned branches). Highest-scoring ~70% of the time. Random ~30% for exploration."

- [ ] **Step 8: Commit**

~~~
git add plugin/skills/run/references/loop.md
git commit -m "Update loop.md for parallel branching: batch coherence, variant branches, new metrics fields"
~~~

### Task 3: Update CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

**Context:** The Key Conventions section mentions single branches per generation. Read the full file before starting.

- [ ] **Step 1: Update branch convention**

Replace line 39:

```
- Each generation gets its own git branch (`gen-N`), branched from the best-scoring non-pruned parent
```

with:

```
- Each generation may produce parallel variant branches (`gen-N-a`, `gen-N-b`, etc.) in separate worktrees. The best-scoring variant survives; others are pruned
```

- [ ] **Step 2: Commit**

~~~
git add CLAUDE.md
git commit -m "Update CLAUDE.md: parallel variant branches"
~~~

### Task 4: Update cron plan

**Files:**
- Modify: `docs/superpowers/plans/2026-03-24-venture-cron-jobs.md`

**Context:** The cron runner's "evolving" phase describes a serial single-branch generation. It needs to support parallel dispatch within a single tick. Read the cron plan before starting.

- [ ] **Step 1: Update the evolving phase steps**

In the cron-runner.md prompt (around line 140), replace step 4:

```
4. **Diagnose** weaknesses. **Propose** one small change.
```

with:

```
4. **Diagnose** weaknesses. **Propose** 1 to N changes (more when stuck, fewer when converging).
```

Replace step 6:

```
6. **Attempt**: invoke the task agent subagent per loop.md.
```

with:

```
6. **Attempt all in parallel**: invoke one task agent per proposed change, each in its own worktree per loop.md. Wait for all to complete.
```

Replace step 7:

```
7. **Score**: evaluate against criteria. Append to `metrics/scores.jsonl`.
```

with:

```
7. **Score all variants**: evaluate each against criteria. Append winning variant to `metrics/scores.jsonl`.
```

Replace step 9:

```
9. Record branch in `archive/branches.jsonl`.
```

with:

```
9. Record all variants in `archive/branches.jsonl` (one line per variant, winning variant has `pruned: false`).
```

- [ ] **Step 2: Commit**

~~~
git add docs/superpowers/plans/2026-03-24-venture-cron-jobs.md
git commit -m "Update cron plan for parallel branching"
~~~

### Task 5: Final verification

- [ ] **Step 1: Verify SKILL.md**

Read SKILL.md and confirm:
1. Generation loop describes parallel branching (propose N changes, attempt all in parallel, score all, batch coherence)
2. Wide vs. narrow guidance is present
3. All variants use the same model
4. Prune behavior for batches is described

- [ ] **Step 2: Verify loop.md**

Read loop.md and confirm:
1. Task agent invocation shows `isolation: "worktree"` and `run_in_background: true`
2. Output directory uses variant suffix (`gen-N-a/`)
3. Coherence agent invocation shows batch prompt format with all variant scores
4. branches.jsonl has `variant` and `change` fields
5. complexity.jsonl has `variants_tried` field
6. Git workflow shows `gen-N-V` branch naming
7. Parent selection says "winning variants only"

- [ ] **Step 3: Verify CLAUDE.md**

Read CLAUDE.md and confirm branch convention mentions parallel variants and worktrees.

- [ ] **Step 4: Verify cron plan**

Read the cron plan and confirm the evolving phase supports parallel dispatch.

- [ ] **Step 5: Cross-file consistency**

Verify:
- Branch naming is consistent across all files (`gen-N-a/b/c` pattern)
- The coherence batch prompt format in loop.md matches what SKILL.md describes
- scores.jsonl records only the winning variant (consistent between loop.md and SKILL.md)
- branches.jsonl format is consistent between loop.md and the spec
