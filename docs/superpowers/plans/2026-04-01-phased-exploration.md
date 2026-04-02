# Phased Exploration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split the syndicate lifecycle into exploration and convergence phases so it diverges before it converges, producing better results through genuine exploration.

**Architecture:** Two changes to existing markdown skill files (SKILL.md and loop.md). No new files. SKILL.md gets phase rules, ratchet mechanics, transition logic, and updated stopping conditions. loop.md gets updated metrics format and coherence invocation template.

**Tech Stack:** Markdown (skill definitions)

**Spec:** `docs/superpowers/specs/2026-04-01-phased-exploration-design.md`

---

### Task 1: Add Exploration Phase to SKILL.md Gen 1 Section

**Files:**
- Modify: `plugin/skills/run/SKILL.md:35-39`

- [ ] **Step 1: Update the Gen 1 section to establish exploration phase**

Replace the current Gen 1 section (lines 35-39):

```markdown
## Generation 1: Start by Doing

Make your first attempt. Produce the real deliverable. Score each criterion on a 1 to 5 scale (1 = not met, 5 = fully met). Then score yourself honestly, and ask whether building this revealed that the criteria themselves are wrong. Revise them if so. This isn't failure, it's learning.

Skip the coherence check for generation 1. There is no trajectory to evaluate yet.
```

With:

```markdown
## Generation 1: Start by Doing

You are in the **exploration phase**. Convergence is structurally impossible until you transition out.

Make your first attempt. Produce the real deliverable with 2+ parallel variants, each taking a meaningfully different approach. Score each criterion on a 1 to 5 scale (1 = not met, 5 = fully met). Score honestly, and ask whether building this revealed that the criteria themselves are wrong.

After scoring, perform the **criteria ratchet**: do exactly one of (a) add a criterion the best variant doesn't already satisfy at 5, (b) split a vague criterion into sharper ones, or (c) raise the bar on an existing criterion. You may also prune criteria that stop making sense; pruning doesn't substitute for the ratchet. Document ratchet and pruning actions in meta-notes.

Skip the coherence check for generation 1. There is no trajectory to evaluate yet.
```

- [ ] **Step 2: Commit**

```bash
git add plugin/skills/run/SKILL.md
git commit -m "SKILL.md: add exploration phase to Gen 1 section"
```

---

### Task 2: Update "Every Generation After That" Section in SKILL.md

**Files:**
- Modify: `plugin/skills/run/SKILL.md:42-53`

- [ ] **Step 1: Update the generation loop to include phase-aware variant requirements and the ratchet step**

Replace the current section (lines 42-53):

```markdown
## Every Generation After That

1. **Diagnose.** What's weakest in the last attempt? Are the criteria still measuring the right things?
2. **Propose 1 to N changes.** Each targets the diagnosed weakness from a different angle. Decide how many based on confidence: 1 if the path is obvious, 3 to 4 if stuck or exploring early. State what each change is expected to improve and why.
3. **Attempt all in parallel.** Each proposed change gets its own task agent running in a separate git worktree (`isolation: "worktree"`). All run simultaneously as background agents. Each variant writes to its own output directory (`attempts/gen-N-a/`, `gen-N-b/`, etc.).
4. **Score all.** Evaluate each variant honestly against current criteria. Record the winning variant's score in `scores.jsonl`. Record all variants in `branches.jsonl`.
5. **Coherence check on batch.** A separate agent reviews the batch: all variant scores, the spread, complexity growth, and the provisional winner's diff stats. It decides: continue, flag, or prune. On `flag`, you must change your approach. Each `flag` increments the plateau counter; `continue` or `prune` resets it. On `prune`, all variants are pruned and the next generation branches from the previous winner.
6. **Squash-merge best, clean up rest.** Squash-merge the winning variant onto `syndicate/run-<N>` as a single commit: `gen-<G>: <one sentence>`. Mark other variants pruned in `branches.jsonl`. Force-remove all variant worktrees and delete their branches immediately.
7. **Record what you learned.** Write observations in `meta-notes.md`. Note what was tried in parallel, what worked, what didn't. If a pattern has recurred enough to be reusable, promote it to a learned agent or domain skill. Distill meta-notes when they get too long.

The syndicate governs itself. No generation count from the user.

When to go wide (3 to 4 variants): low scores, unclear direction, first few generations, criteria just changed. When to go narrow (1 to 2 variants): scores improving steadily, clear next step, approaching convergence. All variants in a generation use the same model.
```

With:

```markdown
## Every Generation After That

1. **Diagnose.** What's weakest in the last attempt? Are the criteria still measuring the right things?
2. **Propose changes.** During exploration: 2+ variants, each taking a meaningfully different approach. During convergence: 1 to N based on confidence. State what each change is expected to improve and why.
3. **Attempt all in parallel.** Each proposed change gets its own task agent running in a separate git worktree (`isolation: "worktree"`). All run simultaneously as background agents. Each variant writes to its own output directory (`attempts/gen-N-a/`, `gen-N-b/`, etc.).
4. **Score all.** Evaluate each variant honestly against current criteria. Record the winning variant's score in `scores.jsonl` (include `phase` and `ratchet` fields). Record all variants in `branches.jsonl`.
5. **Ratchet (exploration only).** After scoring, perform exactly one of: (a) add a criterion the best variant doesn't already satisfy at 5, (b) split a vague criterion into sharper ones, (c) raise the bar on an existing criterion. You may also prune criteria that stop making sense; pruning doesn't substitute for the ratchet. Document ratchet and pruning actions in meta-notes.
6. **Coherence check on batch.** A separate agent reviews the batch: all variant scores, the spread, complexity growth, and the provisional winner's diff stats. Include the current phase and ratchet action in the coherence prompt. It decides: continue, flag, or prune. On `flag`, you must change your approach. Each `flag` increments the plateau counter; `continue` or `prune` resets it. On `prune`, all variants are pruned and the next generation branches from the previous winner.
7. **Squash-merge best, clean up rest.** Squash-merge the winning variant onto `syndicate/run-<N>` as a single commit: `gen-<G>: <one sentence>`. Mark other variants pruned in `branches.jsonl`. Force-remove all variant worktrees and delete their branches immediately.
8. **Record what you learned.** Write observations in `meta-notes.md`. Note what was tried in parallel, what worked, what didn't. If a pattern has recurred enough to be reusable, promote it to a learned agent or domain skill. Distill meta-notes when they get too long.

The syndicate governs itself. No generation count from the user.

During exploration, go wide: always 2+ variants with genuinely different approaches. During convergence, go narrow when confident (1 to 2 variants) or wide when stuck (3 to 4). All variants in a generation use the same model.
```

- [ ] **Step 2: Commit**

```bash
git add plugin/skills/run/SKILL.md
git commit -m "SKILL.md: phase-aware generation loop with ratchet step"
```

---

### Task 3: Add Phase Transition Section to SKILL.md

**Files:**
- Modify: `plugin/skills/run/SKILL.md` (insert after "Every Generation After That" section, before "The Coherence Firewall")

- [ ] **Step 1: Add the phase transition section**

Insert this new section between "Every Generation After That" and "The Coherence Firewall":

```markdown
## Phase Transition

The syndicate starts in **exploration phase** and must explicitly transition to **convergence phase** before convergence stopping conditions apply.

**Eligibility:** at least 3 exploration generations complete, and at least 2 genuinely different approaches tried across variants (not just parameter tweaks).

**To transition**, write a transition rationale to meta-notes:
- What approaches were explored and how they compared
- Why the current best approach won (with evidence from variant scores)
- What the exploration surfaced that wouldn't have been obvious upfront

Pass the transition rationale summary to the coherence agent in the next invocation. It can flag a thin rationale. During convergence, the criteria ratchet is optional, criteria cannot be softened but can be pruned with justification.
```

- [ ] **Step 2: Commit**

```bash
git add plugin/skills/run/SKILL.md
git commit -m "SKILL.md: add phase transition section"
```

---

### Task 4: Update Stopping Conditions in SKILL.md

**Files:**
- Modify: `plugin/skills/run/SKILL.md:83-88`

- [ ] **Step 1: Replace the stopping conditions section**

Replace the current section (lines 83-88):

```markdown
## Stopping Conditions

- **Converged:** average score 4.5 or above for 2+ generations. Ship the best attempt.
- **All branches pruned:** no viable parents. Report best result.
- **Sustained plateau:** flagged 3+ consecutive times with no promising direction.
```

With:

```markdown
## Stopping Conditions

- **Converged:** average score 4.8 or above for 2+ consecutive generations, and the syndicate is in convergence phase. Cannot trigger during exploration.
- **All branches pruned:** no viable parents. Report best result. Either phase.
- **Sustained plateau:** flagged 3+ consecutive times. Either phase. During exploration, this means variants aren't producing useful diversity. During convergence, refinement has stalled.
```

- [ ] **Step 2: Commit**

```bash
git add plugin/skills/run/SKILL.md
git commit -m "SKILL.md: raise convergence threshold to 4.8, require convergence phase"
```

---

### Task 5: Update Principles in SKILL.md

**Files:**
- Modify: `plugin/skills/run/SKILL.md:105-113`

- [ ] **Step 1: Add exploration principle**

In the Principles section, add this as the second bullet (after "Ship a good deliverable"):

```markdown
- Explore before you converge. Early generations are for discovery, not optimization.
```

- [ ] **Step 2: Commit**

```bash
git add plugin/skills/run/SKILL.md
git commit -m "SKILL.md: add exploration principle"
```

---

### Task 6: Update Venture Mode Round Start in SKILL.md

**Files:**
- Modify: `plugin/skills/run/SKILL.md:97-101` (Venture Mode section)

- [ ] **Step 1: Note that each round starts in exploration phase**

In the Venture Mode section, after "Instead of dissolving, the syndicate then enters a **discovery phase**", add a sentence:

