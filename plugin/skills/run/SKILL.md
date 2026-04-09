---
name: run
description: Spins up a self-governing organization that iterates on a deliverable until it ships. Use when the user wants something built, written, or designed through iterative improvement.
---

# Syndicate

You stand up an organization (workers, management, oversight) to do a job or run a venture. The user gives you a goal. You attempt the work, score it, refine, and iterate until you ship. In **job** mode, the syndicate dissolves after shipping. In **venture** mode, it ships, then finds the next thing to improve.

A structurally separate coherence agent watches the trajectory and shuts things down if the organization is spiraling. For procedural details (subagent invocation, formats, git workflow), read `references/loop.md`. For architectural background, read `references/architecture.md`.

## Setup

If `syndicate/` doesn't exist in the project root, bootstrap it:

1. Copy `templates/` to `syndicate/` in the project root. Ensure `syndicate/baseline-sync.sh` is executable (`chmod +x`).
2. Detect the PR target branch: if no remote, write `none`; else try `git symbolic-ref refs/remotes/origin/HEAD` and on any failure fall back to `main`. Write to `syndicate/.pr-target`.
3. Create `syndicate/run-<N>` off HEAD (N increments past prior runs).
4. Run the discovery pass (see `references/loop.md` "Discovery at Gen 0") to index agents and skills into `syndicate/discovered.jsonl`:
   - Read `~/.claude/syndicate-manifest.jsonl` for syndicate-promoted artifacts (`"origin": "syndicate"`). If the file does not exist (first-ever run on this machine), skip this source.
   - Scan the system reminder's skill list for installed plugin skills. Write each with `"origin": "installed-plugin"`, `"kind": "skill"`, name, and description.
   - If neither source yields entries, write an empty `discovered.jsonl` and continue.
5. Commit `syndicate/` on that branch.
6. Tag it locally as an annotated tag, overriding any user signing config: `git -c tag.gpgSign=false tag -a syndicate-seed-<N> -m "syndicate seed <N>"`. Do not push.

If `syndicate/` exists, you are resuming. Check out the existing `syndicate/run-<N>` branch and pick up where you left off.

## Generation 0: Scope of Work

Before building, establish a shared understanding of the goal with the user:

1. Restate your understanding. Ask if anything is missing.
2. Ask clarifying questions one at a time about constraints, priorities, and what "good" means.
3. Propose 3 to 7 initial criteria with brief rationale.
4. On approval, write `goal.md` and `criteria.md`.

Criteria are still hypotheses. They will evolve as the syndicate learns, but they start from shared understanding, not unvalidated assumptions.

## Generation 1: Start by Doing

You are in the **exploration phase**. Convergence is structurally impossible until you transition out.

Make the first attempt with 2+ parallel variants taking meaningfully different approaches. Score each criterion 1 to 5 (1 = not met, 5 = fully met). Score honestly, and ask whether building this revealed that the criteria themselves are wrong.

After scoring, perform the **criteria ratchet** (step 5 below). Document ratchet and pruning in meta-notes. Skip the coherence check for gen 1: no trajectory yet.

## Every Generation After That

1. **Diagnose.** What's weakest in the last attempt? Are the criteria still measuring the right things?
2. **Propose changes.** Exploration: 2+ variants, each a meaningfully different approach. Convergence: 1 to N based on confidence. State what each change is expected to improve and why.
   Each variant declares one mutation operator from {rewrite, constrain, decompose, invert, borrow}. Same-operator collisions in one generation do not count as diversity. See `references/loop.md` "Mutation Operators".
3. **Attempt all in parallel.** Each variant gets its own task agent in a separate worktree (`isolation: "worktree"`), running simultaneously as a background agent. Each writes to its own output directory (`attempts/gen-N-a/`, `gen-N-b/`, ...).
4. **Score all.** Evaluate every variant honestly. Append the winner to `scores.jsonl` (with `phase` and `ratchet`). Append all variants to `branches.jsonl`.
5. **Ratchet (exploration only).** Do exactly one of: (a) add a criterion the best variant doesn't already satisfy at 5, (b) split a vague criterion into sharper ones, (c) raise the bar on an existing criterion. You may also prune criteria that stopped making sense; pruning does not substitute for the ratchet. Document in meta-notes.
6. **Coherence check on batch.** A separate agent reviews the full batch: variant scores, spread, complexity growth, provisional winner's diff stats, plus current phase and ratchet action. It returns: continue, flag, or prune. On `flag`, change your approach; each `flag` increments the plateau counter. `continue` and `prune` reset it. On `prune`, all variants are pruned and the next generation branches from the previous winner.
7. **Merge best, clean up rest.** After scoring, evaluate whether variants have complementary strengths:
   - **Single winner (default):** One variant dominates across criteria. Squash-merge onto `syndicate/run-<N>` as `gen-<G>: <one sentence>`. Mark others pruned in `branches.jsonl`.
   - **Combine:** Variants excel on different criteria and their file changes don't overlap. Check file-level overlap: run `git diff --name-only` for each variant relative to baseline. If any file appears in more than one variant's diff, fall back to single winner. Otherwise, apply each variant's changes via `git checkout <variant-branch> -- <files>` and commit as `gen-<G>: combined (<variants>): <one sentence>`. Mark contributing variants with `"pruned": false, "combined": true` in `branches.jsonl`. Score the combined result for `scores.jsonl`. Document in meta-notes which variants were combined and which criteria each addressed.
   Force-remove all variant worktrees and delete their branches immediately after merging.
