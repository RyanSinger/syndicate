---
name: run
description: Spins up a self-governing organization that iterates on a deliverable until it ships. Use when the user wants something built, written, or designed through iterative improvement.
---

# Syndicate

You spin up an organization to do a job or run a venture. The user gives you a goal. You stand up the syndicate (workers, management, oversight), attempt the work, score it, refine the approach, and iterate until you ship something good. In **job** mode, the syndicate dissolves after shipping. In **venture** mode, it ships and then finds the next thing to improve.

A structurally separate coherence agent watches the trajectory and shuts things down if the organization is spiraling. For procedural details (subagent invocation, formats, git workflow), read `references/loop.md`. For architectural background, read `references/architecture.md`.

## Setup

If `syndicate/` doesn't exist in the project root, bootstrap it:

1. Copy this skill's `templates/` directory to `syndicate/` in the project root.
2. Detect the PR target branch (`git symbolic-ref refs/remotes/origin/HEAD`, fall back to `main`). If no remote exists, record `none`. Write the result to `syndicate/.pr-target`.
3. Create a branch `syndicate/run-<N>` off the current HEAD (N increments if prior runs exist in the branch namespace).
4. Commit the `syndicate/` directory on that branch.
5. Tag it `syndicate-seed-<N>` (local only).

If `syndicate/` exists, you are resuming. Check out the existing `syndicate/run-<N>` branch and pick up where you left off.

## Generation 0: Scope of Work

Before building anything, have a conversation with the user to establish a shared understanding of the goal:

1. Restate your understanding of the goal. Ask if anything is missing.
2. Ask clarifying questions, one at a time, to understand constraints, priorities, and what "good" means.
3. Propose initial criteria (3 to 7) and explain each one.
4. User approves the scope. Write `goal.md` and `criteria.md`.

The criteria are still hypotheses. They will evolve as the syndicate learns. But they start from a shared understanding, not unvalidated assumptions.

## Generation 1: Start by Doing

You are in the **exploration phase**. Convergence is structurally impossible until you transition out.

Make your first attempt. Produce the real deliverable with 2+ parallel variants, each taking a meaningfully different approach. Score each criterion on a 1 to 5 scale (1 = not met, 5 = fully met). Score honestly, and ask whether building this revealed that the criteria themselves are wrong.

After scoring, perform the **criteria ratchet**: do exactly one of (a) add a criterion the best variant doesn't already satisfy at 5, (b) split a vague criterion into sharper ones, or (c) raise the bar on an existing criterion. You may also prune criteria that stop making sense; pruning doesn't substitute for the ratchet. Document ratchet and pruning actions in meta-notes.

Skip the coherence check for generation 1. There is no trajectory to evaluate yet.

## Every Generation After That

1. **Diagnose.** What's weakest in the last attempt? Are the criteria still measuring the right things?
2. **Propose changes.** During exploration: 2+ variants, each taking a meaningfully different approach. During convergence: 1 to N based on confidence. State what each change is expected to improve and why.
3. **Attempt all in parallel.** Each proposed change gets its own task agent running in a separate git worktree (`isolation: "worktree"`). All run simultaneously as background agents. Each variant writes to its own output directory (`attempts/gen-N-a/`, `gen-N-b/`, etc.).
4. **Score all.** Evaluate each variant honestly against current criteria. Record the winning variant's score in `scores.jsonl` (include `phase` and `ratchet` fields). Record all variants in `branches.jsonl`.
5. **Ratchet (exploration only).** After scoring, perform exactly one of: (a) add a criterion the best variant doesn't already satisfy at 5, (b) split a vague criterion into sharper ones, (c) raise the bar on an existing criterion. You may also prune criteria that stop making sense; pruning doesn't substitute for the ratchet. Document ratchet and pruning actions in meta-notes.
6. **Coherence check on batch.** A separate agent reviews the batch: all variant scores, the spread, complexity growth, and the provisional winner's diff stats. Include the current phase and ratchet action in the coherence prompt. It decides: continue, flag, or prune. On `flag`, you must change your approach. Each `flag` increments the plateau counter; `continue` or `prune` resets it. On `prune`, all variants are pruned and the next generation branches from the previous winner.
7. **Squash-merge best, clean up rest.** Squash-merge the winning variant onto `syndicate/run-<N>` as a single commit: `gen-<G>: <one sentence>`. Mark other variants pruned in `branches.jsonl`. Force-remove all variant worktrees and delete their branches immediately.
8. **Record what you learned.** Write observations in `meta-notes.md`. Note what was tried in parallel, what worked, what didn't. If a pattern has recurred enough to be reusable, promote it to a learned agent or domain skill. Distill meta-notes when they get too long.

The syndicate governs itself. No generation count from the user.

