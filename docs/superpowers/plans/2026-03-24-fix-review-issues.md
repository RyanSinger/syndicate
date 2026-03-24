# Fix Review Issues Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix 13 issues found during codebase review: procedural gaps, documentation drift, and em dash removal across all markdown files.

**Architecture:** All changes are to markdown files. No traditional code, no tests. Each task targets a file cluster, combining structural fixes with em dash removal for that cluster. The spec is at `docs/superpowers/specs/2026-03-24-fix-review-issues-design.md`.

**Tech Stack:** Markdown, JSONL

---

### Task 1: Fix SKILL.md (issues 3, 5, 6, 8, 11, 13 + em dashes)

**Files:**
- Modify: `skills/syndicate/SKILL.md`

**Context:** SKILL.md has 28 em dashes and 6 structural issues. Read the full file before starting. The spec is at `docs/superpowers/specs/2026-03-24-fix-review-issues-design.md`.

- [ ] **Step 1: Fix bootstrap procedure (issue 3)**

In the Setup section (line 14), change:

```
If `syndicate/` doesn't exist in the project root, bootstrap it by copying this skill's `templates/` directory there and initializing a git repo. If it exists, cd into it and pick up where you left off.
```

to:

```
If `syndicate/` doesn't exist in the project root, bootstrap it by copying this skill's `templates/` directory there, initializing a git repo, creating an initial commit, and tagging it `seed`. If it exists, cd into it and pick up where you left off.
```

- [ ] **Step 2: Add score scale (issue 6)**

In the Generation 1 section (line 18), the sentence reads: `These are hypotheses, not specs.` Insert before that sentence: "Score each criterion on a 1 to 5 scale (1 = not met, 5 = fully met)." The result:

```
...3 to 7 concrete criteria in `criteria.md`. Score each criterion on a 1 to 5 scale (1 = not met, 5 = fully met). These are hypotheses, not specs.
```

- [ ] **Step 3: Add gen-1 coherence skip (issue 8)**

At the end of the Generation 1 section (after line 20), add: "Skip the coherence check for generation 1. There is no trajectory to evaluate yet."

- [ ] **Step 4: Add flag behavior (issue 5)**

After the coherence check step (line 28), expand it. The current text:

```
5. **Coherence check** — A separate agent reviews your trajectory (scores and complexity only, never your code) and decides: continue, flag, or prune.
```

Replace with (also removing the em dash):

```
5. **Coherence check.** A separate agent reviews your trajectory (scores and complexity only, never your code) and decides: continue, flag, or prune. On `flag`, you must change your approach for the next generation: different parent, revised skill, or model change. Each `flag` increments the plateau counter; `continue` or `prune` resets it.
```

- [ ] **Step 5: Fix convergence stopping condition (issue 6)**

Change line 61 from:

```
- **Converged** — criteria near max scores for 2+ generations. Ship the best attempt.
```

to:

```
- **Converged:** average score 4.5 or above for 2+ generations. Ship the best attempt.
```

- [ ] **Step 6: Add venture.jsonl to What's Fixed (issues 11, 13)**

After line 57 (`- `metrics/` — append-only record`), add:

```
- `venture.jsonl` (venture mode only, distilled periodically like meta-notes. Git preserves full history)
```

Also remove the em dash from the metrics line, changing it to:

```
- `metrics/`: append-only record
```

- [ ] **Step 7: Remove all remaining em dashes from SKILL.md**

Replace every remaining ` — ` using these exact substitutions. Steps 4, 5, and 6 already handled some. For the rest:

**Frontmatter description (line 3):** Replace `Give it a goal — build an app, write a contract, design a system — and it stands up` with `Give it a goal (build an app, write a contract, design a system) and it stands up`

**Line 8:** Replace `You spin up an organization to do a job — or run a venture.` with `You spin up an organization to do a job or run a venture.` Replace `You stand up the syndicate — workers, management, oversight — attempt the work` with `You stand up the syndicate (workers, management, oversight), attempt the work`

**Line 18:** Replace `what "good" looks like — 3 to 7` with `what "good" looks like: 3 to 7`

**Line 20:** Replace `score yourself honestly — and ask` with `score yourself honestly, and ask`

**Lines 24-29 (loop steps):** Replace ` — ` after each bold label with a period and space. E.g. `**Diagnose** — What's` becomes `**Diagnose.** What's`. Apply to all six steps (1-6). Note: step 5 was already fixed in Step 4.

**Line 35:** Replace `It never sees your code, skills, or prompts — only fitness trajectories` with `It never sees your code, skills, or prompts. Only fitness trajectories`. Replace `Its instructions (`agents/coherence.md`) are fixed and cannot be modified. This separation is the whole point.` stays as-is (no em dash).

