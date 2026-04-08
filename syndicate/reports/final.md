# Dissolution Report

## Outcome
Improved the syndicate plugin across six generations: user-level cross-project promotion with collision policy and lazy-load discovery, ~10% token reduction on files loaded every generation, three real bootstrap bugs fixed via live dry-run validation, convergence-threshold dual-clause tuning, mutation-operator taxonomy, and empirical discovery ranking formula. Coherence firewall preserved throughout.

## Stopping Reason
Converged. Gens 4, 5, and 6 all scored >= 4.8 in convergence phase (gen 5 was flagged on a bloat regression, cleanly reverted, and the net state held at gen-4's 5.0). Gen 6's consolidation confirmed all landmarks present and no regressions.

## Rounds Summary
Single round, job mode, 6 generations, 14 variant attempts (3 per gen 1-3, 1 per gen 4-6), 3 worktree dispatches in gen 3 re-run after the initial dispatch hit the upstream worktree isolation bug.

## Score Trajectory
| Gen | Phase | Avg | Winner | Notes |
|-----|-------|-----|--------|-------|
| 1 | exploration | 4.20 | 1-a promotion plumbing | 3 variants: narrow / broad / architectural |
| 2 | exploration | 4.67 | 2-c token tightening | 3 variants: scoring / capital / prose-tightening; losers banked |
| 3 | exploration | 4.83 | 3-b live validation | 3 variants: integrate / validate / novel; first dispatch hit worktree isolation bug, re-dispatched with baseline-sync workaround |
| 4 | convergence (transition) | 5.00 | 4-a integration | Integrated gen-3-a's mutation operators + empirical ranking directly |
| 5 | convergence | 4.83 | 5-a (flagged) | Added reward-hacking audit; coherence flagged bloat; reverted |
| 6 | convergence | 5.00 | 6-a consolidation | Meta-notes distilled, landmarks verified, no plugin edits |

## What Was Learned
- **Empirical validation beats speculative machinery.** Gen 3-b's live dry-run found the gpgSign `git tag` bug that bit this very session at bootstrap, two other real bugs, and tuned the convergence threshold with citations. It outscored variants that were more research-heavy but didn't run the thing.
- **Token discipline compounds durably.** Gen 2-c's editorial pass was the most durable single change because it shrank files loaded every generation forever. Cost-free improvements at compounding levels are gold; match the fix to where the cost actually lives.
- **Coherence firewall works.** Gen 5's bloat-for-no-gain was correctly flagged even though the content (a reward-hacking warning) was well-intentioned. Respecting the flag and reverting was the right move; the Principles section already covered the point.
- **Bank pruned-but-good ideas, integrate later.** Gen 1-b and Gen 2-a lost to narrower variants but their research (mutation operators, empirical ranking, pairwise scoring) was banked and integrated in Gen 4. The ratchet drives broadening; the bank holds what broadening surfaces.
- **Upstream bugs require documented workarounds.** The `isolation: "worktree"` forks-from-main bug (anthropics/claude-code#45371) was filed and a mandatory baseline-sync procedure was baked into loop.md so every future run handles it until the fix lands.
- **Match variant scope to exploration phase.** Gen 1 went wide across conceptual axes (narrow/broad/architectural); Gen 2 across different weaknesses (scoring/capital/tokens); Gen 3 across orthogonal strategies (integrate/validate/novel). Diversity of approach is what the firewall is actually checking for.

## Deliverable
Changes landed on `syndicate/run-1`:
- **plugin/skills/run/SKILL.md** (+~130 words for mutation operators bullet; +10% tightening from gen-2-c; net 1637 words)
- **plugin/skills/run/references/loop.md** (Promotion Scope / Collision Policy / Discovery at Gen 0 / Mutation Operators / Ranking Formula sections; bootstrap gpgSign fix; discovery empty-manifest fix; mandatory baseline-sync workaround section with anthropics/claude-code#45371 reference; convergence dual-clause tuning)
- **plugin/agents/task.md** (tightened by gen-2-c)
- **plugin/agents/coherence.md** (unchanged — firewall invariant preserved)
- **.gitignore** (adds `.scratch/`)

Scratch validation artifacts (gen-3-b's `.scratch/run1/`, `.scratch/run2/`) were cleaned up before commit.

## Upstream Issue Filed
[anthropics/claude-code#45371](https://github.com/anthropics/claude-code/issues/45371) — Agent tool isolation:"worktree" forks from default branch instead of caller's current HEAD.
