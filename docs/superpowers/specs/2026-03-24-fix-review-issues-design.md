# Fix All Code Review Issues

Spec for fixing 12 issues found during full codebase review. Approach B: fix each issue, rewriting sections where multiple issues cluster rather than patching line by line.

## Section 1: Coherence handling (loop.md, SKILL.md)

Three issues cluster in the coherence section.

### Issue 2: Output format mismatch

The coherence agent's output format (`agents/coherence.md`) omits `generation`, but `coherence-log.jsonl` requires it.

**Fix:** Add a note after the coherence agent invocation template in `loop.md` stating the meta-agent must add `generation` to the response before appending to `coherence-log.jsonl`.

### Issue 5: Flag response has no defined meta-agent behavior

The coherence agent can return `flag` but no instruction tells the meta-agent what to do with it.

**Fix:** Add the full behavior definition to `SKILL.md` under the coherence check step (step 5). In `loop.md`, add a cross-reference note after the coherence invocation section pointing to `SKILL.md` step 5 for flag handling. The canonical rule lives in `SKILL.md` only. Defined behavior: on `flag`, the meta-agent must change its approach for the next generation (different parent, revised skill, or model change). Each `flag` increments the plateau counter; `continue` or `prune` resets it. The existing "Sustained plateau" stopping condition triggers at 3+ consecutive flags.

### Issue 7: No recovery for invalid coherence JSON

**Fix:** Add one line to the coherence invocation section in `loop.md`: if the coherence agent returns invalid JSON, treat it as `flag` with reason "coherence agent returned invalid response" and log that to `coherence-log.jsonl`.

## Section 2: Stopping conditions and scoring (SKILL.md)

### Issue 6: Score scale undefined

**Fix:** Add one sentence to the Generation 1 section where criteria are first created: "Score each criterion on a 1 to 5 scale (1 = not met, 5 = fully met)." Clarify the convergence stopping condition: "Converged: average score 4.5 or above for 2+ generations."

### Issue 8: Gen-1 omits coherence check

**Fix:** Make the omission explicit. Add one sentence at the end of Generation 1: "Skip the coherence check for generation 1. There is no trajectory to evaluate yet."

## Section 3: Bootstrap and git workflow (SKILL.md, loop.md)

### Issue 3: Seed branch never created

**Fix:** Add to the bootstrap procedure in `SKILL.md`: after "initializing a git repo," add "create an initial commit and tag it `seed`." Update the `loop.md` git workflow section to show the bootstrap commit.

### Issue 4: Skills double-inclusion in task agent prompt

`loop.md` says to concatenate "all files in skills/ and skills/domain/" but `skills/domain/` is a subdirectory of `skills/`.

**Fix:** Change to "all files in skills/*.md and skills/domain/*.md" so the two globs are non-overlapping.

## Section 4: Complexity metrics gap (loop.md)

### Issue 9: No instruction for populating learned-agent fields

**Fix:** Add a note after the `complexity.jsonl` format definition in `loop.md`: "Count non-retired entries in `learned-agents/registry.jsonl` for `learned_agent_count`. For `learned_agent_invocations`, count the learned agents invoked during the current generation."

## Section 5: Documentation gaps (CLAUDE.md, plugin.json, README.md, SKILL.md)

### Issue 1: CLAUDE.md says branches.jsonl is in metrics/

**Fix:** Separate metrics files from archive files in CLAUDE.md. List `scores.jsonl`, `complexity.jsonl`, `coherence-log.jsonl` as metrics. List `branches.jsonl` as archive.

### Issue 10: plugin.json and README missing features

**Fix:**
- Update `plugin.json` description to mention venture mode and learned agents. Bump version to `0.2.0`.
- Update `README.md` "How It Works" to briefly mention learned agents and domain skills.

### Issue 11: SKILL.md missing venture.jsonl

**Fix:** Add `venture.jsonl` to the "What's Fixed" section in `SKILL.md` as a new line: `venture.jsonl` (venture mode only, append-only round history). Place it after the `metrics/` line to group it with other append-only items.

### Issue 13: venture.jsonl has no distillation procedure

A long-running venture (e.g., operating a SaaS over months) could accumulate hundreds or thousands of rounds. `venture.jsonl` is read during discovery to review past round focus, and dumping the full file into context at scale wastes tokens and risks hitting context limits.

**Fix:** Add a distillation procedure for `venture.jsonl` in `loop.md`, modeled on the existing `meta-notes.md` distillation. Keep the last ~10 rounds intact. Compress older rounds into a summary paragraph at the top of the file. Git preserves the full history for research. Trigger distillation at the same points as meta-notes: when the file is consuming too many tokens relative to its value.

Also update `SKILL.md`'s "What's Fixed" description to note that `venture.jsonl` is distilled periodically (not strictly append-only). This changes the fix from Issue 11: instead of calling it "append-only," describe it as "distilled periodically, like meta-notes. Git preserves full history."

## Section 6: Em dash removal (all .md files)

**Fix:** Replace every ` — ` (em dash as separator) across all markdown files with rewritten prose using colons, commas, periods, or restructured sentences.

Preserved as-is: `--- Distilled through gen-N ---` and `--- Round N ---` markers (format delimiters, not punctuation).

**Files affected (confirmed via grep):** `SKILL.md`, `loop.md`, `architecture.md`, `coherence.md`, `task.md`, `README.md`, `meta-notes.md`. `CLAUDE.md` has no em dashes.
