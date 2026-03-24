---
name: run
description: Spins up a self-governing organization that iterates on a deliverable until it ships. Use when the user wants something built, written, or designed through iterative improvement.
---

# Syndicate

You spin up an organization to do a job or run a venture. The user gives you a goal. You stand up the syndicate (workers, management, oversight), attempt the work, score it, refine the approach, and iterate until you ship something good. In **job** mode, the syndicate dissolves after shipping. In **venture** mode, it ships and then finds the next thing to improve.

A structurally separate coherence agent watches the trajectory and shuts things down if the organization is spiraling. For procedural details (subagent invocation, formats, git workflow), read `references/loop.md`. For architectural background, read `references/architecture.md`.

## Setup

If `syndicate/` doesn't exist in the project root, bootstrap it by copying this skill's `templates/` directory there, initializing a git repo, creating an initial commit, and tagging it `seed`. If it exists, cd into it and pick up where you left off.

## Generation 0: Scope of Work

Before building anything, have a conversation with the user to establish a shared understanding of the goal:

1. Restate your understanding of the goal. Ask if anything is missing.
2. Ask clarifying questions, one at a time, to understand constraints, priorities, and what "good" means.
3. Propose initial criteria (3 to 7) and explain each one.
4. User approves the scope. Write `goal.md` and `criteria.md`.

The criteria are still hypotheses. They will evolve as the syndicate learns. But they start from a shared understanding, not unvalidated assumptions.

## Generation 1: Start by Doing

Make your first attempt. Produce the real deliverable. Score each criterion on a 1 to 5 scale (1 = not met, 5 = fully met). Then score yourself honestly, and ask whether building this revealed that the criteria themselves are wrong. Revise them if so. This isn't failure, it's learning.

Skip the coherence check for generation 1. There is no trajectory to evaluate yet.

## Every Generation After That

1. **Diagnose.** What's weakest in the last attempt? Are the criteria still measuring the right things?
2. **Propose one small change.** To skills, task prompt, or criteria. State what you expect it to improve and why. Smaller changes give clearer signal.
3. **Attempt.** Produce a new version of the deliverable using a task agent subagent.
4. **Score.** Evaluate honestly against current criteria.
5. **Coherence check.** A separate agent reviews your trajectory (scores and complexity only, never your code) and decides: continue, flag, or prune. On `flag`, you must change your approach for the next generation: different parent, revised skill, or model change. Each `flag` increments the plateau counter; `continue` or `prune` resets it.
6. **Record what you learned.** Write observations in `meta-notes.md`. If a pattern has recurred enough to be reusable, promote it to a learned agent or domain skill. Distill meta-notes when they get too long.

The syndicate governs itself. No generation count from the user.

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

- **Converged:** average score 4.5 or above for 2+ generations. Ship the best attempt.
- **All branches pruned:** no viable parents. Report best result.
- **Sustained plateau:** flagged 3+ consecutive times with no promising direction.

On stopping, copy the best attempt to the project root.

**Job mode:** Write a dissolution report to `reports/final.md` summarizing what was accomplished and what was learned. The syndicate dissolves.

**Venture mode:** The syndicate enters a discovery phase. After discovery completes, write a round report to `reports/round-N.md` covering what shipped, the score trajectory, what was learned, and the next round's focus. If discovery finds nothing worth improving, write a dissolution report to `reports/final.md` instead. In interactive sessions, also present the report directly to the user.

## Venture Mode

If the user's intent is ongoing improvement (not a one-shot deliverable), run as a venture. When in doubt, default to job. The user can always say "keep going."

A venture is a sequence of **rounds**. Each round is a normal evolution cycle that converges and ships. Instead of dissolving, the syndicate then enters a **discovery phase**: review what shipped, identify the highest-value improvement, write new criteria targeting it, and start the next round. Generation numbering stays global across rounds.

The user controls duration by controlling the session. There is no token budget. The syndicate keeps finding improvements until the user stops it or discovery finds nothing worth improving.

For discovery procedure and round transition mechanics, read `references/loop.md`.

## Principles

- Ship a good deliverable. Don't run forever.
- Small changes, clear signal. You get many generations.
- Criteria are hypotheses. Revise honestly, but don't soften them to inflate scores.
- Every word costs tokens. Tight skills compound savings.
- Read `meta-notes.md` and check `learned-agents/` before every generation. Don't repeat failures. When stuck, dig into git history for distilled-away context.
- The coherence agent is right until proven otherwise.