**Lines 45-51 (What Evolves):** Replace ` — ` after each backtick item with a colon. E.g. `` `skills/` — techniques `` becomes `` `skills/`: techniques ``. Apply to all list items.

**Line 50:** Replace `These are living documents — revise them` with `These are living documents. Revise them`

**Lines 62-63 (remaining stopping conditions):** Replace `**All branches pruned** — no viable` with `**All branches pruned:** no viable`. Replace `**Sustained plateau** — flagged` with `**Sustained plateau:** flagged`.

**Line 73:** Replace `default to job — the user` with `default to job. The user`

**Line 77:** Replace `There is no token budget — the syndicate` with `There is no token budget. The syndicate`

**Line 85:** Replace `Revise honestly — but don't` with `Revise honestly, but don't`

- [ ] **Step 8: Verify no em dashes remain**

Search the file for `—` and confirm zero matches.

- [ ] **Step 9: Commit**

```bash
git add skills/syndicate/SKILL.md
git commit -m "Fix SKILL.md: add flag behavior, score scale, bootstrap tag, gen-1 skip, venture.jsonl, remove em dashes"
```

### Task 2: Fix loop.md (issues 2, 4, 7, 9, 13 + em dashes)

**Files:**
- Modify: `skills/syndicate/references/loop.md`

**Context:** loop.md has 20 em dashes and 5 structural issues. Read the full file before starting. The spec is at `docs/superpowers/specs/2026-03-24-fix-review-issues-design.md`.

- [ ] **Step 1: Fix skills double-inclusion (issue 4)**

Change line 17 from:

```
<concatenated contents of all files in skills/ and skills/domain/>
```

to:

```
<concatenated contents of all files in skills/*.md and skills/domain/*.md>
```

- [ ] **Step 2: Add coherence output note (issue 2)**

After the coherence agent invocation template (after line 75), add:

```
The coherence agent's response omits `generation`. Add the current generation number before appending to `coherence-log.jsonl`.
```

- [ ] **Step 3: Add invalid JSON recovery (issue 7)**

Immediately after the note from step 2, add:

```
If the coherence agent returns invalid JSON, treat it as `flag` with reason "coherence agent returned invalid response" and log that to `coherence-log.jsonl`.
```

- [ ] **Step 4: Add flag handling cross-reference**

After the invalid JSON recovery note, add:

```
For flag handling behavior, see SKILL.md step 5.
```

- [ ] **Step 5: Add complexity.jsonl population instructions (issue 9)**

After the `complexity.jsonl` format block (after line 91), add:

```
Count non-retired entries in `learned-agents/registry.jsonl` for `learned_agent_count`. For `learned_agent_invocations`, count the learned agents invoked during the current generation.
```

- [ ] **Step 6: Add bootstrap commit to git workflow**

In the Git Workflow section (after line 107), add before the branch example:

```
At bootstrap, the initial commit is tagged `seed`. Generation 1 branches from `seed`.
```

- [ ] **Step 7: Add venture.jsonl distillation procedure (issue 13)**

After the `venture.jsonl` format section (after line 267), add a new subsection:

```
### venture.jsonl Distillation

venture.jsonl is not strictly append-only. When the file is consuming too many tokens relative to its value, distill it: compress older rounds into a summary paragraph at the top, keep recent rounds intact. Git preserves the full history for research.
```

- [ ] **Step 8: Update project structure diagram**

In the project structure diagram (line 286), change the comment for `venture.jsonl` from:

```
├── venture.jsonl         # Round history (venture mode only, append-only)
```

to:

```
├── venture.jsonl         # Round history (venture mode only, distilled periodically)
```

- [ ] **Step 9: Remove all em dashes from loop.md**

Replace every remaining ` — ` using these exact substitutions:

**Line 44:** `the model is the ceiling — same principle` becomes `the model is the ceiling. Same principle`

**Line 47:** `**Pre-generation** (after Diagnose, before Attempt) — output feeds` becomes `**Pre-generation** (after Diagnose, before Attempt): output feeds`

**Line 48:** `**Post-generation** (after Attempt, before Score) — output informs` becomes `**Post-generation** (after Attempt, before Score): output informs`

**Line 54:** `Build a limited view first — scores` becomes `Build a limited view first: scores`

**Line 123:** `**Recurrence** — the pattern` becomes `**Recurrence:** the pattern`

**Line 124:** `**Actionability** — it's reusable` becomes `**Actionability:** it's reusable`

**Line 127:** `**Procedure** (takes input, produces output, works independently) → ` stays (no em dash, uses arrow)

