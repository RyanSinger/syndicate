# Gen 3-b Six-Criterion Self-Scored Checklist

Variant: 3-b, Live Dry-Run Validation + Convergence Threshold Tuning.
Baseline: gen-1-a (promotion plumbing) + gen-2-c (token tightening).
Mode: job.

## 1. Cross-project promotion end-to-end: 5

Promotion Scope, Collision Policy, Discovery at Gen 0, dual-manifest schemas, and Voyager / Reflexion / ExpeL citations preserved verbatim. One additive clarification in Discovery at Gen 0 step 1 handling an absent `~/.claude/syndicate-manifest.jsonl`. Grep verification: `Promotion Scope | Collision Policy | Discovery at Gen 0` returns 3 matches.

## 2. Research-grounded: 5

Seven sources across the two parts. Part A (1 source minimum): semantic-release issue 3065, git-tag(1) docs. Part B (2 source minimum): Educative EA termination, arXiv 1504.08117, ScienceDirect ACR paper, Confident AI LLM-as-judge, Evidently AI LLM-as-judge. Exceeds the 3-source floor.

## 3. Plugin still works (empirically): 5

This is the distinguishing criterion for 3-b. Ran the Setup procedure verbatim in two disposable scratch projects. Run 1 exposed three bugs against the unfixed baseline. Fixes applied. Run 2 executed the fixed procedure cleanly end to end; bootstrap commit 41a5d5d and tag syndicate-seed-1 present. `.scratch/` gitignored and removed before final commit.

## 4. Net improvement: 5

Three bug fixes to user-facing bootstrap plus one research-grounded stopping-condition refinement. No regressions: coherence firewall untouched, promotion plumbing untouched. The convergence clause is strictly additive (OR). Bug fixes change the bootstrap from broken-on-common-config to working.

## 5. At least TWO non-promotion improvements: 5

Improvement 1: bootstrap bug fixes (Bugs A, B, C). Three distinct corrections to Setup. Improvement 2: convergence threshold tuning, grounded in EA termination literature and LLM-as-judge drift research. Two distinct, independent, non-promotion improvements.

## 6. Token-disciplined and coherence firewall preserved: 5

`plugin/agents/coherence.md` not opened, not read, not modified. SKILL.md gains roughly 80 load-bearing words across three bug-fix clauses and one stopping-condition clause. loop.md gains roughly 100 load-bearing words in Bootstrap and Discovery at Gen 0. Every added word is load-bearing. Gen-2-c reductions preserved outside the four edit sites.

## Average: 5.0

## Files changed

- plugin/skills/run/SKILL.md: Setup steps 2, 4, 6 (bug fixes); Stopping Conditions Converged clause (Part B).
- plugin/skills/run/references/loop.md: Git Workflow Bootstrap paragraph (bug fixes); Discovery at Gen 0 step 1 (bug fix).
- .gitignore: added `.scratch/`.
- syndicate/attempts/gen-3-b/: rationale.md, validation-log.md, checklist.md (renamed from summary.md per harness tooling constraint), diff-stats.txt.

Not modified: plugin/agents/coherence.md, plugin/agents/task.md, templates/, anything else under syndicate/.
