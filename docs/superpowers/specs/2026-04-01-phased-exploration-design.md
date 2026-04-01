# Phased Exploration: Diverge Then Converge

## Problem

The syndicate converges in 2-3 generations because it writes achievable criteria, scores itself well against them, and hits the 4.5 convergence threshold before exploring alternatives. The output is usually fine but not meaningfully better than a single-pass approach like brainstorming. The syndicate's value proposition (burn tokens to explore the possibility space) is unrealized.

## Design

Split the syndicate lifecycle into two explicit phases: **exploration** (diverge, try different approaches, raise the bar) and **convergence** (refine the best approach, ship).

### Phase 1: Exploration

Starts at Gen 1. Convergence stopping condition is structurally disabled.

Rules:
- Every generation must produce 2+ parallel variants. No narrow mode.
- After scoring each generation, the meta-agent must perform a **criteria ratchet**: exactly one of:
  - **Add** a criterion the current best doesn't already satisfy at 5
  - **Split** a vague criterion into sharper ones
  - **Raise the bar** on an existing criterion
- Criteria may also be **pruned** if they stop making sense. Pruning is independent of the ratchet (doesn't substitute for it). Document what was pruned and why in meta-notes.
- No cap on total criteria count. The coherence agent already watches for complexity growth without corresponding improvement.

### Phase 2: Convergence

Entered via explicit transition. Normal loop rules resume.

Rules:
- 1-N variants per generation based on confidence (current behavior)
- Criteria ratchet is optional
- Criteria cannot be softened, but can be pruned with justification
- Convergence threshold: 4.8 average for 2+ consecutive generations (raised from 4.5)

### Phase Transition

Transition from exploration to convergence is a deliberate act, not an automatic threshold.

**Eligibility:**
- At least 3 exploration generations complete
- At least 2 genuinely different approaches tried across variants (not just parameter tweaks)

**To transition**, the meta-agent writes a transition rationale to meta-notes:
- What approaches were explored and how they compared
- Why the current best approach won (with evidence from variant scores)
- What the exploration surfaced that wouldn't have been obvious upfront

The transition rationale summary is passed to the coherence agent in the next invocation. The coherence agent can flag if the rationale is thin.

Phase is tracked in `scores.jsonl` via a `phase` field (`"exploration"` or `"convergence"`).

### Coherence Agent Adaptations

The static prompt (`agents/coherence.md`) is unchanged. All phase awareness comes through the dynamic invocation context.

**During exploration**, the invocation prompt includes:
- `Phase: exploration (gen N of minimum 3)`
- All variant scores and what each tried (always 2+)
- The ratchet action taken: `Ratchet: added "X" / split "Y" / raised "Z"`

The coherence agent calibrates expectations: score drops during exploration are healthy (criteria getting harder, approaches diverging). Low variant diversity (all variants scoring similarly) is a flag signal.

**At transition**, the invocation prompt includes:
- `Phase: convergence (transitioned at gen N)`
- One-sentence transition rationale summary

**During convergence**, the invocation prompt includes:
- `Phase: convergence`
- Standard scoring info

### Stopping Conditions

- **Converged:** average score 4.8+ for 2+ consecutive generations, and the syndicate is in convergence phase. Cannot trigger during exploration.
- **All branches pruned:** no viable parents. Report best result. Either phase.
- **Sustained plateau:** flagged 3+ consecutive times. Either phase. During exploration, this means variants aren't producing useful diversity. During convergence, refinement has stalled.

**Venture mode:** discovery phase is unchanged. Each new round starts back in exploration phase, so the full diverge-then-converge cycle repeats per round.

### Metrics Changes

`scores.jsonl` gets two new fields:
```jsonl
{"generation": 1, "scores": {...}, "avg": 1.5, "model": "opus", "criteria_changed": false, "phase": "exploration", "ratchet": "added: error recovery", "timestamp": "..."}
```

- `phase`: `"exploration"` or `"convergence"`
- `ratchet`: describes the ratchet action taken (exploration only, null during convergence if no ratchet)

### File Changes

**SKILL.md:**
- Gen 1 section: note it is always exploration phase
- "Every Generation After That": step 2 requires 2+ variants during exploration; new step between 4 and 5 for the mandatory ratchet action; phase transition subsection added
- Stopping conditions: rewritten per this spec
- Principles: add "Explore before you converge. Early generations are for discovery, not optimization."

**loop.md:**
- `scores.jsonl` format: add `phase` and `ratchet` fields
- Coherence agent invocation template: add `Phase:` and `Ratchet:` lines to the prompt

**No changes:**
- `agents/coherence.md` (static prompt unchanged)
- `agents/task.md` (task agents don't need phase awareness)
- Templates (criteria start as hypotheses regardless)
- Git workflow, promoting learnings, discovery phase mechanics
