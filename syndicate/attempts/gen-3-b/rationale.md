# Gen 3-b Rationale: Live Dry-Run Validation, Bootstrap Bug Fixes, and Convergence Threshold Tuning

## What this variant is

The baseline (gen-1-a + gen-2-c) added promotion plumbing and tightened tokens. Nothing in the baseline had been **executed**. This variant runs the plugin's Setup procedure end to end against two disposable scratch projects, fixes every bug the live run surfaces, and makes one additional research-grounded improvement (Part B). It is the first empirical validation of the bootstrap path.

## Part A: live validation

See `validation-log.md` for the raw execution trace. Summary of bugs and fixes:

| # | Bug | Severity | Fix location |
|---|---|---|---|
| A | `git symbolic-ref refs/remotes/origin/HEAD` can exit 128 even when a remote exists; written procedure treats "has remote" as equivalent to "symbolic-ref succeeds" | minor | SKILL.md step 2; loop.md Git Workflow Bootstrap |
| B | Discovery pass at gen 0 is under-specified when `~/.claude/syndicate-manifest.jsonl` is absent (first-ever run on a machine); implementer does not know whether to write `discovered.jsonl` at all | minor, first-run trap | loop.md Discovery at Gen 0 step 1; SKILL.md step 4 |
| C | `git tag syndicate-seed-<N>` fails with `fatal: no tag message?` under the very common `tag.gpgSign=true` / `tag.forceSignAnnotated=true` user config. Bootstrap is **broken** for any developer who signs git artifacts. | critical | SKILL.md step 6; loop.md Git Workflow Bootstrap |

All three reproduced in `.scratch/run1` before fix. Run 2 executed end to end cleanly against the fixed plugin/.

### Why Bug C is critical, not cosmetic

The canonical way to trigger this failure is a developer who ran one of the widely-circulated "set up signed git" checklists:

```
git config --global commit.gpgsign true
git config --global tag.gpgsign true
git config --global tag.forceSignAnnotated true
```

With those in place, `git tag <name>` (a lightweight tag) is silently upgraded to an annotated-and-signed tag. Annotated tags require a message (via `-m` or editor) and signing requires a passphrase; in a non-interactive agent, the command either hangs or exits with `fatal: no tag message?`. This matches the semantic-release issue #3065, where the same upgrade path caused the release pipeline to hang forever. The fix is to make the tag explicitly annotated, supply the message on the command line, and override the sign flag per-invocation so the user's global config cannot hijack it.

Source 1 (Bug C, grounding): semantic-release/semantic-release issue #3065, "Hanging forever while tagging the release if git is configured to sign tags," https://github.com/semantic-release/semantic-release/issues/3065. Also the git-tag(1) documentation on `tag.gpgSign` and `tag.forceSignAnnotated`: https://git-scm.com/docs/git-tag.

## Part B: convergence threshold tuning with citation

The baseline stopping condition was:

> Converged: average score 4.8+ for 2+ consecutive generations, in convergence phase.

This is a single absolute-threshold test. Two research-grounded problems:

**Problem 1: LLM-as-judge pointwise scores drift.**
Pointwise LLM scores fluctuate on absolute rating scales. Even the best models (GPT-4, Llama-3 70B) diverge from calibrated human raters by up to ~5 points on absolute scales in high inter-human-agreement domains. An absolute 4.8 threshold on a 1-5 scale is within that drift envelope. A genuinely converged run can fail to cross 4.8 purely because the judge ran cold; an unconverged run can cross it purely because the judge ran hot.

Source 2 (Part B): LLM-as-a-judge calibration ceiling discussion (Confident AI, Evidently, Langfuse, Arize). Representative text: "pointwise scores tend to fluctuate a lot... even the best available models diverge by up to 5 points on absolute rating scales," https://www.confident-ai.com/blog/why-llm-as-a-judge-is-the-best-llm-evaluation-method ; https://www.evidentlyai.com/llm-guide/llm-as-a-judge ; https://arize.com/llm-as-a-judge/ . The core point: pointwise LLM scoring is a noisy signal; a stopping rule that depends on crossing a narrow absolute threshold on a noisy signal under-converges.

