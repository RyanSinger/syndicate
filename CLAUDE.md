# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Syndicate is a Claude Code plugin (installed via `/plugin marketplace add RyanSinger/syndicate`). It spins up a self-governing organization of agents to iteratively produce a deliverable. The user provides a goal; the syndicate attempts, scores, evolves its approach, and ships.

Two modes: **job** (converge and dissolve) and **venture** (converge, ship, discover next improvement, repeat).

## Architecture: Three-Tier Governance

The core design borrows structural separation from TurkoMatic (2011) to prevent derailment:

- **Meta-agent** (the main Claude session): diagnoses weaknesses, modifies skills/prompts/criteria, promotes learnings to agents or domain skills
- **Task agent** (subagent via `claude -p`): produces the deliverable each generation. Starts on haiku, upgrades only with evidence
- **Coherence agent** (subagent via `claude -p`, always haiku): watches fitness trajectories and complexity metrics only. Never sees code, prompts, or skills. Its prompt (`agents/coherence.md`) is fixed and must not be modified

The syndicate communicates with the user at defined moments: scope of work before gen 1, round boundary reports after each discovery phase, and a dissolution report on stopping. Mid-round, it runs autonomously.

The coherence firewall is the key architectural invariant. Without it, the system reliably derails into complexity spirals.

## Plugin Structure

- `skills/syndicate/SKILL.md`: Main skill entry point (the syndicate loop definition)
- `skills/syndicate/agents/`: Fixed subagent prompts (task.md, coherence.md). These ship with the plugin and do not evolve
- `skills/syndicate/references/`: architecture.md (design rationale), loop.md (procedural details for subagent invocation, metrics formats, git workflow, discovery phase)
- `skills/syndicate/templates/`: Bootstrapped into `syndicate/` in the user's project root when a syndicate starts. Contains initial skills, prompts, meta-notes, and empty directories for attempts/metrics/archive
- `.claude-plugin/plugin.json`: Plugin manifest

## Key Conventions

- Subagents are invoked with `CLAUDECODE= claude -p "..."` (stripping env var enables nesting)
- Metrics files (`scores.jsonl`, `complexity.jsonl`, `coherence-log.jsonl`) are append-only JSONL in `syndicate/metrics/`
- Branch records (`branches.jsonl`) are append-only JSONL in `syndicate/archive/`
- Each generation gets its own git branch (`gen-N`), branched from the best-scoring non-pruned parent
- Token efficiency is critical: every word in skills/prompts compounds across every task agent call and generation
- `skills-manifest.jsonl` tracks provenance for domain skills (both imported from plugins and locally promoted)
- `learned-agents/registry.jsonl` tracks lifecycle of promoted agents

## What Evolves vs. What's Fixed

Evolves: `syndicate/skills/`, `syndicate/prompts/task.md`, `syndicate/criteria.md`, `syndicate/learned-agents/`, `syndicate/meta-notes.md`

Fixed: `syndicate/goal.md` (set once), `skills/syndicate/agents/` (bundled with plugin), `syndicate/metrics/` (append-only), `syndicate/reports/` (written at round boundaries and dissolution)
