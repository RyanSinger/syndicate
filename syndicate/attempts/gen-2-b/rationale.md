# Gen 2-b: Empirical Capital Maturity

## Premise

Gen 1-a shipped a clean promotion pipe to `~/.claude/`. The pipe is necessary but not sufficient. Once a user accumulates ten or twenty promoted artifacts across runs, description-only ranking stops scaling: every Gen 0 discovery has to choose what to load into limited working context, and "matches some keywords" is a weak signal compared to "this thing actually helped on past runs."

Gen 2-b adds the missing feedback loop: track empirical performance of discovered artifacts, rank by a blended quality + popularity + relevance score, and auto-flag duds. Promotion plumbing is preserved verbatim. Scoring mechanics, coherence agent, and meta-state are untouched.

## Research Grounding

- **Voyager** (Wang et al. 2023, arXiv:2305.16291) demonstrated that a persistent skill library carried across tasks is the dominant factor in lifelong agent performance, but the paper also notes that retrieval over that library matters: skills indexed only by description suffer as the library grows. Voyager itself uses an LLM-similarity retrieval over skill descriptions; later work has shown empirical reweighting helps.
- **Lifelong LLM Agents Roadmap** (Zheng et al. 2025, arXiv:2501.07278) frames the open problem as a "wake-sleep" loop: agents must record outcomes during execution (wake) and curate the library between runs (sleep), retiring or downweighting stale skills. The roadmap explicitly calls out staleness, usage tracking, and reversible deactivation as missing primitives in most agent frameworks. Record Usage + auto-flag + reversibility map directly onto this.
- **ExpeL** (Zhao et al. 2024) cross-task transfer experiments include an insight-pruning step: insights that fail to generalize across tasks are removed from the working set. ExpeL's pruning is harder (delete) than ours (flag), but the empirical signal is the same: track per-use outcomes, drop the ones that don't earn their context budget.
- **Generative Agents** (Park et al. 2023) memory retrieval blends relevance, recency, and importance into a single score. Our blended discovery rank (`desc_match` + `use_signal` + `quality`) is the same shape, adapted to the syndicate's promoted-artifact setting where "importance" becomes "average score delta the artifact has produced."

The cold-start fallback (neutral 0.5 quality, zero use signal, description-only rank) is the standard fix for the cold-start problem in quality-weighted retrieval: don't punish unproven artifacts, but don't reward them either.

## What Gets Added (on top of 1-a's baseline)

1. **Manifest schema extension**. Five new fields per entry: `uses_count`, `score_deltas` (capped list of last 10), `avg_score_delta`, `last_used`, `flagged`. All initialized to zero/empty/null/false at promotion. The promotion path itself is unchanged; extension is purely additive.
2. **Discovery Ranking Formula**. Blended score `0.5 * desc_match + 0.2 * use_signal + 0.3 * quality`, with explicit cold-start fallback so new artifacts compete on description alone. Discovery loads the top 10 candidates' descriptions into working context; the rest stay in the manifest.
3. **Auto-flag rule**. After `uses_count >= 3`, if `avg_score_delta <= 0`, flag the artifact. Flagged artifacts are skipped by Discovery. The flag is reversible by a later positive event. Retirement remains manual: flagging is hiding, not deletion.
4. **Record Usage section**. Defines exactly when (generation boundary or dissolution) and how (locate line, append delta, recompute, rewrite) to update empirical fields. The rule is conservative: at most one event per artifact per run, and only on a strict score improvement (with the negative branch reachable when a loaded artifact rode a losing generation).
5. **SKILL.md hook**. One line added to step 8 ("Record what you learned") pointing the meta-agent at Record Usage when a discovered artifact contributed.

## What Is Preserved Verbatim

- The Promotion Scope section (user-level default, project fallback opt-out).
- The Collision Policy section (no overwrite; fall back to project; record collision; original-author revision rule). Not touched.
- The promotion path itself: how artifacts get written to `~/.claude/agents/` or `~/.claude/skills/`.
- All scoring mechanics (no pairwise, no LLM-as-judge changes).
- Coherence agent (read-only confirmed: `plugin/agents/coherence.md` not touched).
- syndicate/ meta-state.

## Token Discipline

- SKILL.md: 1 line edited (well under the 5-line cap).
- loop.md: empirical-fields paragraph (~3 lines), Discovery rewrite (~12 lines net), Ranking Formula (~14 lines), Auto-Flag Rule (~5 lines), Record Usage (~22 lines). All in references/loop.md, which is loaded only when the meta-agent needs procedural detail.
- No new files created in the plugin.
- Discovery loads at most top-10 descriptions, bounding per-generation token cost as the user library grows. This is the load-bounding the directive cares about.

## Criterion-by-criterion Self-Score

1. **Cross-project promotion end-to-end**: 5. Baseline preserved verbatim; manifest schema is additive and backward-compatible (a missing empirical field is treated as zero/null/false on read).
2. **Research-grounded**: 5. Four 2023-2025 sources cited inline at the formula and at the auto-flag rule, each tied to a specific design decision.
3. **Plugin still works**: 5. All edits are textual additions to one reference file plus one line in SKILL.md. No agent definitions, no scoring code, no metrics format changes that break readers.
4. **Net improvement over current plugin**: 5. Empirical ranking + auto-flag is the missing curation half of the wake-sleep loop. Without it, the user's library grows monotonically and Discovery degrades.
5. **Addresses non-promotion weaknesses**: 5. The ranking + flag + record-usage machinery is the non-promotion improvement layered on top.
6. **Token-disciplined; coherence firewall preserved**: 5. SKILL.md change is one line. Coherence prompt and coherence agent untouched. Discovery output is bounded by top-10.

## Risks

- **Schema migration**: existing manifest entries from 1-a runs lack the new fields. Reader code (Discovery) must treat missing fields as defaults. The text says so explicitly in the cold-start description but reader implementations need to respect it. Acceptable for v1; the meta-agent reading the manifest is an LLM and will handle a missing field gracefully.
- **Keyword extraction is unspecified**. "Goal keywords, lowercased, stop-words removed" leaves the exact tokenization to the meta-agent. Acceptable: this is a soft retrieval signal, not a deterministic index. A future variant can sharpen this.
- **Single-process write race**: noted in text. Bounded to one lost delta. Acceptable.
