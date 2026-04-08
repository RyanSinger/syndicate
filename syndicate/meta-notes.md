# Meta-Agent Notes

Record observations here after each generation. When a pattern recurs enough to be reusable, promote it to a learned agent (procedure) or domain skill (knowledge). Distill this file at round boundaries or when it gets too long. Git preserves the full history.

---

## Generation 1

Three parallel variants, each exploring a distinct angle on "improve the plugin".

**Variants tried:**
- **1-a** (narrow: promotion plumbing only): 4.2 avg. **Winner.**
- **1-b** (broad: 5-change bundle from deep lit review): 3.6 avg. Pruned.
- **1-c** (architectural: dual-tier shared learning layer): 4.0 avg. Pruned.

**Why 1-a won.** 1-a landed closest to user intent: direct user-level promotion with no staging gate, which matches the user's explicit "land directly" instruction. Collision policy is clean (fall back to project, never silently overwrite). Token discipline is best (7+70 lines). Lowest implementation risk: didn't touch scoring, metrics, or agent invocation.

1-b gated promotion behind "3 gens survived + project-agnostic wording" — an implicit staging gate contradicting the user. Also changed scoring from absolute to pairwise and added mutation operators: multiple interacting machinery changes at once, highest surface area.

1-c's canonical-store + runtime-mirror dual-tier duplicates what Claude Code's native user-level discovery already does, adding complexity (event-sourced manifest, staleness math, conflict resolution, divergence detection) without a clear v1 win. 136 lines in loop.md is the worst bloat.

**Ratchet action.** Added criterion 5 ("Addresses non-promotion weaknesses"). 1-a's weakness is exactly its strength: narrow scope. Gen 2 must keep the promotion work AND add at least one meaningful improvement elsewhere. Ideas worth salvaging from pruned variants:
- **From 1-b:** pairwise variant scoring (LLM-as-Judge survey, Gu et al. 2024); named mutation operators with explicit diversity check (PromptBreeder, EvoPrompt).
- **From 1-b:** diversity-collapse as an additional plateau signal during exploration.
- **From 1-c:** usage-event recording on promoted artifacts so the Gen 0 discovery index can rank by empirical value, not just description matching.

**Coherence:** continue. Trajectory healthy, complexity growth proportional, ratchet doing its job.

**Research surfaced:** Voyager 2023, Reflexion 2023, ExpeL 2024, Generative Agents 2023, ADAS / Meta Agent Search 2024, PromptBreeder 2023, EvoPrompt 2023, LLM-as-Judge survey 2024, Darwin Godel Machine 2025, Lifelong LLM Agents Roadmap 2025, ACM TOIS Memory Survey 2025, Anthropic Agent Skills Oct 2025 + Tool Search Tool Nov 2025.

## Generation 2

Three parallel variants on top of gen-1-a baseline, each tackling a different non-promotion weakness.

**Variants tried:**
- **2-a** (pairwise scoring + named mutation operators + diversity-collapse signal): 4.5. Pruned. Built on WRONG base (missed gen-1-a baseline; worktree isolation forked from main, not run-1). Work is salvageable via cherry-pick if needed later.
- **2-b** (empirical capital maturity: usage tracking, blended discovery ranking, auto-flag): 4.5. Pruned. Clean extension of gen-1-a's manifest; mostly future-value (pays off after many promotions accumulate).
- **2-c** (editorial pass on SKILL.md, loop.md, task.md): **4.67. Winner.**

**Why 2-c won.** Durable compounding savings at the most expensive tier: SKILL.md and task.md are loaded on every single task-agent dispatch, so trimming 10% and 13% respectively pays every time. Zero load-bearing content removed per spot-check. Research-grounded (Anthropic context engineering 2025, LLMLingua-2 ACL 2024, Chroma Context Rot 2025) argues that tightening isn't just aesthetic: redundant phrasing functions as a distractor and degrades long-context performance.

2-a was strong work on the wrong base: a worktree-isolation failure meant it forked from `main` instead of `syndicate/run-1`, so its diff doesn't stack on top of gen-1-a. The pairwise procedure (round-robin, position-swap, tie-break by cumulative margin), mutation operator taxonomy, and diversity-collapse signal are all cleanly specified and should be considered for gen-3 integration. Cost concern: pairwise judgment adds real per-generation overhead (3 comparisons × 2 position swaps at N=3 variants = 6 judgments) that may not earn its keep at small N.

2-b's empirical ranking is an elegant upgrade but is latent: it only pays off after a critical mass of promoted artifacts exist with multiple runs of usage history. Current reality: zero promoted artifacts. Fold in later.

**Ratchet action.** Raised criterion 5 bar: "at least two" non-promotion improvements (up from "at least one"). Gen 3 must bundle more. Meta-level observation worth preserving: the ratchet is working. Gen 1 forced broadening beyond promotion; gen 2 delivered it; gen 3 now must stack improvements.

**Worktree isolation bug.** Both gen-2-a and gen-2-c had isolation anomalies: 2-a forked from the wrong base, 2-c's worktree didn't get created at all and the agent edited main directly. This may be a harness or plugin issue worth flagging. Mitigation for gen 3: explicitly verify each worktree branches from current `syndicate/run-1` HEAD after dispatch; if not, abort and re-dispatch.

**Coherence:** continue. Complexity trending DOWN (winner removed content). Trajectory healthy.

**Added to bank (potentially for later integration or promotion to shared skills):**
- Pairwise LLM-as-judge procedure (2-a) — implement when N>=3 variants and absolute-score ties become common
- Named mutation operator taxonomy (2-a) — could promote to a domain skill once proven
- Empirical discovery ranking formula (2-b) — implement before first user-level promotion goes live
- Auto-flag rule for stale artifacts (2-b) — same timing
