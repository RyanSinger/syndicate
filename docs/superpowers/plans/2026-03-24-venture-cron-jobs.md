# Venture Mode Cron Jobs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable venture mode to run autonomously across sessions via cron. A heartbeat fires periodically, runs one generation (or discovery phase), and exits. The venture's own convergence logic decides when to stop. No predefined generation count.

**Architecture:** A new `state.json` file externalizes phase tracking so each cron invocation is stateless. A shell wrapper handles locking and phase gating. A focused agent prompt drives single-step execution via `claude -p`. Existing files get minimal additions to maintain state.json during interactive use too.

**Tech Stack:** Markdown, JSONL, Bash

---

### Task 1: Add state.json bootstrap template

**Files:**
- Create: `skills/syndicate/templates/state.json`

The state file externalizes what the meta-agent currently holds in context: which phase, which generation, convergence tracking. Both interactive and cron paths read/write it.

- [ ] **Step 1: Create state.json template**

Create `skills/syndicate/templates/state.json`:

```json
{
  "mode": "job",
  "phase": "evolving",
  "current_generation": 0,
  "current_round": 1,
  "convergence_streak": 0,
  "flag_streak": 0,
  "last_run": null,
  "last_shipped_gen": null,
  "cron_enabled": false,
  "notify": null
}
```

Field definitions:
- `mode`: "job" or "venture". Set by meta-agent at bootstrap based on user intent.
- `phase`: "evolving" (running generations), "discovery" (between rounds), "paused" (user-frozen), or "dissolved" (venture complete).
- `current_generation`: last completed generation number. Next generation is N+1.
- `current_round`: current round number (starts at 1).
- `convergence_streak`: consecutive generations with average score >= 4.5. Reset on score drop.
- `flag_streak`: consecutive coherence flags. Reset on `continue` or `prune`.
- `last_run`: ISO timestamp of last completed generation/discovery.
- `last_shipped_gen`: branch name of last shipped best attempt (e.g. "gen-12").
- `cron_enabled`: whether cron runner should execute. Defaults false.
- `notify`: shell command for notifications (receives report text on stdin), or null for no notification. Default null.

---

### Task 2: Add state.json maintenance to loop.md

**Files:**
- Modify: `skills/syndicate/references/loop.md`

**Context:** State.json must stay current whether running interactively or via cron. Add update steps at the natural points in the existing loop.

- [ ] **Step 1: Add state.json section after Project Structure**

At the end of `loop.md` (after the Project Structure section, line 317), add a new section:

```markdown
## State Tracking

`state.json` in the syndicate root tracks phase and progress. Update it at these points:

### After each generation

After recording learnings (step 6), update `state.json`:
- Set `current_generation` to the generation just completed
- Set `last_run` to current ISO timestamp
- If coherence returned `flag`: increment `flag_streak`
- If coherence returned `continue`: reset `flag_streak` to 0
- If coherence returned `prune`: reset `flag_streak` to 0
- If average score >= 4.5: increment `convergence_streak`
- If average score < 4.5: reset `convergence_streak` to 0

### On convergence (entering discovery)

When stopping conditions are met:
- Set `phase` to `"discovery"`
- Set `last_shipped_gen` to the best attempt's branch name

### After discovery phase

After completing the discovery procedure (steps 1-9):
- If a new round was started: increment `current_round`, set `phase` to `"evolving"`, reset `convergence_streak` to 0
- If nothing worth improving: set `phase` to `"dissolved"`

### On dissolution

When the syndicate dissolves (any stopping condition in job mode, or discovery finds nothing in venture mode):
- Set `phase` to `"dissolved"`
```

- [ ] **Step 2: Add state.json to the Project Structure tree**

In the Project Structure section (line 296), add `state.json` after `goal.md`:

```
syndicate/
├── goal.md              # User's goal (written gen 1, fixed)
├── state.json           # Phase and progress tracking
├── criteria.md          # Acceptance criteria (evolves)
```

---

### Task 3: Create the cron runner agent prompt

**Files:**
- Create: `skills/syndicate/agents/cron-runner.md`

**Context:** This is the prompt passed to `claude -p` on each cron tick. It must be self-contained: read state from disk, execute one step, update state, exit. It follows the same evolution loop as the interactive meta-agent but compressed into a single-step executor.

- [ ] **Step 1: Create cron-runner.md**

Create `skills/syndicate/agents/cron-runner.md`:

