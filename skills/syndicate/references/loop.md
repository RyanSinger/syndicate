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

## Project Structure

After bootstrap, `syndicate/` in the project root contains:

```
syndicate/
├── goal.md              # User's goal (written gen 1, fixed)
├── criteria.md          # Acceptance criteria (evolves)
├── meta-notes.md        # Persistent memory (append-only)
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
