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
