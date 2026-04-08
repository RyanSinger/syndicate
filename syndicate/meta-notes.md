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

## Generation 3 (final exploration)

Three parallel variants. First dispatch of all three hit the worktree isolation bug: each worktree forked from `main` instead of `syndicate/run-1`. Filed as anthropics/claude-code#45371 and baked a `baseline-sync` workaround into loop.md Task Agent section. Re-dispatched all three with mandatory first-step sync.

- **3-a** Integrate pruned winners (mutation operators + empirical discovery ranking): 4.67. Pruned. Surgical, but 3-b outscored.
- **3-b** Live dry-run validation + convergence threshold tuning: **4.83. Winner.**
- **3-c** New frontier (ratchet integrity audit + MAST taxonomy + position-bias scoring): 4.33. Pruned. Added +121 words to SKILL.md, partially undoing gen-2-c's tightening; three new mechanisms at once was too ambitious.

**Why 3-b won.** Only variant that empirically proved the plugin works. Ran the bootstrap procedure twice in disposable scratch projects and found THREE real bugs, including the `git tag` gpgSign failure that bit this very session when I bootstrapped `syndicate/run-1` at the start (had to work around with -m flag). Plus tuned the convergence threshold with citations. Empirical validation >> speculative machinery.

**Transition rationale.** Three exploration generations have surfaced a clear direction and a stable bank of pruned-but-valuable ideas. Gen 1 established promotion plumbing. Gen 2 tightened prose. Gen 3 empirically validated the plugin and fixed real bootstrap bugs. Further exploration would spread surface area and increase token cost. Convergence focus: disciplined integration of best bank ideas.

## Generation 4 (first convergence)

Single variant, applied directly by the meta-agent (no subagent): integrated gen-3-a's mutation operator taxonomy and empirical discovery ranking formula as a known-good narrow delta from the reachable (but deleted) branch. +1 line SKILL.md, +23 loop.md. All grounding preserved (PromptBreeder, EvoPrompt, Voyager, Zheng 2025). Score: 5.0. Coherence: continue.

## Generation 5 (flagged, reverted)

Attempted to add a trimmed version of gen-3-c's reward-hacking audit to the ratchet step in SKILL.md. Coherence flagged: token complexity jumped 131 words vs gen-4 while score dropped from 5.0 to 4.83. Respected the flag and reverted. The principle "never soften criteria to inflate scores" was already in the Principles section anyway; restating it in step 5 was redundant. Plateau counter: 1.

## Generation 6 (consolidation)

No new plugin edits. Sanity-checked all landmarks (Promotion Scope, Collision Policy, Discovery at Gen 0, Mutation Operators, Ranking Formula = 5 grep matches), verified coherence firewall (0 lines changed to agents/coherence.md since main), confirmed gen-3-b bug fixes present. Distilled meta-notes with this round's learnings. Score: 5.0 (gen-4 state preserved, no regressions). Plateau counter reset by continue.

**Convergence stop:** gens 4 and 6 both at 5.0 in convergence phase, with gen-5 flagged and cleanly reverted between them. Two effective convergence gens at 4.8+, stop condition met. Ready to dissolve.

## Key meta-learnings from this run

1. **Empirical validation > speculative mechanisms.** Gen 3-b found real bugs the prior research-heavy variants missed. When uncertain, run the thing.
2. **Token discipline compounds.** Gen 2-c's editorial pass is one of the most valuable single changes because it runs every generation forever. Cost-free improvements at the right level are gold.
3. **Coherence firewall works.** Gen 5 was correctly flagged when a small feature added disproportionate bulk. Revert-and-ship is a legitimate resolution.
4. **Worktree isolation bug is universal and requires baseline-sync workaround.** Now documented in loop.md and filed upstream.
5. **Don't front-load machinery.** Gen 1-b and Gen 2-a were strong research-grounded ideas that lost to narrower, disciplined variants because their scoping exceeded the current need. Ideas go to the bank; integrate when the cost/benefit flips.
6. **Match variant scope to exploration phase.** Gen 1 went wide (narrow/broad/architectural), Gen 2 picked different weaknesses (scoring/capital/tokens), Gen 3 tried orthogonal strategies (integrate/validate/novel). Diversity of approach is what the coherence agent is actually checking.
