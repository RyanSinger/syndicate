# Gen 2-b Summary

Matures gen-1-a's promotion baseline with usage tracking and empirical ranking. Promotion plumbing untouched; collision policy preserved verbatim.

## Changes

- plugin/skills/run/SKILL.md: 1 line edited in step 8, pointing the meta-agent at Record Usage when a discovered artifact contributed to a winning generation.
- plugin/skills/run/references/loop.md:
  - Manifest schema: added uses_count, score_deltas, avg_score_delta, last_used, flagged to the user manifest line format. Empirical fields are mutated in place by Record Usage.
  - Discovery at Gen 0: skip flagged entries; rank by blended formula; sort discovered.jsonl; load top 10.
  - Discovery Ranking Formula: rank = 0.5 * desc_match + 0.2 * use_signal + 0.3 * quality, with explicit cold-start fallback (neutral 0.5 quality, zero use signal). Cited Voyager, Lifelong LLM Agents Roadmap, Generative Agents.
  - Auto-Flag Rule: if uses_count >= 3 and avg_score_delta <= 0, set flagged true. Reversible by later positive event. Retirement remains manual. Cited ExpeL and Lifelong LLM Agents wake-sleep.
  - Record Usage: defines when (generation boundary or dissolution; one event per artifact per run; only on strict score improvement, with reachable negative branch) and how (locate line, append clamped delta, recompute mean, set last_used, apply auto-flag, rewrite line).

## Preserved Verbatim

- Promotion Scope (user-level default).
- Collision Policy (no overwrite, project fallback, original-author revision).
- All scoring mechanics.
- plugin/agents/coherence.md (firewall integrity).
- syndicate/ meta-state.

## Sources Cited

- Wang et al. 2023, Voyager (arXiv:2305.16291): persistent skill library, library-compounding lifelong learning.
- Zheng et al. 2025, Lifelong LLM Agents Roadmap (arXiv:2501.07278): wake-sleep curation, staleness, reversible deactivation.
- Zhao et al. 2024, ExpeL: cross-task transfer with insight pruning.
- Park et al. 2023, Generative Agents: relevance + recency + importance retrieval blend.

## Token Footprint

- SKILL.md: +1 line edited (cap was 5).
- loop.md: ~55 net lines added across four sections, all in the loaded-on-demand reference file.
- No new files in plugin/.
- Discovery loads at most top-10 candidate descriptions per run.
