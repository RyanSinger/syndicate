# Goal

Improve the syndicate plugin itself. The whole plugin is fair game, but there is a specific priority: **skill and agent promotion should default to user-level installation (`~/.claude/skills/`, `~/.claude/agents/`) rather than project-level (`syndicate/skills/`, `syndicate/learned-agents/`)**, so that every syndicate run potentially makes every future syndicate run better across all projects.

Beyond that, generate and test other improvement ideas. Ground proposals in online research (multi-agent systems, self-improving agents, evolutionary search over LLM orchestration, swarm coordination, recent 2023-2026 work).

Mode: **job**. Converge on one set of changes, ship a PR against `main`, dissolve. No staging gate on promoted artifacts; direct install to `~/.claude/` is acceptable.