```markdown
# Cron Runner

You are resuming a venture syndicate for one step. Read state, execute the next action, update state, and exit.

## Startup

1. Read `syndicate/state.json`. If `phase` is `paused` or `dissolved`, exit immediately with no changes.
2. If `current_generation` < 1, log "Scope of work not completed. Run gen 1 interactively first." and exit with no changes.
3. Read `syndicate/goal.md`, `syndicate/criteria.md`, `syndicate/meta-notes.md`.
4. Read the skill definition at `skills/syndicate/SKILL.md` and procedural reference at `skills/syndicate/references/loop.md`.

## If phase is "evolving"

Run ONE generation following the "Every Generation After That" procedure in SKILL.md:

1. Read the last attempt (check `state.json` for `current_generation`, look at `syndicate/attempts/gen-<N>/`).
2. Read `syndicate/metrics/scores.jsonl` (last 10 lines), `syndicate/metrics/coherence-log.jsonl` (last 5 lines), `syndicate/archive/branches.jsonl`.
3. Check `syndicate/learned-agents/registry.jsonl` for agents to invoke.
4. **Diagnose** weaknesses. **Propose** one small change.
5. Select parent branch per the parent selection rule in loop.md.
6. **Attempt**: invoke the task agent subagent per loop.md.
7. **Score**: evaluate against criteria. Append to `metrics/scores.jsonl`.
8. Record complexity in `metrics/complexity.jsonl`.
9. Record branch in `archive/branches.jsonl`.
10. **Coherence check**: invoke the coherence agent per loop.md. Append to `metrics/coherence-log.jsonl`.
11. **Record learnings** in `meta-notes.md`. Promote patterns if ready.
12. Git commit: `git add -A && git commit -m "gen-<N>: <one sentence>"`.
13. **Update `state.json`**: increment generation, update streaks, set timestamp.
14. **Check stopping conditions**: if `convergence_streak` >= 2, or `flag_streak` >= 3, or all branches pruned:
    - If job mode, or plateau/all-pruned in any mode: write dissolution report to `syndicate/reports/final.md`, set `phase` to `"dissolved"`.
    - If venture mode convergence: set `phase` to `"discovery"` and set `last_shipped_gen`. No report yet (discovery hasn't run).

## If phase is "discovery"

Run the discovery phase following the procedure in loop.md:

1. Read the shipped deliverable (`attempts/<last_shipped_gen>/`).
2. Read `syndicate/venture.jsonl` if it exists.
3. Identify 3-5 candidate improvements.
4. Pick the highest-value one. If nothing is worth improving, write dissolution report to `syndicate/reports/final.md`, set `phase` to `"dissolved"` in state.json, git commit, and exit.
5. Rewrite `criteria.md` for the new focus.
6. Append to `meta-notes.md` with `--- Round N ---` separator.
7. Append to `venture.jsonl`.
8. Distill `meta-notes.md` if it's getting long.
9. Update `state.json`: increment `current_round`, set `phase` to `"evolving"`, reset `convergence_streak` to 0.
10. Write round report to `syndicate/reports/round-N.md` following the Round Report Format in loop.md.
11. Git commit: `git add -A && git commit -m "round-<N>: discovery - <focus>"`.

## Rules

- Execute exactly ONE step (one generation or one discovery phase), then exit.
- Follow all procedures in SKILL.md and loop.md: model selection, coherence firewall, parent selection, token efficiency.
- The coherence agent always runs on sonnet. Start the task agent on opus. Downgrade to sonnet if prior meta-notes show evidence the task is simple enough.
- Never modify `agents/coherence.md` or `agents/task.md` (these are fixed, bundled with the skill).
- If any subagent invocation fails, log the error in meta-notes, set the generation as a failed attempt with score 0, and proceed with coherence check.
- Write round reports to `syndicate/reports/round-N.md` and dissolution reports to `syndicate/reports/final.md` as specified in the loop reference.
```

---

### Task 4: Create the cron shell wrapper

**Files:**
- Create: `skills/syndicate/cron-runner.sh`

**Context:** Shell script invoked by crontab. Handles locking (prevents overlapping runs), phase gating (skips if paused/dissolved), and invokes Claude with the runner prompt. The project root is passed as an argument.

- [ ] **Step 1: Create cron-runner.sh**

Create `skills/syndicate/cron-runner.sh`:

```bash
#!/bin/bash
set -euo pipefail

PROJECT_DIR="${1:?Usage: cron-runner.sh <project-root>}"
SYNDICATE_DIR="$PROJECT_DIR/syndicate"
STATE_FILE="$SYNDICATE_DIR/state.json"
LOCK_FILE="$SYNDICATE_DIR/.cron.lock"
SKILL_DIR="$PROJECT_DIR/skills/syndicate"
LOG_FILE="$SYNDICATE_DIR/cron.log"

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" >> "$LOG_FILE"; }

# Verify state file exists
if [ ! -f "$STATE_FILE" ]; then
  log "No state.json found. Exiting."
  exit 0
fi

# Check cron_enabled
CRON_ENABLED=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('cron_enabled', False))")
if [ "$CRON_ENABLED" != "True" ]; then
  exit 0
fi

# Check phase
PHASE=$(python3 -c "import json; print(json.load(open('$STATE_FILE'))['phase'])")
if [ "$PHASE" = "dissolved" ] || [ "$PHASE" = "paused" ]; then
  exit 0
fi

# Lock: prevent overlapping runs
if [ -f "$LOCK_FILE" ]; then
  LOCK_AGE=$(( $(date +%s) - $(stat -c %Y "$LOCK_FILE" 2>/dev/null || stat -f %m "$LOCK_FILE") ))
  if [ "$LOCK_AGE" -lt 3600 ]; then
    log "Lock held (age: ${LOCK_AGE}s). Skipping."
    exit 0
  fi
  log "Stale lock (age: ${LOCK_AGE}s). Removing."
  rm -f "$LOCK_FILE"
fi

cleanup() { rm -f "$LOCK_FILE"; }
trap cleanup EXIT
echo $$ > "$LOCK_FILE"

log "Starting cron run. Phase: $PHASE"

# Run one step
RUN_MARKER=$(mktemp)
cd "$PROJECT_DIR"
RUNNER_PROMPT=$(cat "$SKILL_DIR/agents/cron-runner.md")

CLAUDECODE= claude -p "$RUNNER_PROMPT" \
  --model sonnet \
  --allowedTools "Bash,Read,Write,Edit,Glob,Grep" \
  >> "$LOG_FILE" 2>&1

EXIT_CODE=$?

# Check for new reports and notify
NOTIFY_CMD=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('notify') or '')")
if [ -n "$NOTIFY_CMD" ]; then
  for REPORT in $(find "$SYNDICATE_DIR/reports" -name "*.md" -newer "$RUN_MARKER" 2>/dev/null); do
    cat "$REPORT" | eval "$NOTIFY_CMD"
    log "Notification sent for: $REPORT"
  done
fi
rm -f "$RUN_MARKER"

log "Cron run complete. Exit code: $EXIT_CODE"
```

- [ ] **Step 2: Make it executable**

```bash
chmod +x skills/syndicate/cron-runner.sh
```

---

### Task 5: Create the cron reference documentation

**Files:**
- Create: `skills/syndicate/references/cron.md`

**Context:** Reference doc for setting up and operating cron-based venture mode. Covers setup, configuration, monitoring, and troubleshooting.

- [ ] **Step 1: Create cron.md**

Create `skills/syndicate/references/cron.md`:

```markdown
# Cron Reference

How to run venture mode autonomously across sessions.

## How It Works

A cron job fires at a configurable interval. Each tick:
1. Checks `state.json` for phase and `cron_enabled`
2. Acquires a lock file (`.cron.lock`) to prevent overlapping runs
3. Invokes Claude with the cron runner prompt to execute one generation or one discovery phase
4. Updates `state.json` and releases the lock

The venture's own convergence logic decides when to stop. No predefined generation count.

## Setup

### 1. Start the venture interactively

Bootstrap the syndicate and run at least generation 1 interactively. This ensures `goal.md`, `criteria.md`, and `state.json` are properly initialized.

### 2. Enable cron in state.json

Set two fields in `syndicate/state.json`:
- `"mode": "venture"`
- `"cron_enabled": true`

### 3. Add the crontab entry

```bash
# Run every 15 minutes
*/15 * * * * /path/to/project/skills/syndicate/cron-runner.sh /path/to/project

# Run every hour
0 * * * * /path/to/project/skills/syndicate/cron-runner.sh /path/to/project
```

Adjust the interval based on how fast you want generations to proceed. Each tick runs one generation, so the interval is the minimum time between generations.

## Pausing and Stopping

Multiple mechanisms, pick whichever fits:

| Method | How | Effect |
|--------|-----|--------|
| Pause | Set `"phase": "paused"` in state.json | Cron ticks exit immediately. Resume by setting phase back to `"evolving"` or `"discovery"` |
| Disable cron | Set `"cron_enabled": false` in state.json | Same as pause, but phase is preserved |
| Remove crontab | `crontab -e` and delete the line | No more ticks. State is preserved for interactive resumption |
| Dissolve | Set `"phase": "dissolved"` in state.json | Permanent stop. Venture is done |

## Monitoring

Cron output is logged to `syndicate/cron.log`. Check progress:

```bash
# Recent activity
tail -50 syndicate/cron.log

