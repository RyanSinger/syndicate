# Venture Mode Communication Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add user communication to the syndicate: scope of work before gen 1, round boundary reports, dissolution reports, and cron notifications. Also revise the existing cron plan to incorporate these.

**Architecture:** All changes are to markdown files (skill definitions, references, templates) and one shell script revision. The communication model is built into the existing loop, not a separate system. Reports are written to `syndicate/reports/`. Notifications in cron mode are dispatched by the shell wrapper via a pluggable `notify` command in state.json.

**Tech Stack:** Markdown, JSONL, Bash

---

### Task 1: Add Scope of Work phase to SKILL.md

**Files:**
- Modify: `skills/syndicate/SKILL.md`

**Context:** The spec replaces the current "Generation 1: Start by Doing" with two phases: "Generation 0: Scope of Work" (brainstorming conversation with the user) and "Generation 1: Start by Doing" (first attempt using user-approved criteria). Read the full file before starting. The spec is at `docs/superpowers/specs/2026-03-24-venture-communication-design.md`.

- [ ] **Step 1: Replace Generation 1 section with Generation 0 + Generation 1**

Replace the current "Generation 1: Start by Doing" section (lines 16-22) with:

```markdown
## Generation 0: Scope of Work

Before building anything, have a conversation with the user to establish a shared understanding of the goal:

1. Restate your understanding of the goal. Ask if anything is missing.
2. Ask clarifying questions, one at a time, to understand constraints, priorities, and what "good" means.
3. Propose initial criteria (3 to 7) and explain each one.
4. User approves the scope. Write `goal.md` and `criteria.md`.

The criteria are still hypotheses. They will evolve as the syndicate learns. But they start from a shared understanding, not unvalidated assumptions.

## Generation 1: Start by Doing

Make your first attempt. Produce the real deliverable. Then score yourself honestly, and ask whether building this revealed that the criteria themselves are wrong. Revise them if so. This isn't failure, it's learning.

Skip the coherence check for generation 1. There is no trajectory to evaluate yet.
```

- [ ] **Step 2: Add report writing to Stopping Conditions**

After line 68 ("On stopping, copy the best attempt to the project root and report what the syndicate learned."), replace that line and the job/venture mode lines (68-72) with:

```markdown
On stopping, copy the best attempt to the project root.

**Job mode:** Write a dissolution report to `reports/final.md` summarizing what was accomplished and what was learned. The syndicate dissolves.

**Venture mode:** The syndicate enters a discovery phase. After discovery completes, write a round report to `reports/round-N.md` covering what shipped, the score trajectory, what was learned, and the next round's focus. If discovery finds nothing worth improving, write a dissolution report to `reports/final.md` instead. In interactive sessions, also present the report directly to the user.
```

- [ ] **Step 3: Add reports/ to What's Fixed**

After line 60 (the venture.jsonl entry), add:

```markdown
- `reports/`: round boundary reports and dissolution report
```

- [ ] **Step 4: Commit**

```bash
git add skills/syndicate/SKILL.md
git commit -m "Add scope of work phase and round/dissolution reports to SKILL.md"
```

### Task 2: Add Round Reports and Dissolution Reports to loop.md

**Files:**
- Modify: `skills/syndicate/references/loop.md`

**Context:** Add report format specifications, report writing steps in the discovery phase, and update the project structure. Read the full file before starting. The spec is at `docs/superpowers/specs/2026-03-24-venture-communication-design.md`.

- [ ] **Step 1: Add Round Reports section**

After the "Coherence Agent at Round Boundaries" section (after line 289), add:

```markdown
## Reports

The syndicate writes reports at round boundaries and on dissolution. All reports go in `reports/`.

### Round Report Format

Written after the discovery phase completes (step 9), before resuming the evolution loop. File: `reports/round-N.md`.

```markdown
# Round N Report

## What Shipped
<One sentence describing the deliverable. Path to best attempt.>

## Score Trajectory
<Starting and ending average scores for the round. Number of generations. Notable events: model upgrades, criteria revisions, coherence flags.>

## What Was Learned
<Two to three sentences distilled from meta-notes. What worked, what didn't.>

## Next Round Focus
<What the discovery phase identified as the highest-value improvement, and why. What was considered and rejected.>
```

In interactive sessions, also present the report directly to the user.

### Dissolution Report Format

Written whenever the syndicate dissolves, regardless of mode or stopping condition. File: `reports/final.md`.

```markdown
# Dissolution Report

## Outcome
<One sentence: what was accomplished.>

## Stopping Reason
<Why the syndicate stopped: convergence (job), nothing worth improving (venture), sustained plateau, or all branches pruned.>

## Rounds Summary
<For ventures: one line per round from venture.jsonl. For jobs: single round summary.>

## What Was Learned
<Key learnings distilled from meta-notes. What approaches worked, what failed, what surprised.>

