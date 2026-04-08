# Variant 1-a Summary

Surgical edits to SKILL.md and loop.md that default learned-agent and domain-skill promotion to user level (~/.claude/agents/, ~/.claude/skills/) with a new ~/.claude/syndicate-manifest.jsonl for provenance, a Gen 0 discovery pass, and an explicit collision-falls-back-to-project policy.

## Self-Scored Checklist

1. Cross-project promotion works end-to-end (user-level install, provenance, discoverable by fresh runs): 5
   User-level default is set for both agents and skills. User manifest schema is defined with source_run, source_project, promoted_at, last_revised, description, collision, fallback_scope, retired. Gen 0 discovery procedure reads the manifest and indexes non-retired entries for the meta-agent. Claude Code's own auto-discovery makes the artifacts loadable with no path manipulation. Full round trip is specified.

2. Research-grounded (cite specific 2023-2026 sources): 5
   rationale.md cites Claude Code skills docs (2025), Voyager (Wang et al. 2023, arXiv:2305.16291), Reflexion and ExpeL via a 2024-2025 memory-mechanisms survey, and the 2025 ACM TOIS survey on LLM agent memory. Voyager is cited inline in loop.md's Discovery section so the justification lives with the rule.

3. Plugin still works (bootstrap, task/coherence agent invocation, worktree flow, squash-merge, metrics): 5
   Bootstrap gains one step (discovery pass). Task and coherence agent invocation is unchanged. Worktree dispatch, squash-merge, branches.jsonl, scores.jsonl, complexity.jsonl, and coherence-log.jsonl are all untouched. plugin/agents/coherence.md and plugin/agents/task.md are not modified. Project-level fallback keeps pre-existing project learned-agents working without migration.

4. Net improvement over current plugin (addresses real weaknesses): 5
   The current plugin has a genuine weakness: learnings die with the run or at best stay in-project. This variant converts the syndicate into a lifelong-learning system with cross-run accumulation, which is the exact property Voyager showed drives compounding capability. Provenance, lifecycle, and collision handling are all defined so the feature is safe to ship.

5. Token-disciplined (SKILL.md + loop.md don't bloat gratuitously; coherence firewall integrity preserved): 4
   SKILL.md grew by about 2 lines (131 to 133). loop.md grew by about 50 lines, most of which is the new Discovery section, the user manifest schema, and the collision policy, each of which is load-bearing and has no shorter form. The discovery gate caps per-generation token load by loading full artifact contents only on trigger match. Coherence firewall is fully preserved: plugin/agents/coherence.md untouched, zero tool access untouched, metrics-only view untouched. I scored 4 not 5 because loop.md is noticeably longer; a more aggressive copy editor could probably shave 10 to 15 lines without losing information.
