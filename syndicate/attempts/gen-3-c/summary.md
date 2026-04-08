# Gen 3-c Summary

Three structural guards added to the plugin: a ratchet integrity audit (reward-hacking guard), a MAST-derived failure-mode taxonomy for Diagnose, and a position-bias mitigation in the scoring step. All grounded in 2024 to 2025 sources. Reserved-list ideas untouched.

## Criteria Self-Score

1. **Cross-project promotion end-to-end**: 4. Preserved intact from gen-1-a; this variant does not regress it. No new end-to-end dry run performed (out of scope for a structural-guard variant).
2. **Research-grounded**: 5. Six 2024 to 2025 sources cited, each tied to a specific edit: MAST taxonomy (Cemri 2025), Darwin Godel Machine reward hacking (Zhang 2025), Lets Verify Step by Step (Lightman 2023), Calibrating LLM Judges (arXiv:2512.22245), Ye 2024 position bias, ICLR 2025 self-certainty best-of-N.
3. **Plugin still works**: 4. SKILL.md edits are additive inside existing numbered steps. loop.md adds two new sections and one taxonomy reference, no existing section removed. New ratchet-audit.jsonl follows the existing append-only JSONL convention in metrics/. No dry run executed in this worktree.
4. **Net improvement**: 5. Adds a class of defenses (reward-hacking resistance, structured diagnosis, judge-bias mitigation) that the plugin previously lacked entirely. Each improvement has a clear mechanism and a cited source.
5. **At least TWO non-promotion improvements**: 5. Three non-promotion improvements land: ratchet integrity audit, failure-mode taxonomy, position-bias mitigation. Meets "at least two" with margin.
6. **Token-disciplined; coherence firewall integrity preserved**: 4. SKILL.md grew from 1504 to 1625 words (+121). loop.md added roughly 350 words in two new sections. Coherence agent gains exactly one new field (ratchet_audit), a one-token status signal with no deliverable content. plugin/agents/coherence.md untouched.

**Average**: 4.5.

## Files changed

- plugin/skills/run/SKILL.md: three targeted edits in steps 1, 4, 5.
- plugin/skills/run/references/loop.md: two new sections (Failure-Mode Taxonomy, Ratchet Integrity Audit) and a Scoring Hygiene paragraph added before Metrics Formats.

## Files not changed (by rule)

- plugin/agents/coherence.md
- plugin/agents/task.md
- syndicate/ except this attempts directory