## Deliverable
<Path to the best attempt in the project root.>
```

```

### Dissolution Trigger Points

Write the dissolution report wherever `phase` is set to `"dissolved"`:
- Job mode convergence (round converged, no discovery phase)
- Venture mode exhaustion (discovery found nothing worth improving)
- Sustained plateau (flagged 3+ consecutive times, any mode)
- All branches pruned (no viable parents, any mode)

- [ ] **Step 2: Add report writing step to Discovery Phase**

In the Discovery Phase section, after step 8 ("Append to `venture.jsonl`"), add a new step 9 and renumber the current step 9:

Current step 8 (line 256): `8. Append to `venture.jsonl` (create it on the first round boundary).`
Current step 9 (line 257): `9. Resume the evolution loop. The next generation continues the global count.`

Change to:

```
8. Append to `venture.jsonl` (create it on the first round boundary).
9. Write a round report to `reports/round-N.md` following the Round Report Format above. In interactive sessions, also present it to the user.
10. Resume the evolution loop. The next generation continues the global count.
```

- [ ] **Step 3: Add dissolution report to discovery dissolution path**

The line "Discovery should be fast: one deliberate pause, not a sub-loop. If you can't find anything worth improving, the venture is done. Dissolve." (line 259) needs a report step. Change to:

```
Discovery should be fast: one deliberate pause, not a sub-loop. If you can't find anything worth improving, write a dissolution report to `reports/final.md` and dissolve.
```

- [ ] **Step 4: Add reports/ to project structure**

In the Project Structure tree, after the `archive/` entry (line 315-316), add:

```
├── reports/
│   ├── round-N.md          # Round boundary reports
│   └── final.md            # Dissolution report
```

- [ ] **Step 5: Commit**

```bash
git add skills/syndicate/references/loop.md
git commit -m "Add round reports, dissolution reports, and report writing steps to loop.md"
```

### Task 3: Add reports/ template directory

**Files:**
- Create: `skills/syndicate/templates/reports/.gitkeep`

- [ ] **Step 1: Create the directory**

```bash
mkdir -p skills/syndicate/templates/reports
touch skills/syndicate/templates/reports/.gitkeep
```

- [ ] **Step 2: Commit**

```bash
git add skills/syndicate/templates/reports/.gitkeep
git commit -m "Add reports/ template directory"
```

### Task 4: Update CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

**Context:** CLAUDE.md needs to reflect the new communication model. Read the full file before starting.

- [ ] **Step 1: Add communication model to architecture section**

After the coherence agent bullet (line 17, ending with "Its prompt (`agents/coherence.md`) is fixed and must not be modified"), add:

```markdown

The syndicate communicates with the user at defined moments: scope of work before gen 1, round boundary reports after each discovery phase, and a dissolution report on stopping. Mid-round, it runs autonomously.
```

- [ ] **Step 2: Add reports to What Evolves vs. What's Fixed**

After the Fixed line (line 43, "Fixed: `syndicate/goal.md` (set once), `skills/syndicate/agents/` (bundled with plugin), `syndicate/metrics/` (append-only)"), add `syndicate/reports/` to the list. Change the line to:

```
Fixed: `syndicate/goal.md` (set once), `skills/syndicate/agents/` (bundled with plugin), `syndicate/metrics/` (append-only), `syndicate/reports/` (written at round boundaries and dissolution)
```

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "Add communication model and reports to CLAUDE.md"
```

### Task 5: Revise the cron plan

**Files:**
- Modify: `docs/superpowers/plans/2026-03-24-venture-cron-jobs.md`

**Context:** The existing cron plan was written before the communication design. It needs revisions to incorporate scope of work enforcement, round/dissolution reports, and notifications. Read both the cron plan and the communication spec before starting. The spec is at `docs/superpowers/specs/2026-03-24-venture-communication-design.md`.

- [ ] **Step 1: Add notify field to state.json template (Task 1 of cron plan)**

In the state.json template (lines 24-36), add after `"cron_enabled": false`:

```json
  "notify": null