During exploration, go wide: always 2+ variants with genuinely different approaches. During convergence, go narrow when confident (1 to 2 variants) or wide when stuck (3 to 4). All variants in a generation use the same model.

## Phase Transition

The syndicate starts in **exploration phase** and must explicitly transition to **convergence phase** before convergence stopping conditions apply.

**Eligibility:** at least 3 exploration generations complete, and at least 2 genuinely different approaches tried across variants (not just parameter tweaks).

**To transition**, write a transition rationale to meta-notes:
- What approaches were explored and how they compared
- Why the current best approach won (with evidence from variant scores)
- What the exploration surfaced that wouldn't have been obvious upfront

Pass the transition rationale summary to the coherence agent in the next invocation. It can flag a thin rationale. During convergence, the criteria ratchet is optional, criteria cannot be softened but can be pruned with justification.

## The Coherence Firewall

The coherence agent is the key insight from TurkoMatic (2011): self-organizing systems reliably derail without a structurally separate observer. It runs as a native subagent with zero tool access. It never sees your code, skills, or prompts. Only fitness trajectories, complexity metrics, and commit messages. Its instructions (`agents/coherence.md`) are fixed and cannot be modified. This separation is the whole point.

## Model Selection

A wasted generation costs more than a better model. Start strong, downgrade with evidence.

Start the task agent on **opus**. Downgrade to **sonnet** if evidence shows the task is simple enough (scores near max on first attempt, straightforward deliverable). Never change model and approach in the same generation. The coherence agent always runs on **sonnet**. Learned agents default to **sonnet**.

## What Evolves

- `skills/`: techniques, patterns, approach
- `skills/domain/`: domain-specific knowledge (promoted from learnings or imported from installed plugins)
- `skills-manifest.jsonl`: provenance and lifecycle tracking for domain skills
- `prompts/task.md`: how the task agent is instructed
- `criteria.md`: your understanding of what good looks like (sharpen as you learn, don't soften to game scores)
- `learned-agents/`: specialized subagents promoted from recurring patterns in meta-notes. These are living documents. Revise them as understanding deepens.
- `meta-notes.md`: observations and learnings, distilled periodically to stay manageable

## What's Fixed

- `goal.md`: the user's goal doesn't change
- `agents/`: core subagent prompts (task, coherence) bundled with this skill
- `metrics/`: append-only record
- `venture.jsonl` (venture mode only, distilled periodically like meta-notes. Git preserves full history)
- `reports/`: round boundary reports and dissolution report

## Stopping Conditions

- **Converged:** average score 4.8 or above for 2+ consecutive generations, and the syndicate is in convergence phase. Cannot trigger during exploration.
- **All branches pruned:** no viable parents. Report best result. Either phase.
- **Sustained plateau:** flagged 3+ consecutive times. Either phase. During exploration, this means variants aren't producing useful diversity. During convergence, refinement has stalled.

On stopping, copy the best attempt to the project root. Commit the final state on `syndicate/run-<N>`. Read `syndicate/.pr-target`: if it is not `none`, push the branch and open a PR targeting that branch. The PR description includes the goal, final scores, generation count, and path to the dissolution or round report. If no remote exists, tell the user which branch contains the deliverable.

**Job mode:** Write a dissolution report to `reports/final.md` summarizing what was accomplished and what was learned. The syndicate dissolves.

**Venture mode:** The syndicate enters a discovery phase. After discovery completes, write a round report to `reports/round-N.md` covering what shipped, the score trajectory, what was learned, and the next round's focus. If discovery finds nothing worth improving, write a dissolution report to `reports/final.md` instead. In interactive sessions, also present the report directly to the user.

## Venture Mode

If the user's intent is ongoing improvement (not a one-shot deliverable), run as a venture. When in doubt, default to job. The user can always say "keep going."

A venture is a sequence of **rounds**. Each round is a normal evolution cycle that converges and ships. Each new round starts back in exploration phase, so the full diverge-then-converge cycle repeats. Instead of dissolving, the syndicate then enters a **discovery phase**: review what shipped, identify the highest-value improvement, write new criteria targeting it, and start the next round. Generation numbering stays global across rounds.

The user controls duration by controlling the session. There is no token budget. The syndicate keeps finding improvements until the user stops it or discovery finds nothing worth improving.

For discovery procedure and round transition mechanics, read `references/loop.md`.

## Principles

- Ship a good deliverable. Don't run forever.
- Explore before you converge. Early generations are for discovery, not optimization.
- Small changes, clear signal. You get many generations.
- Criteria are hypotheses. Revise honestly, but don't soften them to inflate scores.
- Every word costs tokens. Tight skills compound savings.
- Read `meta-notes.md` and check `learned-agents/` before every generation. Don't repeat failures. When stuck, dig into git history for distilled-away context.
- The coherence agent is right until proven otherwise.
