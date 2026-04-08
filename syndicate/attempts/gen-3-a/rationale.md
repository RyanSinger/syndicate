# Gen 3-a Rationale: Integrate Pruned Winners

## What This Variant Does

Layers the best pruned contributions from gen-2-a (variant diversity) and gen-2-b (empirical discovery) on top of the gen-2-c baseline (which carries gen-1-a's cross-project promotion plumbing and gen-2-c's tightened prose). All additions are concise; nothing from gen-2-c is re-expanded.

## What Was Integrated

### From gen-2-a: Mutation Operator Taxonomy

A named 5-operator set {rewrite, constrain, decompose, invert, borrow} added to `references/loop.md` as a new "Mutation Operators" section, with one-line definitions each. SKILL.md step 2 gains two lines requiring each variant to declare one operator and treating same-operator collisions as failing the diversity requirement. `branches.jsonl` gains an optional `operator` field.

Citations: PromptBreeder (Fernando et al. 2023, arXiv:2309.16797) shows a fixed mutation-class taxonomy outperforms ad-hoc edits on reasoning benchmarks. EvoPrompt (Guo et al. 2023, arXiv:2309.08532) shows explicit evolutionary operators on discrete prompts converge faster (up to 25 percent on BBH).

### From gen-2-b: Empirical Discovery Ranking

A "Ranking Formula" subsection added inside the existing "Discovery at Gen 0" section of loop.md, with the blended score `rank = 0.5 * desc_match + 0.2 * use_signal + 0.3 * quality`, explicit cold-start fallback, auto-flag rule (`uses_count >= 3` and `avg_score_delta <= 0`), and top-10 load bound. The user manifest JSONL line gains five empirical fields: `uses_count`, `score_deltas`, `avg_score_delta`, `last_used`, `flagged`.

Citations: Voyager (Wang et al. 2023, arXiv:2305.16291) establishes the persistent skill library as the dominant lifelong-agent primitive and notes retrieval quality matters. Lifelong LLM Agents Roadmap (Zheng et al. 2025, arXiv:2501.07278) names wake-sleep curation (usage tracking, reversible deactivation) as a missing framework primitive.

## What Was Deferred (per directive)

- **Pairwise winner selection (gen-2-a)**: full round-robin procedure skipped. Replaced with one-line reference: "pairwise is available as a tie-breaker; see gen-2-a rationale." Absolute scoring remains the default winner selector. Rationale: the full pairwise protocol is substantial; the tie-breaker pointer preserves the idea for a future variant without committing budget now.
- **Record Usage procedure (gen-2-b)**: full step-by-step algorithm skipped. Replaced with one-line stub: "usage recording is finalized when first user-level promotion runs live." Rationale: until at least one run produces a genuine cross-project promotion usage event, the recording path is speculative. The manifest schema is ready to receive data; the write-path spec can land once a real collision exercises it.
- **Diversity-collapse plateau signal (gen-2-a)**: not integrated. Rationale: the three-condition compound signal is a late-stage optimization and its interaction with the existing flag counter adds surface area. The operator taxonomy alone already raises diversity quality; the plateau detector can wait.

## What Was Preserved

- All of gen-1-a's promotion plumbing: "Promotion Scope", "Collision Policy", user-manifest authority, and the "Discovery at Gen 0" section. Verified by grep landmark check (3/3).
- Gen-2-c's tightened SKILL.md prose. SKILL.md word count moved from 1504 to 1530 (net +26 words, roughly two lines in step 2, matching the directive's "at most 2 lines" budget).
- `plugin/agents/coherence.md`: untouched. Coherence firewall integrity preserved.
- `syndicate/` meta-state outside `attempts/gen-3-a/`: untouched.

## Risks

1. **Operator declaration friction**: requiring every variant to name an operator adds a small ceremonial cost. Mitigated by keeping the set to 5 and making the definitions one line each. The "borrow" slot is deliberately broad to cover anything that imports from an external or historical source.
2. **Manifest schema drift**: gen-1-a runs' manifest lines lack the new empirical fields. Readers must treat missing fields as defaults (`uses_count: 0`, `flagged: false`). Acceptable because the reader is an LLM reading JSONL, not a strict parser.
3. **Cold-start gaming**: unproven entries compete on description alone and could crowd out proven entries. Bounded by the 0.5 + 0.2 + 0.3 weighting: a proven entry with `quality = 1.0` and `use_signal = 1.0` earns 0.5 over the cold-start floor, enough to dominate on ties.
4. **Record-Usage deferral**: the manifest has fields nothing writes to yet. The stub sentence makes the deferral explicit. Worst case: fields remain zero until a future variant wires the write path.

## Token Discipline

- SKILL.md: +26 words, +2 lines (within the explicit 2-line cap).
- loop.md: two new subsections totaling ~20 lines; both live in the reference file, which only loads when the meta-agent reads it.
- No files added to `plugin/`.
- No changes to scoring mechanics, coherence agent, metrics schemas beyond one optional field on `branches.jsonl` and five additive manifest fields.