# Current state
cat syndicate/state.json

# Score trajectory
tail -10 syndicate/metrics/scores.jsonl

# Coherence decisions
tail -10 syndicate/metrics/coherence-log.jsonl
```

## Lock File

`.cron.lock` prevents overlapping runs. If a run crashes without cleanup:
- Locks older than 1 hour are automatically treated as stale and removed
- To manually clear: `rm syndicate/.cron.lock`

## Resuming Interactively

You can always resume a venture interactively, even if cron is configured. The state.json is the shared source of truth. Either disable cron first (`"cron_enabled": false`) or remove the crontab entry to avoid conflicts.

## Limitations

- Each cron tick runs one generation. Multi-generation bursts require shorter intervals.
- The cron runner uses sonnet by default. The runner may upgrade the task agent model based on meta-notes evidence, following the same model selection rules as interactive mode.
- Cron output is less interactive. Check `cron.log` and metrics files for progress.

## Notifications

The syndicate can notify the user when it ships a round or dissolves. Configure the `notify` field in `state.json` with a shell command that accepts report text on stdin:

```json
"notify": "mail -s 'Syndicate Report' user@example.com"
```

Examples:
- Email: `"notify": "mail -s 'Syndicate Report' user@example.com"`
- Slack webhook: `"notify": "curl -s -X POST -H 'Content-type: application/json' -d @- https://hooks.slack.com/..."`
- No notification: `"notify": null` (default)

Reports are always written to `syndicate/reports/` regardless of notification config. Notifications are a convenience, not the canonical record.
```

---

### Task 6: Add cron section to SKILL.md

**Files:**
- Modify: `skills/syndicate/SKILL.md`

**Context:** Add a short section after Venture Mode explaining that ventures can run autonomously via cron. Keep it minimal and point to the reference doc.

- [ ] **Step 1: Add Cron section after Venture Mode**

After the Venture Mode section (line 82, `For discovery procedure and round transition mechanics, read references/loop.md.`), add:

```markdown

## Cron (Autonomous Venture Mode)

Ventures can run autonomously across sessions. A cron job fires periodically, runs one generation (or discovery phase), and exits. The venture's own convergence logic decides when to stop.

To enable: complete the scope of work (generation 0) and run at least generation 1 interactively. Then set `cron_enabled: true` and `mode: "venture"` in `state.json`, and add a crontab entry pointing to `cron-runner.sh`. To pause, set `phase: "paused"` in `state.json` or set `cron_enabled: false`.

For setup and operation details, read `references/cron.md`.
```

---

### Task 7: Update CLAUDE.md with cron information

**Files:**
- Modify: `CLAUDE.md`

**Context:** CLAUDE.md provides guidance to Claude Code when working in this repo. Add a brief mention of cron support.

- [ ] **Step 1: Add cron to architecture section**

In the "Architecture: Three-Tier Governance" section, after the bullet about the coherence agent (line 17), add:

```markdown
- **Cron runner** (optional, via `cron-runner.sh`): enables ventures to run autonomously across sessions. Each cron tick invokes `claude -p` with a focused runner prompt to execute one generation or discovery phase. State tracked in `syndicate/state.json`.
```

- [ ] **Step 2: Add cron files to Plugin Structure**

In the "Plugin Structure" section, after the line about templates (line 26), add:

```markdown
- `skills/syndicate/agents/cron-runner.md`: Focused prompt for headless single-step execution (one generation or discovery phase per invocation)
- `skills/syndicate/cron-runner.sh`: Shell wrapper for crontab (handles locking, phase gating, invokes Claude)
- `skills/syndicate/references/cron.md`: Setup and operation guide for autonomous venture mode
```

- [ ] **Step 3: Add state.json to Key Conventions**

After the line about each generation getting its own git branch (line 34), add:

```markdown
- `state.json` in the syndicate root tracks phase, generation, round, and convergence/flag streaks. Updated after every generation and phase transition. Shared between interactive and cron execution.
```

---

### Verification

After all tasks:

1. Verify `skills/syndicate/templates/state.json` exists with correct defaults
2. Verify `skills/syndicate/agents/cron-runner.md` exists and is self-contained
3. Verify `skills/syndicate/cron-runner.sh` exists and is executable
4. Verify `skills/syndicate/references/cron.md` exists with setup instructions
5. Verify `skills/syndicate/SKILL.md` has a Cron section after Venture Mode
6. Verify `skills/syndicate/references/loop.md` has State Tracking section with update rules
7. Verify `CLAUDE.md` mentions cron runner, state.json, and new files
8. Verify the project structure tree in loop.md includes state.json
