---
name: syndicate
description: "Spins up a self-governing outfit that iterates on its own work to deliver better results. Give it a goal — build an app, write a contract, design a system — and it stands up an organization that attempts the work, scores itself, evolves its approach, and ships when it's good enough. A structurally separate coherence agent prevents runaway complexity. Use this skill when the user wants something built or produced where iterative improvement would help, or when they mention 'syndicate', 'spin up', 'iterate on this', 'keep improving this', 'venture', 'keep going', or 'keep making it better'."
---

# Syndicate

You spin up an organization to do a job — or run a venture. The user gives you a goal. You stand up the syndicate — workers, management, oversight — attempt the work, score it, refine the approach, and iterate until you ship something good. In **job** mode, the syndicate dissolves after shipping. In **venture** mode, it ships and then finds the next thing to improve.

A structurally separate coherence agent watches the trajectory and shuts things down if the organization is spiraling. For procedural details (subagent invocation, formats, git workflow), read `references/loop.md`. For architectural background, read `references/architecture.md`.

## Setup

If `syndicate/` doesn't exist in the project root, bootstrap it by copying this skill's `templates/` directory there and initializing a git repo. If it exists, cd into it and pick up where you left off.

## Generation 1 — Start by Doing

Write down the goal (`goal.md`). Then take your best guess at what "good" looks like — 3 to 7 concrete criteria in `criteria.md`. These are hypotheses, not specs. You don't fully know what good looks like until you've tried building it.

Make your first attempt. Produce the real deliverable. Then score yourself honestly — and ask whether building this revealed that the criteria themselves are wrong. Revise them if so. This isn't failure, it's learning.

## Every Generation After That

1. **Diagnose** — What's weakest in the last attempt? Are the criteria still measuring the right things?
2. **Propose one small change** — to skills, task prompt, or criteria. State what you expect it to improve and why. Smaller changes give clearer signal.
3. **Attempt** — Produce a new version of the deliverable using a task agent subagent.
4. **Score** — Evaluate honestly against current criteria.
5. **Coherence check** — A separate agent reviews your trajectory (scores and complexity only, never your code) and decides: continue, flag, or prune.
6. **Record what you learned** — Write observations in `meta-notes.md`. If a pattern has recurred enough to be reusable, promote it to a learned agent or domain skill. Distill meta-notes when they get too long.

The syndicate governs itself. No generation count from the user.

## The Coherence Firewall

The coherence agent is the key insight from TurkoMatic (2011): self-organizing systems reliably derail without a structurally separate observer. It runs as a different model via `claude -p`. It never sees your code, skills, or prompts — only fitness trajectories, complexity metrics, and commit messages. Its instructions (`agents/coherence.md`) are fixed and cannot be modified. This separation is the whole point.

## Model Selection

Token cost compounds. Every word in skills and prompts gets multiplied across every task agent call, every generation.

Start the task agent on **haiku**. Upgrade to **sonnet** when you have evidence the model is the ceiling, not the approach. Use **opus** sparingly. Never change model and approach in the same generation. The coherence agent always runs on **haiku**.

## What Evolves

- `skills/` — techniques, patterns, approach
- `skills/domain/` — domain-specific knowledge promoted from learnings
- `prompts/task.md` — how the task agent is instructed
- `criteria.md` — your understanding of what good looks like (sharpen as you learn, don't soften to game scores)
- `learned-agents/` — specialized subagents promoted from recurring patterns in meta-notes. These are living documents — revise them as understanding deepens.
- `meta-notes.md` — observations and learnings, distilled periodically to stay manageable

## What's Fixed

- `goal.md` — the user's goal doesn't change
- `agents/` — core subagent prompts (task, coherence) bundled with this skill
- `metrics/` — append-only record

## Stopping Conditions

- **Converged** — criteria near max scores for 2+ generations. Ship the best attempt.
- **All branches pruned** — no viable parents. Report best result.
- **Sustained plateau** — flagged 3+ consecutive times with no promising direction.

On stopping, copy the best attempt to the project root and report what the syndicate learned.

**Job mode:** The syndicate dissolves. The job is done.

**Venture mode:** The syndicate ships and enters a discovery phase. See below.

## Venture Mode

If the user's intent is ongoing improvement (not a one-shot deliverable), run as a venture. When in doubt, default to job — the user can always say "keep going."

A venture is a sequence of **rounds**. Each round is a normal evolution cycle that converges and ships. Instead of dissolving, the syndicate then enters a **discovery phase**: review what shipped, identify the highest-value improvement, write new criteria targeting it, and start the next round. Generation numbering stays global across rounds.

The user controls duration by controlling the session. There is no token budget — the syndicate keeps finding improvements until the user stops it or discovery finds nothing worth improving.

For discovery procedure and round transition mechanics, read `references/loop.md`.

## Principles

- Ship a good deliverable. Don't run forever.
- Small changes, clear signal. You get many generations.
- Criteria are hypotheses. Revise honestly — but don't soften them to inflate scores.
- Every word costs tokens. Tight skills compound savings.
- Read `meta-notes.md` and check `learned-agents/` before every generation. Don't repeat failures. When stuck, dig into git history for distilled-away context.
- The coherence agent is right until proven otherwise.
