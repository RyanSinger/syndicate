# Gen 2-a Rationale: Scoring Reliability + Variant Diversity

## Sources

1. Zheng et al. 2023, Judging LLM-as-a-Judge with MT-Bench and Chatbot Arena. arXiv:2306.05685. https://arxiv.org/abs/2306.05685
   Establishes that pairwise comparison correlates more strongly with human judgment than absolute scoring on close comparisons; introduces position bias as a known failure mode.

2. Gu et al. 2024, A Survey on LLM-as-a-Judge. arXiv:2411.15594. https://arxiv.org/abs/2411.15594
   Survey concludes that pairwise protocols are more aligned with human evaluation than score-based ones in most settings, while documenting the position-bias and length-bias risks. Recommends position-swap as a cheap mitigation.

3. Liusie, Manakul, Gales 2023, LLM Comparative Assessment: Zero-shot NLG Evaluation through Pairwise Comparisons. arXiv:2307.07889. https://arxiv.org/abs/2307.07889
   Shows pairwise comparison reliably outperforms direct pointwise scoring on summarisation/dialogue NLG eval, particularly when score gaps are small (which is the typical syndicate gen-to-gen situation).

4. Tripathi et al. 2025, Pairwise or Pointwise? Evaluating Feedback Protocols for Bias in LLM-Based Evaluation. arXiv:2504.14716. https://arxiv.org/abs/2504.14716
   Counterweight: pairwise protocols flip preference about 35% of the time under distractors vs. 9% for absolute scores. Justifies keeping absolute scores alongside pairwise (for the ratchet) and using position-swap.

5. Fernando et al. 2023, PromptBreeder: Self-Referential Self-Improvement via Prompt Evolution. arXiv:2309.16797. https://arxiv.org/abs/2309.16797
   Demonstrates that a fixed taxonomy of mutation operator classes (5 classes including direct, EDA, hyper, and Lamarckian mutations) outperforms ad-hoc edits across reasoning benchmarks. Justifies declaring named operators per variant.

6. Guo et al. 2023, EvoPrompt: Connecting LLMs with Evolutionary Algorithms Yields Powerful Prompt Optimizers. arXiv:2309.08532. https://arxiv.org/abs/2309.08532
   Shows that explicit evolutionary operators (crossover, mutation classes) on discrete prompts converge faster than unstructured iteration; up to 25 percent gain on BBH. Reinforces the named-operator design.

7. Mouret and Clune 2015 / quality-diversity literature with 2024 LLM applications (LLMatic, CycleQD, DejaQ, ICLR 2024 "Quality-Diversity through AI Feedback" https://proceedings.iclr.cc/paper_files/paper/2024/file/5b9bef4eae0f574cedbf9f4bf29d8ae7-Paper-Conference.pdf).
   Quality-diversity work argues that collapsing diversity early in evolutionary search starves later generations of building blocks. Justifies the diversity-collapse plateau signal as a structural early warning, not just a fitness signal.

## Changes

### A. Pairwise winner selection
- What: variant winner is chosen by round-robin pairwise comparison with position-swap. Absolute 1 to 5 scores are still recorded for the ratchet, trajectory, and convergence detection.
- Files touched: plugin/skills/run/SKILL.md (one bullet edit in step 4), plugin/skills/run/references/loop.md (new "Pairwise Winner Selection" section, branches.jsonl schema updated with optional `rank`, `margin`, `operator`).
- Why: directive criterion 1 (scoring reliability). Pairwise judgments are documented to be more aligned with human evaluation than pointwise scoring on small score gaps (Zheng 2023, Gu 2024, Liusie 2023). This is the dominant syndicate situation: gen-to-gen variants usually differ by less than 0.5 points on a 5-point scale, exactly the regime where pointwise scoring is noisiest.
- Source: Zheng 2023, Gu 2024, Liusie 2023.
- Risk: pairwise protocols have their own bias (Tripathi 2025: ~35% preference flip under distractors). Mitigations: (a) keep absolute scores for the ratchet so a noisy pairwise call cannot soften criteria, (b) position-swap and require agreement, treat disagreement as ties, (c) cap the round-robin at 4 variants and fall back to single-elimination above that.

### B. Named mutation operators
- What: each variant declares one of {rewrite, constrain, decompose, invert, borrow}. Two same-operator variants in one generation do not satisfy the "genuinely different" exploration requirement.
- Files touched: plugin/skills/run/SKILL.md ("Propose changes" step), plugin/skills/run/references/loop.md (new "Mutation Operators" section), plugin/agents/task.md (one paragraph telling task agents to print the operator on the first line of summary.md).
- Why: directive criterion 2 (variant diversity). PromptBreeder and EvoPrompt both demonstrate that a fixed, named taxonomy of mutation classes converges faster and produces more genuinely different candidates than ad-hoc "be different" instructions.
- Source: Fernando 2023, Guo 2023.
- Risk: forcing operators may feel rigid. Mitigated by keeping the set small (5), making it advisory-but-checked, and letting the meta-agent borrow from the same operator across generations (only same-generation collisions are blocked).

### C. Diversity-collapse plateau signal
- What: in exploration phase, if the last 2 generations had pairwise margins below 0.5, winning absolute averages within 0.3, and overlapping mutation operators between consecutive winners, count it as 1 plateau flag.
- Files touched: plugin/skills/run/SKILL.md (Stopping Conditions section, one bullet).
- Why: pure fitness plateau detection misses the case where variants are converging structurally before they have explored enough. Quality-diversity literature (MAP-Elites, ICLR 2024 Quality-Diversity through AI Feedback) argues that diversity loss is the leading indicator of premature convergence. The signal is exploration-only and only contributes to the existing 3-flag plateau counter, so it cannot independently stop the syndicate.
- Source: Mouret-Clune 2015 / Quality-Diversity through AI Feedback ICLR 2024.
- Risk: false positives if a problem genuinely has only one good operator. Mitigated by requiring all three conditions simultaneously (margin AND absolute AND operator overlap) and by feeding into the existing flag counter rather than acting unilaterally.

## What was NOT touched (deliberately)
- plugin/skills/run/SKILL.md sections on cross-project promotion: untouched.
- plugin/agents/coherence.md: untouched (firewall integrity).
- syndicate/ meta-state outside of attempts/gen-2-a/: not modified.
- scores.jsonl schema: unchanged (backward compatible). Only branches.jsonl gained optional fields.

## Token discipline
SKILL.md grew by approximately 4 lines (one expanded bullet in step 2, one rewritten bullet in step 4, one new bullet in stopping conditions). All operator definitions, pairwise procedure, and schema details live in loop.md, which only loads when the meta-agent reads it. The task agent prompt (task.md) gained one short paragraph because operator declaration must reach every variant.