```

Add to the field definitions after line 47:

```
- `notify`: shell command for notifications (receives report text on stdin), or null for no notification. Default null.
```

- [ ] **Step 2: Add startup check to cron-runner.md (Task 3 of cron plan)**

In the cron-runner.md Startup section (line 127), after the check for `paused` or `dissolved`, add a new step:

```
2. If `current_generation` < 1, log "Scope of work not completed. Run gen 1 interactively first." and exit with no changes.
```

Renumber subsequent steps.

- [ ] **Step 3: Add reports/ awareness to cron-runner.md**

In the cron-runner.md Rules section (line 165), add:

```
- Write round reports to `syndicate/reports/round-N.md` and dissolution reports to `syndicate/reports/final.md` as specified in the loop reference.
```

- [ ] **Step 4: Add report writing to cron-runner.md evolving phase**

In the "If phase is evolving" section, replace step 14 (line 148) with:

```
14. **Check stopping conditions**: if `convergence_streak` >= 2, or `flag_streak` >= 3, or all branches pruned:
    - If job mode, or plateau/all-pruned in any mode: write dissolution report to `syndicate/reports/final.md`, set `phase` to `"dissolved"`.
    - If venture mode convergence: set `phase` to `"discovery"` and set `last_shipped_gen`. No report yet (discovery hasn't run).
```

- [ ] **Step 5: Add report writing to cron-runner.md discovery phase**

In the "If phase is discovery" section, after step 9 (line 162, updating state.json), add:

```
10. Write round report to `syndicate/reports/round-N.md` following the Round Report Format in loop.md.
```

Replace step 4's dissolution path (line 157, "set `phase` to `"dissolved"` in state.json, git commit, and exit") with:

```
4. Pick the highest-value one. If nothing is worth improving, write dissolution report to `syndicate/reports/final.md`, set `phase` to `"dissolved"` in state.json, git commit, and exit.
```

Renumber step 10 to 11.

- [ ] **Step 6: Add notification to cron-runner.sh (Task 4 of cron plan)**

In the cron-runner.sh script, before the `cd "$PROJECT_DIR"` line (line 236), add:

```bash
RUN_MARKER=$(mktemp)
```

After the Claude invocation block (after line 245), before the final log line, add:

```bash
# Check for new reports and notify
NOTIFY_CMD=$(python3 -c "import json; print(json.load(open('$STATE_FILE')).get('notify') or '')")
if [ -n "$NOTIFY_CMD" ]; then
  for REPORT in $(find "$SYNDICATE_DIR/reports" -name "*.md" -newer "$RUN_MARKER" 2>/dev/null); do
    cat "$REPORT" | eval "$NOTIFY_CMD"
    log "Notification sent for: $REPORT"
  done
fi
rm -f "$RUN_MARKER"
```

- [ ] **Step 7: Add Notifications section to cron.md (Task 5 of cron plan)**

In the cron.md reference doc, after the Limitations section (line 349), add:

```markdown

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

- [ ] **Step 8: Update cron section in SKILL.md**

The cron plan's Task 6 adds a Cron section to SKILL.md. The text needs a note about generation 0. In the cron plan's proposed text (line 371), change:

```
To enable: start the venture interactively (at least gen 1), set `cron_enabled: true` and `mode: "venture"` in `state.json`, and add a crontab entry pointing to `cron-runner.sh`.
```

to:

```
To enable: complete the scope of work (generation 0) and run at least generation 1 interactively. Then set `cron_enabled: true` and `mode: "venture"` in `state.json`, and add a crontab entry pointing to `cron-runner.sh`.
```

- [ ] **Step 9: Commit**

```bash
git add docs/superpowers/plans/2026-03-24-venture-cron-jobs.md
git commit -m "Revise cron plan: add notifications, report writing, scope of work enforcement"
```

**Note:** The cron plan's Task 7 also modifies CLAUDE.md (adding cron runner, state.json, and new file references). When implementing the cron plan, those edits must be reconciled with this communication plan's Task 4 edits to the same file. Implement this communication plan first, then the cron plan.

### Task 6: Final verification

- [ ] **Step 1: Verify communication model is complete**

Read each modified file and confirm:
1. SKILL.md: Generation 0 scope of work exists before Generation 1
2. SKILL.md: Stopping conditions section includes report writing for both job and venture modes
3. SKILL.md: reports/ listed in What's Fixed
4. loop.md: Round Report Format section exists with template
5. loop.md: Dissolution Report Format section exists with template and all trigger points listed
6. loop.md: Discovery phase step 9 writes round report
7. loop.md: Discovery dissolution path writes dissolution report
8. loop.md: reports/ in project structure
9. templates/reports/.gitkeep exists
10. CLAUDE.md: mentions communication model and reports/

- [ ] **Step 2: Verify cron plan revisions**

Read the cron plan and confirm:
1. state.json template has `notify` field
2. cron-runner.md has `current_generation < 1` startup check
3. cron-runner.md Rules section mentions reports/ directory
4. cron-runner.md evolving phase writes dissolution report for job mode and plateau/all-pruned
4. cron-runner.md discovery phase writes round report after step 9
5. cron-runner.md discovery phase writes dissolution report if nothing worth improving
6. cron-runner.sh has RUN_MARKER and notification dispatch
7. cron.md has Notifications section
8. SKILL.md cron section mentions scope of work requirement

- [ ] **Step 3: Check cross-file consistency**

Verify:
- The round report format in loop.md matches what SKILL.md describes
- The dissolution trigger points in loop.md match the stopping conditions in SKILL.md
- The cron plan's report writing steps match loop.md's report format sections
- CLAUDE.md's description of reports/ matches what actually exists
