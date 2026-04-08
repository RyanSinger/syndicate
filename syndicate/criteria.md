# Criteria

Each scored 1 (not met) to 5 (fully met). Criteria are hypotheses and may be ratcheted during exploration.

## 1. Cross-project promotion works end-to-end
Promoted skills/agents land in `~/.claude/skills/` or `~/.claude/agents/` with provenance tracked (manifest entries, source run, rationale). A fresh syndicate run in a different project can discover and use them. Demonstrated by an actual dry-run or test invocation, not just "the code exists."

## 2. Research-grounded
Non-trivial proposals cite specific sources (papers, repos, blog posts, 2023-2026) from the multi-agent / self-improving agent / LLM orchestration literature. Each change traces to a source or an explicit rationale for departing from one. No vibes-only design.

## 3. Plugin still works
Bootstrapping, Gen 0 scope conversation, task and coherence subagent invocation, worktree workflow, squash-merge, metrics logging all still function. Regression-verified by running the modified plugin on a toy goal in a scratch directory (or equivalent test).

## 4. Net improvement over current plugin
Changes address real weaknesses beyond the promotion feature alone. Weaknesses identified from reading current `meta-notes.md`, `loop.md`, `architecture.md`, prior run history, and research. Each change states what it improves and the mechanism.

## 5. Token-disciplined
Skills and prompts do not bloat gratuitously. Net word-count delta on `plugin/skills/run/SKILL.md` + `plugin/skills/run/references/loop.md` is tracked; large additions must earn their keep with clear value. Coherence firewall integrity preserved: no code, skills, or prompts leak into the coherence agent's context.