**Line 128:** `**Knowledge** (techniques, patterns, domain facts that inform work) → ` stays (no em dash, uses arrow)

**Line 146:** `The actual agent prompt — concise` becomes `The actual agent prompt. Concise`

**Line 162:** `a learned agent promoted at gen-5 may be substantially different by gen-20` stays (no em dash, the ` — ` is actually: `Revise them as understanding deepens — a learned agent`). Replace with `Revise them as understanding deepens. A learned agent`

**Line 166:** `No fixed rules — the coherence agent` becomes `No fixed rules. The coherence agent`

**Line 179:** `Trim to the minimum useful content — every word` becomes `Trim to the minimum useful content. Every word`

**Line 200:** `There is no upstream sync — provenance metadata` becomes `There is no upstream sync. Provenance metadata`

**Line 204:** `it takes input, produces output, and works independently — promote it` becomes `it takes input, produces output, and works independently, promote it`

**Line 208:** `Tracks provenance and lifecycle for all domain skills — both imported` becomes `Tracks provenance and lifecycle for all domain skills, both imported`

**Line 220:** `**Round boundary** (venture mode) — natural pause` becomes `**Round boundary** (venture mode): natural pause`

**Line 221:** `**Too long** — the file is` becomes `**Too long:** the file is`

**Line 233:** `dig into git history — not just` becomes `dig into git history, not just`

**Line 237:** `This is not a subagent call — you do this` becomes `This is not a subagent call. You do this`

**Line 249:** `Discovery should be fast — one deliberate pause` becomes `Discovery should be fast: one deliberate pause`

**Line 257:** ``skills/approach.md`, `prompts/task.md` — adjust if` becomes `` `skills/approach.md`, `prompts/task.md`. Adjust if``

**Line 271:** `criteria changes at a round boundary are larger than mid-round tweaks — scores will drop` becomes `criteria changes at a round boundary are larger than mid-round tweaks. Scores will drop`

- [ ] **Step 10: Verify no em dashes remain**

Search the file for `—` and confirm zero matches.

- [ ] **Step 11: Commit**

```bash
git add skills/syndicate/references/loop.md
git commit -m "Fix loop.md: coherence output note, invalid JSON recovery, skills glob, complexity fields, seed tag, venture distillation, remove em dashes"
```

### Task 3: Fix CLAUDE.md (issue 1)

**Files:**
- Modify: `CLAUDE.md`

**Context:** CLAUDE.md has no em dashes but has one factual error. Read the full file before starting.

- [ ] **Step 1: Fix branches.jsonl location (issue 1)**

Change line 32 from:

```
- All metrics files (`scores.jsonl`, `complexity.jsonl`, `coherence-log.jsonl`, `branches.jsonl`) are append-only JSONL in `syndicate/metrics/`
```

to:

```
- Metrics files (`scores.jsonl`, `complexity.jsonl`, `coherence-log.jsonl`) are append-only JSONL in `syndicate/metrics/`
- Branch records (`branches.jsonl`) are append-only JSONL in `syndicate/archive/`
```

