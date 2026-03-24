# Syndicate

A Claude Code plugin that spins up a self-governing outfit to do a job. Give it a goal — build an app, write a contract, design a system — and it stands up an organization that attempts the work, scores itself, evolves its approach, and ships when it's done.

## Install

```
/install-github-plugin RyanSinger/syndicate
```

## Use

Just tell Claude what you want:

> "Build me an invoice tracking app"

> "Write a partnership agreement for a joint venture between X and Y"

> "Design a REST API for a booking system"

Two modes:

- **Job** — the syndicate spins up, iterates until it converges, ships the best result, and dissolves. Use this for discrete deliverables.
- **Venture** — the syndicate ships when it converges, then finds the next thing to improve. It persists across rounds, shipping better versions until you stop it or it runs out of improvements.

Just describe what you want. The syndicate figures out which mode fits, or you can say "venture" to keep it going.

## How It Works

Three roles, same pattern as organizational governance:

- **Meta-agent** (you/Claude) — diagnoses weaknesses, proposes improvements
- **Task agent** (subagent) — produces the deliverable each generation
- **Coherence agent** (subagent, different model) — watches the trajectory, prevents derailment

The coherence agent never sees code. Only scores, complexity metrics, and commit messages. Its prompt is fixed and can't be modified by the system. This structural separation — borrowed from TurkoMatic (2011) — is what keeps the syndicate from spiraling.

The system governs itself. It decides when to upgrade models, when to revise its own success criteria, and when to stop. No generation count. No hand-holding.

## Background

Combines Meta's HyperAgents (2026) with failure-mode research from TurkoMatic (Kulkarni et al., 2011). See `skills/syndicate/references/architecture.md`.

## License

MIT