8. **Record what you learned.** Update `meta-notes.md`: what was tried in parallel, what worked, what didn't. If a pattern recurs and is reusable, promote it to a learned agent or domain skill. Distill meta-notes when they get long.
9. **Check phase transition (exploration only).** After 3+ exploration generations, evaluate transition eligibility (see Phase Transition). If not ready, continue.

The syndicate governs itself. No generation count from the user.

Exploration: always 2+ variants with genuinely different approaches. Convergence: narrow when confident (1 to 2), wide when stuck (3 to 4). All variants in a generation use the same model.

## Phase Transition

The syndicate starts in **exploration phase** and must explicitly transition to **convergence phase** before convergence stopping conditions apply.

**Eligibility:** 3+ exploration generations complete and 2+ genuinely different approaches tried (not just parameter tweaks).

**To transition,** write a transition rationale to meta-notes covering:
- What approaches were explored and how they compared
- Why the current best won (with evidence from variant scores)
- What exploration surfaced that wouldn't have been obvious upfront

Pass a one-sentence rationale to the coherence agent on the next invocation. If it flags the rationale as thin, stay in exploration and run at least one more generation before reconsidering. During convergence, the ratchet is optional and criteria cannot be softened (they may still be pruned with justification).

## The Coherence Firewall

The coherence agent is the key insight from TurkoMatic (2011): self-organizing systems reliably derail without a structurally separate observer. It runs as a native subagent with zero tool access. It never sees code, skills, or prompts: only fitness trajectories, complexity metrics, and commit messages. Its instructions (`agents/coherence.md`) are fixed and cannot be modified. This separation is the whole point.

## Model Selection

A wasted generation costs more than a better model. Start strong, downgrade with evidence.

Start the task agent on **opus**. Downgrade to **sonnet** if evidence shows the task is simple (scores near max on first attempt, straightforward deliverable). Never change model and approach in the same generation. The coherence agent always runs on **sonnet**. Learned agents default to **sonnet**.

## What Evolves

- `skills/`: techniques, patterns, approach
- `skills/domain/`: domain-specific knowledge (promoted from learnings or imported from installed plugins)
- `skills-manifest.jsonl`: provenance and lifecycle for project-scoped domain skills
- `prompts/task.md`: how the task agent is instructed
- `criteria.md`: your understanding of "good" (sharpen as you learn; do not soften to game scores)
- `learned-agents/`: project-scoped specialized subagents. Most promotions go to user level (`~/.claude/agents/`) so future runs in any project can reuse them; this directory is the project-specific fallback. Living documents.
- `meta-notes.md`: observations and learnings, distilled periodically

## What's Fixed

- `goal.md`: the user's goal
- `agents/`: core subagent prompts (task, coherence) bundled with this skill
- `metrics/`: append-only record
- `venture.jsonl` (venture mode only, distilled periodically; git preserves full history)
- `reports/`: round and dissolution reports

## Stopping Conditions

- **Converged:** in convergence phase, and either (a) average score 4.8+ for 2+ consecutive generations, or (b) average score 4.5+ and improvement delta under 0.1 for 3+ consecutive generations. Clause (b) is a stagnation-on-good-quality signal, standard in evolutionary algorithms (stop when best fitness has not improved by more than epsilon over T generations). It also hedges against LLM-as-judge pointwise scoring drift, which fluctuates by several points even on top models and can prevent a genuinely-converged run from crossing an absolute threshold. Cannot trigger during exploration.
- **All branches pruned:** no viable parents. Report best result. Either phase.
- **Sustained plateau:** flagged 3+ consecutive times. Either phase. During exploration, variants aren't producing useful diversity. During convergence, refinement has stalled.

On stopping, copy the best attempt to the project root and commit on `syndicate/run-<N>`. Read `syndicate/.pr-target`: if not `none`, push the branch and open a PR targeting it. The PR description includes goal, final scores, generation count, and path to the dissolution or round report. If no remote, tell the user which branch holds the deliverable.

**Job mode:** Write a dissolution report to `reports/final.md` summarizing what was accomplished and learned. The syndicate dissolves.

**Venture mode:** Enter the discovery phase. After it completes, write a round report to `reports/round-N.md` covering what shipped, the score trajectory, what was learned, and the next round's focus. If discovery finds nothing worth improving, write `reports/final.md` instead. In interactive sessions, also present the report directly to the user.

## Venture Mode

If the user's intent is ongoing improvement (not a one-shot deliverable), run as a venture. When in doubt, default to job. The user can always say "keep going."

A venture is a sequence of **rounds**. Each round is a normal evolution cycle that converges and ships. Each new round restarts in exploration phase, so the diverge-then-converge cycle repeats. Instead of dissolving, the syndicate enters a **discovery phase**: review what shipped, identify the highest-value next improvement, write new criteria targeting it, and start the next round. Generation numbering stays global across rounds.

The user controls duration by controlling the session. There is no token budget. The syndicate keeps finding improvements until the user stops it or discovery finds nothing worth improving.

For discovery procedure and round transition mechanics, read `references/loop.md`.

## Principles

- Ship a good deliverable. Don't run forever.
- Explore before you converge. Early generations are for discovery, not optimization.
- Small changes, clear signal. You get many generations.
- Criteria are hypotheses. Revise honestly; never soften to inflate scores.
- Every word costs tokens. Tight skills compound savings across generations.
- Read `meta-notes.md` and check `learned-agents/` before every generation. Don't repeat failures. When stuck, dig into git history for distilled-away context.
- The coherence agent is right until proven otherwise.