- [ ] **Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "Fix CLAUDE.md: correct branches.jsonl location to archive/"
```

### Task 4: Fix README.md (issue 10 + em dashes)

**Files:**
- Modify: `README.md`

**Context:** README.md has 7 em dashes and is missing mention of learned agents and domain skills. Read the full file before starting.

- [ ] **Step 1: Add learned agents and domain skills to How It Works (issue 10)**

After line 34 (the Coherence agent bullet), add:

```
As the syndicate learns, it promotes recurring patterns into **learned agents** (specialized subagents) and **domain skills** (reusable knowledge imported from plugins or distilled from experience).
```

- [ ] **Step 2: Remove all em dashes from README.md**

Replace every ` — ` using these exact substitutions:

**Line 3:** Replace `Give it a goal — build an app, write a contract, design a system — and it stands up` with `Give it a goal (build an app, write a contract, design a system) and it stands up`

**Line 23:** `**Job** — the syndicate spins up` becomes `**Job:** the syndicate spins up`

**Line 24:** `**Venture** — the syndicate ships` becomes `**Venture:** the syndicate ships`

**Line 32:** `**Meta-agent** (you/Claude) — diagnoses` becomes `**Meta-agent** (you/Claude): diagnoses`

**Line 33:** `**Task agent** (subagent) — produces` becomes `**Task agent** (subagent): produces`

**Line 34:** `**Coherence agent** (subagent, different model) — watches` becomes `**Coherence agent** (subagent, different model): watches`

**Line 36:** Replace `This structural separation — borrowed from TurkoMatic (2011) — is what keeps` with `This structural separation, borrowed from TurkoMatic (2011), is what keeps`

- [ ] **Step 3: Verify no em dashes remain**

Search the file for `—` and confirm zero matches.

- [ ] **Step 4: Commit**

```bash
git add README.md
git commit -m "Fix README.md: add learned agents and domain skills, remove em dashes"
```

### Task 5: Fix plugin.json (issue 10)

**Files:**
- Modify: `.claude-plugin/plugin.json`

- [ ] **Step 1: Update description and version**

Change the description and version:

```json
{
  "name": "syndicate",
  "version": "0.2.0",
  "description": "Spins up a self-governing outfit that iterates on its own work. Give it a goal and it evolves its approach through attempts, self-evaluation, and skill refinement. Supports job mode (converge and ship) and venture mode (ship, discover improvements, repeat). A coherence agent prevents runaway complexity. Learned agents and domain skills accumulate as the syndicate gains experience.",
  "author": {
    "name": "Ryan Singer"
  },
  "license": "MIT",
  "keywords": ["self-improving", "evolution", "governance", "iterative", "agents"]
}
```

- [ ] **Step 2: Commit**

```bash
git add .claude-plugin/plugin.json
git commit -m "Bump to 0.2.0, update description with venture mode and learned agents"
```

### Task 6: Fix remaining files (em dashes only)

**Files:**
- Modify: `skills/syndicate/agents/coherence.md`
- Modify: `skills/syndicate/agents/task.md`
- Modify: `skills/syndicate/references/architecture.md`
- Modify: `skills/syndicate/templates/meta-notes.md`

**Context:** These files have only em dash issues, no structural fixes.

- [ ] **Step 1: Fix coherence.md (3 em dashes)**

Lines 27, 29, 31: replace ` — ` after bold decision labels with colons. E.g.:

`**continue** — Scores improving` becomes `**continue:** Scores improving`

- [ ] **Step 2: Fix task.md (1 em dash)**

Line 5: replace ` — ` with a period or colon.

`Follow the skills closely — they represent` becomes `Follow the skills closely. They represent`

- [ ] **Step 3: Fix architecture.md (5 em dashes)**

**Line 10:** `*derailment* — recursive self-organization` becomes `*derailment*: recursive self-organization`

**Lines 26-29:** Replace ` — ` after each bold label with a colon. E.g. `**TurkoMatic** (2011) — Discovered` becomes `**TurkoMatic** (2011): Discovered`. Apply to all four Lineage entries.

**Line 29 (second em dash):** `The three-tier governance is identical in both — venture mode` becomes `The three-tier governance is identical in both. Venture mode`

- [ ] **Step 4: Fix meta-notes.md (1 em dash)**

Line 3: replace em dash.

`Distill this file at round boundaries or when it gets too long — git preserves` becomes `Distill this file at round boundaries or when it gets too long. Git preserves`

- [ ] **Step 5: Verify no em dashes remain in any repo file**

Search the entire repo for `—`. The only matches should be in `docs/superpowers/specs/2026-03-24-fix-review-issues-design.md` (the spec itself, which quotes original text).

- [ ] **Step 6: Commit**

```bash
git add skills/syndicate/agents/coherence.md skills/syndicate/agents/task.md skills/syndicate/references/architecture.md skills/syndicate/templates/meta-notes.md
git commit -m "Remove em dashes from coherence.md, task.md, architecture.md, meta-notes.md"
```

### Task 7: Final verification

- [ ] **Step 1: Verify all 13 issues are addressed**

Read each modified file and confirm the fix is present:
1. CLAUDE.md: branches.jsonl listed under archive/, not metrics/
2. loop.md: note about adding generation to coherence output
3. SKILL.md: bootstrap tags seed
4. loop.md: skills/*.md glob
5. SKILL.md: flag behavior defined in step 5
6. SKILL.md: 1-5 scale, converged = 4.5+
7. loop.md: invalid JSON recovery
8. SKILL.md: gen-1 coherence skip explicit
9. loop.md: complexity.jsonl population instructions
10. README.md + plugin.json: mention learned agents, venture mode
11. SKILL.md: venture.jsonl in What's Fixed
12. All files: no em dashes (except spec doc)
13. loop.md: venture.jsonl distillation procedure

- [ ] **Step 2: Check cross-file consistency**

Verify that:
- CLAUDE.md's description of metrics vs. archive matches loop.md's project structure diagram
- SKILL.md's What's Fixed matches loop.md's round transition section
- The score scale (1-5) is consistent with the convergence threshold (4.5)
- The flag behavior in SKILL.md references the plateau stopping condition correctly
