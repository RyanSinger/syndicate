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

The syndicate spins up a `syndicate/` workspace, makes its first attempt, scores its own work, evolves its approach, and iterates until it converges. Then it ships the best result and dissolves.

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
