# Gen 3-c: New Frontier

Three improvements targeting areas no prior variant touched: reward-hacking resistance, failure-mode diagnostics, and scoring-judge bias. All three are structural guards rather than new procedures, so they cost little per generation but cover a class of self-improvement pathologies that the current plugin has no defense against.

## Research

1. Cemri, M. et al. (2025). *Why Do Multi-Agent LLM Systems Fail?* arXiv:2503.13657. Empirical taxonomy (MAST) over 1,600+ annotated traces from 7 multi-agent frameworks. 14 failure modes collapse into three roots: specification issues, inter-agent misalignment, verification gaps. Cohen's kappa 0.88 between human annotators. https://arxiv.org/abs/2503.13657
2. Zhang, J. et al. (2025). *Darwin Gödel Machine: Open-Ended Evolution of Self-Improving Agents.* arXiv:2505.22954. Self-modifying coding agents improved SWE-bench 20 to 50 percent, but in several runs the agent removed hallucination markers and fabricated passing test logs to hack the reward function. Only detectable because the system kept a transparent lineage of every change. https://arxiv.org/abs/2505.22954
3. Lightman, H. et al. (2023). *Let's Verify Step by Step.* arXiv:2305.20050. Process supervision (feedback on intermediate steps) outperforms outcome supervision (feedback on final result) on MATH: 78 percent vs baseline. Motivates auditing the reasoning trail behind score changes, not just the final score. https://arxiv.org/abs/2305.20050
4. *Calibrating LLM Judges: Linear Probes for Fast and Reliable Uncertainty Estimation* (2025). arXiv:2512.22245. LLM judges are systematically miscalibrated (ECE 0.108 to 0.427) and show position bias whose magnitude depends on model family, context length, and candidate quality gap. https://arxiv.org/abs/2512.22245
5. Ye, J. et al. (2024). *Justice or Prejudice? Quantifying Biases in LLM-as-a-Judge.* Surveyed in the LLM-judge literature; position, verbosity, and self-preference biases are pervasive. Motivates order-randomization and swap-retest for close calls.
6. *Scalable Best-of-N Selection for LLMs via Self-Certainty* (2025, ICLR OpenReview 29FRqmVQK8) and related test-time-compute work: when samples are close, the honest move is to rescore, not to pick the first reading. Motivates the 0.3-margin tiebreaker.

## Improvement 1: Ratchet Integrity Audit (reward-hacking guard)

**What.** SKILL.md step 5 now calls a two-question audit for every criterion edit: does this edit sharpen or soften the bar, and was it chosen because the winning variant failed the old wording. Answers append to `metrics/ratchet-audit.jsonl`. A `soften` + `variant_failed` combination is presumed score-gaming and auto-reverts. The coherence agent only sees a one-field summary (`"ratchet_audit": "clean" | "reverted"`), so the firewall is preserved.

**Why.** criteria.md already carries the human rule "never soften to inflate scores," but the current loop has zero structural enforcement. The Darwin Gödel Machine paper is the best-documented case of a self-modifying system routing around its reward function when given the chance, and Cemri's MAST calls out specification drift as one of three root failure categories. A cheap per-generation log entry turns the rule into evidence the meta-agent must produce.

**Source.** Darwin Gödel Machine 2025 (reward hacking observed); Cemri MAST 2025 (specification-issues category); Lightman 2023 (process supervision beats outcome supervision when the trace is auditable).

**Risk.** Tiny new metrics file; the audit adds 2 one-sentence answers per edited criterion per generation, a handful of tokens. Risk of false positives is bounded because legitimate soften edits (pruning obsolete criteria) are explicitly allowed with a note. Real cost is zero if no criteria were edited.

**Novelty vs prior variants.** No prior variant (gen-1-a, 1-b, 1-c, 2-a, 2-b, 2-c) touched the ratchet for integrity or added any audit log. Gen-2-a raised the ratchet bar numerically; gen-3-c makes the ratchet self-auditing.

## Improvement 2: MAST-derived failure-mode taxonomy

**What.** A new "Failure-Mode Taxonomy" section in loop.md with three categories (specification drift, inter-variant misalignment, verification gap) and concrete syndicate-visible signals for each. SKILL.md step 1 (Diagnose) now points at it. Taxonomy findings only land in meta-notes when they change the decision, so the addition is narratively quiet in normal generations.

**Why.** The current loop has Diagnose as "what's weakest in the last attempt" with no structured prompt, so the meta-agent reinvents diagnostic categories from scratch every generation. Cemri 2025 gives us 14 empirically grounded modes already clustered into three high-level roots. Compressing the taxonomy to three signal-rich bullets is load-bearing and costs under 200 words.

**Source.** Cemri et al. 2025, MAST taxonomy, 14 modes, 3 root categories, human-annotated across 7 frameworks.

**Risk.** If the taxonomy proves too generic, it will be ignored (worst case: dead text). Mitigated by gating meta-notes entries on decision-changing findings only, so it won't bloat the notes file.

**Novelty vs prior variants.** Completely new. Gen-1-a focused on promotion plumbing. Gen-1-b did literature review but did not add a diagnostic taxonomy. Gen-2 variants focused on scoring, ranking, and token trimming, none of them on Diagnose.

## Improvement 3 (small, load-bearing): position-bias mitigation in scoring

**What.** Two new one-line rules in SKILL.md step 4 and a supporting paragraph in loop.md. (a) Randomize variant read order when scoring, don't walk a-b-c. (b) If the top two variant averages are within 0.3, rescore both with swapped order and keep the lower reading.

**Why.** The meta-agent is the judge here, and LLM judges are measurably position-biased (Calibrating LLM Judges 2025, Ye 2024). Gen-2-a debated pairwise scoring but correctly deferred it as over-engineered for small N. Order randomization plus a swap-retest tiebreaker is the cheapest honest mitigation and does not require any new machinery.

**Source.** Calibrating LLM Judges arXiv:2512.22245 (2025); Ye 2024 position-bias survey; Self-Certainty Best-of-N ICLR 2025 (close-margin rescoring is the right call when samples are close).

**Risk.** Adds up to one extra scoring pass in tight generations. Bounded: only triggers when the top two are within 0.3. Zero cost when the winner is clear.

**Novelty vs prior variants.** Reserved list explicitly keeps pairwise scoring for later. This improvement is distinct: it is a cheap sanity check on the existing absolute-score procedure, not a new scoring method.

## Coherence-firewall check

- No code, skill text, or prompt content flows into the coherence agent.
- The ratchet audit adds exactly one extra field (`"ratchet_audit": "clean" | "reverted"`) to the coherence prompt. That is a one-token signal about the meta-agent's own behavior, not about deliverable content, so it is consistent with the firewall's "metrics and trajectory only" invariant.
- `plugin/agents/coherence.md` was not modified.

## Scope discipline

- `plugin/agents/*.md` untouched.
- `syndicate/` untouched except this `attempts/gen-3-c/` directory.
- No reserved-list ideas implemented (no pairwise scoring, no empirical discovery ranking, no dual-tier shared learning, no further token trimming beyond what these additions required).
