# Venture Mode Communication Design

The user is the syndicate's principal. They provide the tokens and bear the consequences of outcomes. The syndicate has operational autonomy but reports to the user at defined moments. This principle holds whether the session is interactive or running via cron.

## Communication Points

### 1. Scope of Work (before gen 1)

Before building anything, the meta-agent has a conversation with the user:

1. Restate its understanding of the goal. Ask if anything is missing.
2. Ask clarifying questions, one at a time, to understand constraints, priorities, and what "good" means.
3. Propose initial criteria (3 to 7) and explain each one.
4. User approves the scope. The meta-agent writes `goal.md` and `criteria.md`.

This replaces the current "take your best guess" approach in SKILL.md's Generation 1 section. The criteria are still hypotheses that evolve, but they start from a shared understanding rather than the syndicate's unvalidated assumptions.

In cron mode, the scope of work is always done interactively. The cron runner verifies `current_generation >= 1` before proceeding and exits if not. The user must complete the scope of work and run at least gen 1 before enabling cron.

**Changes to SKILL.md:** Replace "Generation 1: Start by Doing" with two phases: "Generation 0: Scope of Work" (the brainstorming conversation) and "Generation 1: Start by Doing" (first attempt, now starting from user-approved criteria).

**Changes to cron-runner.md:** Add a startup check: if `current_generation < 1`, log "Scope of work not completed. Run gen 1 interactively first." and exit.

### 2. Round Boundary Reports (after discovery)

When a round converges and the syndicate completes its discovery phase, it writes a report. The report is written after discovery, not at convergence, because it includes the next round's focus.

The report covers:

- **What shipped:** one sentence describing the deliverable, plus the path to the best attempt.
- **Score trajectory:** starting and ending average scores for the round, number of generations, notable events (model upgrades, criteria revisions, coherence flags).
- **What was learned:** two to three sentences distilled from meta-notes.
- **Next round focus:** what the discovery phase identified as the highest-value improvement, and why. What was considered and rejected. (Omitted if the venture is dissolving because nothing was worth improving.)

The report is written to `syndicate/reports/round-N.md` in all cases. In interactive sessions, the meta-agent also presents it directly in the conversation. In cron mode, a notification points the user to the report.

The syndicate does not block on approval after presenting the report. The default is to keep moving. The user can redirect if the syndicate is drifting from their intent.

**Timing in cron mode:** Convergence is detected at the end of an "evolving" tick, which sets phase to "discovery". The next tick runs discovery, chooses the next focus (or dissolves), writes the round report, and starts the next round. The report is written on the discovery tick, not the convergence tick.

**Changes to SKILL.md:** Add report writing to the round boundary procedure.

**Changes to loop.md:** Add a Round Reports section with the report format and the `reports/` directory. Add `reports/` to the project structure diagram.

### 3. Dissolution Report (on stopping)

When the syndicate dissolves, it writes a final report to `syndicate/reports/final.md` summarizing what it accomplished and what it learned. This applies to all dissolution paths:

- **Job mode convergence:** round converged, deliverable shipped.
- **Venture mode exhaustion:** discovery found nothing worth improving.
- **Sustained plateau:** flagged 3+ consecutive times in any mode.
- **All branches pruned:** no viable parents in any mode.

The dissolution report is written wherever `phase` is set to `"dissolved"`. In the cron runner, this means: in the "evolving" phase when plateau or all-pruned is detected, and in the "discovery" phase when nothing is worth improving. In job mode, the cron runner writes the dissolution report at convergence (job mode never enters discovery).

### 4. No Mid-Round Communication

The syndicate runs autonomously between round boundaries. The user can always check in by asking, but the syndicate does not initiate contact during a round.

## Notification in Cron Mode

When the syndicate runs via cron and hits a round boundary or dissolves, it sends a notification.

**Mechanism:** A `notify` field in `state.json` specifies how to reach the user. The value is a shell command that receives the notification text on stdin. Examples:

- `"notify": "mail -s 'Syndicate Report' user@example.com"` for email
- `"notify": "curl -X POST -d @- https://hooks.slack.com/..."` for Slack
- `"notify": null` for no notification (default). Reports are still written to files.

The cron shell wrapper handles notification dispatch after the cron runner exits, by checking if any report files were created during the run.

**Changes to state.json:** Add `notify` field (default null).

**Changes to cron-runner.sh:** Before the Claude invocation, capture a timestamp. After the invocation, find report files newer than that timestamp. If any exist and `notify` is configured, pipe the report content to the notify command.

## Revisions to the Cron Plan

The existing cron plan (`docs/superpowers/plans/2026-03-24-venture-cron-jobs.md`) needs these revisions:

### state.json

Add field:
- `notify`: shell command for notifications, or null. Default null.

### cron-runner.md (agent prompt)

Add a startup check: if `current_generation < 1`, log a message and exit.

Add to the "evolving" phase, step 14 (after detecting convergence):
- In job mode: write dissolution report to `syndicate/reports/final.md`, set phase to `"dissolved"`.
- In venture mode: set phase to `"discovery"`. No report yet (discovery hasn't run).
- On plateau or all-pruned stopping conditions (any mode): write dissolution report to `syndicate/reports/final.md`, set phase to `"dissolved"`.

Add to the "discovery" phase, after step 9 (after updating state.json for the new round):
- Write round report to `syndicate/reports/round-N.md` following the format in loop.md. This is the right moment because discovery has completed and the next focus is known.

Add to the "discovery" phase, step 4 (if nothing worth improving):
- Write dissolution report to `syndicate/reports/final.md`.

Add explicit awareness of the `syndicate/reports/` directory to the agent prompt.

### cron-runner.sh (shell wrapper)

After the Claude invocation, add a notification step:

Before the Claude invocation, capture a timestamp:

```bash
RUN_MARKER=$(mktemp)
```

After the Claude invocation, check for new reports:

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

### cron.md (reference doc)

Add a Notifications section covering:
- How to configure `notify` in state.json
- Examples for email and Slack
- That reports are always written to files regardless of notification config

### SKILL.md

Add the scope of work phase (Generation 0) before Generation 1. The cron section should note that generation 0 is always interactive.

### loop.md

Add:
- Round Reports section with format specification
- Dissolution Reports section specifying all trigger points (job convergence, venture exhaustion, plateau, all-pruned)
- `reports/` directory in project structure
- Report writing steps: round report at end of discovery phase, dissolution report wherever phase is set to "dissolved"

### templates/

Add `reports/` directory with a `.gitkeep`.
