# Loop Reference

Procedural details for running governed evolution. Read this when you need specifics on subagent invocation, metrics formats, or git workflow.

## Subagent Invocation

Strip the `CLAUDECODE` env var to allow nesting. Read agent prompts fresh from the skill path each time.

### Task Agent

```bash
CLAUDECODE= claude -p "<contents of agents/task.md>

<contents of prompts/task.md>

Skills:
<concatenated contents of all files in skills/ and skills/domain/>

Goal:
<contents of goal.md>

Produce the deliverable. Put all output files in the current directory." \
  --model <chosen model>
```

Copy output into `attempts/gen-<N>/`.

### Coherence Agent

Build a limited view first — scores, complexity, git log, diff stats. Never include code or file contents.

```bash
CLAUDECODE= claude -p "<contents of agents/coherence.md>

Generation: <N>
Branch: <current branch>

Recent scores:
<last 10 lines of metrics/scores.jsonl>

Complexity trend:
<last 10 lines of metrics/complexity.jsonl>

Git log (last 10):
<git log --oneline -10>

Last change (file stats only):
<git diff HEAD~1 --stat>

Respond as JSON only." --model haiku
```

## Metrics Formats

All metrics files are append-only JSONL in `metrics/`.

### scores.jsonl

```jsonl
{"generation": 1, "scores": {"input_validation": 2, "error_messages": 1}, "avg": 1.5, "model": "haiku", "criteria_changed": false, "timestamp": "2026-03-23T14:30:00Z"}
```

### complexity.jsonl

```jsonl
{"generation": 1, "skill_tokens": 45, "prompt_tokens": 12, "file_count": 3}
```

### coherence-log.jsonl

```jsonl
{"generation": 1, "status": "continue", "reason": "Scores improving, complexity stable"}
```

### archive/branches.jsonl

```jsonl
{"generation": 1, "branch": "gen-1", "parent": "seed", "score": 1.5, "pruned": false}
```

## Git Workflow

Each generation gets a branch. Commit messages should be a single sentence.

```bash
git checkout -b gen-<N> <parent-branch>
# ... make changes, produce attempt ...
git add -A
git commit -m "gen-<N>: <one sentence>"
```

### Parent Selection

Read `archive/branches.jsonl`. Highest-scoring non-pruned branch ~70% of the time. Random non-pruned branch ~30% for exploration.

## Discovery Phase (Venture Mode)

After shipping a round's best attempt, the meta-agent shifts from execution to discovery. This is not a subagent call — you do this yourself.

1. Read the shipped deliverable in context of the project.
2. Read `meta-notes.md` for accumulated learnings.
3. Read `venture.jsonl` (if it exists) for what previous rounds focused on.
4. Identify 3-5 candidate improvements, each as one sentence.
5. Pick the highest-value one. Write a brief rationale.
6. Rewrite `criteria.md` targeting that improvement (3-7 criteria, same as gen 1).
7. Append to `meta-notes.md`: what was chosen, what was rejected, why. Use a `--- Round N ---` separator.
8. Append to `venture.jsonl` (create it on the first round boundary).
9. Resume the evolution loop. The next generation continues the global count.

Discovery should be fast — one deliberate pause, not a sub-loop. If you can't find anything worth improving, the venture is done. Dissolve.

## Round Transitions

Generation numbering is **global**. If round 1 ends at gen-12, round 2 starts at gen-13.

**What resets:** `criteria.md` (rewritten for the new focus).

**What may be revised:** `skills/approach.md`, `prompts/task.md` — adjust if the new focus needs a different approach.

**What persists:** `goal.md` (fixed forever), `meta-notes.md` (append-only), all `metrics/*`, `archive/branches.jsonl`, `venture.jsonl`.

### venture.jsonl

Created at the first round boundary. One line per completed round.

```jsonl
{"round": 1, "goal_focus": "initial implementation", "generations": 12, "best_score": 4.2, "shipped_at": "gen-12", "timestamp": "2026-03-24T10:00:00Z"}
```

### Coherence Agent at Round Boundaries

The coherence agent's fixed prompt does not change. But criteria changes at a round boundary are larger than mid-round tweaks — scores will drop because the scoring dimensions changed. When invoking the coherence agent for the first generation of a new round, add this to the context:

```
Note: Criteria changed at generation <N> (new venture round). Score drops from criteria changes are expected.
```

## Project Structure

After bootstrap, `syndicate/` in the project root contains:

```
syndicate/
├── goal.md              # User's goal (written gen 1, fixed)
├── criteria.md          # Acceptance criteria (evolves)
├── meta-notes.md        # Persistent memory (append-only)
├── venture.jsonl         # Round history (venture mode only, append-only)
├── skills/
│   ├── approach.md
│   └── domain/
├── prompts/
│   └── task.md
├── attempts/
│   └── gen-N/
├── metrics/
│   ├── scores.jsonl
│   ├── complexity.jsonl
│   └── coherence-log.jsonl
└── archive/
    └── branches.jsonl
```