**Problem 2: absolute thresholds ignore the canonical EA plateau signal.**
In evolutionary algorithms, the standard termination criterion is not "hit value X" but "best fitness has not improved by more than epsilon over T consecutive generations" (plateau / stagnation detection). The syndicate's convergence phase is exactly an EA convergence phase: fitness is improving, criteria are frozen, each generation proposes refinements, and the meaningful stop signal is "refinements have stopped paying off." An absolute threshold alone cannot express this.

Source 3 (Part B): standard EA termination criteria, including "stop if best fitness has not improved by more than epsilon over the last T generations" (plateau detection on consecutive generations), https://www.educative.io/answers/common-termination-conditions-in-genetic-algorithm ; formal treatment in "Average Convergence Rate of Evolutionary Algorithms," https://arxiv.org/pdf/1504.08117 and ScienceDirect's "Average convergence rate of evolutionary algorithms in continuous optimization," https://www.sciencedirect.com/science/article/pii/S0020025520312421 .

### The fix

Replace the single absolute threshold with a dual condition:

> Converged: in convergence phase, and either (a) average score 4.8+ for 2+ consecutive generations, or (b) average score 4.5+ and improvement delta under 0.1 for 3+ consecutive generations.

Clause (a) is the old rule, unchanged. Clause (b) is a stagnation-on-good-quality signal: if the syndicate has parked at a high-but-not-perfect score and successive generations can't budge it, that is a converged-at-local-maximum outcome and the syndicate should ship, not burn compute until the judge happens to roll 4.8. The 0.1 delta is an epsilon tuned to be larger than expected LLM-judge noise on a stable deliverable, but smaller than a meaningful refinement. The 4.5 floor prevents premature stop on early bad plateaus.

Three generations, not two, because with a noisier signal you need more samples to distinguish drift from true stagnation.

This reduces wasted generations in the common case where the deliverable is good enough but the judge is stingy, while preserving the old high-bar clause exactly for cases where it does fire.

### Why this is "one improvement" and not feature sprawl

Clause (b) is strictly more permissive than clause (a), added as an OR. No existing convergence case is removed. No new metric is introduced; both clauses read the existing `scores.jsonl` avg field. No change to coherence agent, no change to prompts, no change to any generation loop step.

## What was not changed

- `plugin/agents/coherence.md`: untouched. Coherence firewall preserved.
- `syndicate/` content except `attempts/gen-3-b/`: untouched.
- Promotion plumbing from gen-1-a (Promotion Scope, Collision Policy, Discovery at Gen 0, dual manifest schemas, Voyager / Reflexion / ExpeL citations): preserved verbatim. Only the bug-fix language was inserted into Discovery at Gen 0 step 1 and the bootstrap / setup steps. I grep-verified `Promotion Scope | Collision Policy | Discovery at Gen 0` still returns 3 matches.
- Token hygiene from gen-2-c: preserved. Total edits added ~180 words across SKILL.md and loop.md, all load-bearing (bug fixes and convergence clause).

## Sources

1. semantic-release issue #3065: Git tag signing hangs release pipeline. Grounds the `tag.gpgSign` / `tag.forceSignAnnotated` failure mode. https://github.com/semantic-release/semantic-release/issues/3065
2. git-tag(1) documentation on `tag.gpgSign` and `tag.forceSignAnnotated` semantics. https://git-scm.com/docs/git-tag
3. "Common termination conditions in Genetic Algorithm" (Educative): plateau detection on consecutive generations as a standard EA stop rule. https://www.educative.io/answers/common-termination-conditions-in-genetic-algorithm
4. "Average Convergence Rate of Evolutionary Algorithms," He & Lin (2015, arXiv 1504.08117). Formalizes generation-over-generation improvement rate as the convergence metric. https://arxiv.org/pdf/1504.08117
5. "Average convergence rate of evolutionary algorithms in continuous optimization" (Information Sciences, ScienceDirect). Same framework in continuous domains. https://www.sciencedirect.com/science/article/pii/S0020025520312421
6. "LLM-as-a-Judge Simply Explained" (Confident AI): pointwise LLM scoring drifts; rubric calibration is partial; absolute thresholds on pointwise scores are unreliable. https://www.confident-ai.com/blog/why-llm-as-a-judge-is-the-best-llm-evaluation-method
7. "LLM-as-a-judge: a complete guide" (Evidently AI): inter-rater drift ceilings for LLM judges against human raters. https://www.evidentlyai.com/llm-guide/llm-as-a-judge