```markdown
Each new round starts back in exploration phase, so the full diverge-then-converge cycle repeats.
```

- [ ] **Step 2: Commit**

```bash
git add plugin/skills/run/SKILL.md
git commit -m "SKILL.md: venture rounds restart in exploration phase"
```

---

### Task 7: Update scores.jsonl Format in loop.md

**Files:**
- Modify: `plugin/skills/run/references/loop.md:104-110`

- [ ] **Step 1: Add phase and ratchet fields to scores.jsonl format**

Replace the current scores.jsonl section (lines 104-110):

```markdown
### scores.jsonl

```jsonl
{"generation": 1, "scores": {"input_validation": 2, "error_messages": 1}, "avg": 1.5, "model": "haiku", "criteria_changed": false, "timestamp": "2026-03-23T14:30:00Z"}
```

Only the winning variant's score is appended per generation step. All variant scores are recorded in `branches.jsonl`. This keeps the coherence agent's score trajectory clean: one entry per generation, not one per variant.
```

With:

```markdown
### scores.jsonl

```jsonl
{"generation": 1, "scores": {"input_validation": 2, "error_messages": 1}, "avg": 1.5, "model": "opus", "criteria_changed": false, "phase": "exploration", "ratchet": "added: error recovery", "timestamp": "2026-03-23T14:30:00Z"}
```

- `phase`: `"exploration"` or `"convergence"`
- `ratchet`: describes the ratchet action taken. Required during exploration, null during convergence if none taken. Include pruning if applicable: `"added: X, pruned: Y (reason)"`.

Only the winning variant's score is appended per generation step. All variant scores are recorded in `branches.jsonl`. This keeps the coherence agent's score trajectory clean: one entry per generation, not one per variant.
```

- [ ] **Step 2: Commit**

```bash
git add plugin/skills/run/references/loop.md
git commit -m "loop.md: add phase and ratchet fields to scores.jsonl"
```

---

### Task 8: Update Coherence Agent Invocation Template in loop.md

**Files:**
- Modify: `plugin/skills/run/references/loop.md:65-90`

- [ ] **Step 1: Add Phase and Ratchet lines to the coherence agent invocation template**

Replace the current coherence agent invocation template (lines 65-90):

```
Agent tool:
  description: "Gen <N>: coherence check (batch)"
  subagent_type: "syndicate:coherence"
  prompt: |
    Generation: <N>
    Branch: <list all variants, marking best, e.g. gen-3-b (best), gen-3-a, gen-3-c>
    Variants tried: <count>

    Scores:
    <each variant with its score and change description>

    Recent score trajectory (winning variants only):
    <last 10 lines of metrics/scores.jsonl>

    Complexity trend:
    <last 10 lines of metrics/complexity.jsonl>

    Git log (last 10):
    <git log --oneline -10>

    Last change (file stats only, provisional winner by score):
    <git diff of highest-scoring branch --stat>

    Respond as JSON only.
```

With:

```
Agent tool:
  description: "Gen <N>: coherence check (batch)"
  subagent_type: "syndicate:coherence"
  prompt: |
    Generation: <N>
    Phase: <exploration (gen N of minimum 3) | convergence | convergence (transitioned at gen N)>
    Branch: <list all variants, marking best, e.g. gen-3-b (best), gen-3-a, gen-3-c>
    Variants tried: <count>
    Ratchet: <ratchet action taken, e.g. "added: error recovery" or "raised: test coverage" or "none (convergence phase)">

    Scores:
    <each variant with its score and change description>

    Recent score trajectory (winning variants only):
    <last 10 lines of metrics/scores.jsonl>

    Complexity trend:
    <last 10 lines of metrics/complexity.jsonl>

    Git log (last 10):
    <git log --oneline -10>

    Last change (file stats only, provisional winner by score):
    <git diff of highest-scoring branch --stat>

    Respond as JSON only.
```

On the first generation after transition, use `Phase: convergence (transitioned at gen N)` and add the transition rationale summary after the Phase line:

```
    Transition rationale: <one-sentence summary of why exploration ended>
```

- [ ] **Step 2: Commit**

```bash
git add plugin/skills/run/references/loop.md
git commit -m "loop.md: add Phase and Ratchet to coherence invocation template"
```

---

### Task 9: Verify and Final Commit

- [ ] **Step 1: Read both modified files end to end and verify consistency**

Read `plugin/skills/run/SKILL.md` and `plugin/skills/run/references/loop.md`. Check:
- Phase terminology is consistent ("exploration" / "convergence" everywhere)
- Ratchet description matches between SKILL.md (step 5) and loop.md (scores.jsonl format)
- Stopping condition threshold (4.8) is stated only once in SKILL.md
- No references to the old 4.5 threshold remain
- Coherence invocation template in loop.md matches what SKILL.md step 6 describes

- [ ] **Step 2: Fix any inconsistencies found**

- [ ] **Step 3: Commit any fixes**

```bash
git add plugin/skills/run/SKILL.md plugin/skills/run/references/loop.md
git commit -m "Verify consistency across phased exploration changes"
```
