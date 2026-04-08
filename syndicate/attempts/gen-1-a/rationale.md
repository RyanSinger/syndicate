# Variant 1-a: Promotion Plumbing

## Goal

Make promoted learned agents and domain skills default to user-level installation so every syndicate run potentially improves every future syndicate run across all projects. Keep the change surgical and low risk.

## Sources

1. Anthropic, "Extend Claude with skills," Claude Code documentation. https://code.claude.com/docs/en/skills. Confirms user-level skills at `~/.claude/skills/` are available across all projects, each skill in its own directory with a `SKILL.md`, and that when skill names collide across levels the precedence order is enterprise > personal > project. This is the substrate the promotion change relies on.

2. Wang et al., "Voyager: An Open-Ended Embodied Agent with Large Language Models" (2023). https://arxiv.org/abs/2305.16291. The canonical result that a persistent, ever-growing skill library of executable code compounds capability across tasks, alleviates catastrophic forgetting, and enables transfer to novel environments (3.3x more unique items, 15.3x faster milestones, generalizes zero-shot to new Minecraft worlds). Direct justification for cross-run accumulation as the default.

3. Shinn et al., "Reflexion: Language Agents with Verbal Reinforcement Learning" (NeurIPS 2023) and Zhao et al., "ExpeL: LLM Agents Are Experiential Learners" (AAAI 2024), surveyed in "Memory Mechanisms in LLM Agents" (2024-2025). https://www.emergentmind.com/topics/memory-mechanisms-in-llm-based-agents. Both demonstrate cross-task improvement by persisting textual experience across episodes, not just within one trajectory. Reinforces that the accumulation is valuable even when artifacts are prose, not executable code.

4. Supporting background, "A Survey on the Memory Mechanism of Large Language Model-based Agents," ACM TOIS 2025. https://dl.acm.org/doi/10.1145/3748302. Establishes that hierarchical, dynamically managed memory with provenance and lifecycle is the current best practice for lifelong agent systems.

## What I Changed

All edits are in `plugin/`:

1. `plugin/skills/run/references/loop.md`
   - **Learned Agents subsection:** retargeted the default home from `syndicate/learned-agents/<name>.md` to `~/.claude/agents/<name>.md`. Project-level becomes the fallback. Updated the invocation text to say the meta-agent reads both the user manifest and the project registry when choosing candidates.
   - **Promoting Learnings section:** added a "Promotion Scope: User vs Project" subsection that sets user-level as default and defines when to opt out (learning references project-specific paths/names/schemas). Added a "Collision Policy" subsection defining exactly one policy: fall back to project-level install on user-level name collision, record the collision with `"collision": true, "fallback_scope": "project"` in the user manifest, no auto-merge or auto-version. Updated the registry step to append a line to `~/.claude/syndicate-manifest.jsonl` at user level, with a defined JSONL schema that includes kind, name, path, scope, source_run, source_project, promoted_at, last_revised, description, collision, fallback_scope, and retired.
   - **Discovery at Gen 0 section (new, top-level):** procedure for how a fresh run in any project reads `~/.claude/syndicate-manifest.jsonl`, indexes non-retired entries into a per-run ephemeral `syndicate/discovered.jsonl`, keeps names + descriptions in the meta-agent's working context, and loads full artifact contents only when triggers match, matching the existing learned-agent invocation gate. Explicitly notes that Claude Code already auto-discovers user-level artifacts, so the manifest's job is provenance and lifecycle, not path wiring. Notes that unclaimed files in `~/.claude/agents/` are not touched.
   - **Project Structure tree:** added `discovered.jsonl` and reworded `learned-agents/`, `skills/domain/`, and `skills-manifest.jsonl` comments to mark them as project-scoped fallbacks. Added a new block showing the user-level layout at `~/.claude/`.
   - **skills-manifest.jsonl comment:** clarified that it now tracks project-scoped skills only; locally promoted user-level skills live in the user manifest.

2. `plugin/skills/run/SKILL.md`
   - **Setup:** inserted step 4 invoking the Gen 0 discovery pass.
   - **What Evolves:** reworded the `learned-agents/` bullet to say user-level is the default and this directory is the project fallback.

3. `plugin/agents/task.md`: untouched (directive).
4. `plugin/agents/coherence.md`: untouched (architecturally fixed, directive).
5. `syndicate/`: untouched (meta-state for this run, not the plugin).

## Why

The current plugin promotes every pattern into `syndicate/learned-agents/` inside the project where it was discovered. The learning then dies with the run, or at best is carried forward only within that project's branch. Voyager's lifelong-learning result is the exact counterfactual: an accumulating library of executable skills is what produces compounding capability across tasks. Claude Code already supports user-level skills and agents at `~/.claude/{skills,agents}/` with automatic cross-project discovery and a defined precedence order, so the substrate cost is zero. The only missing piece is the syndicate's policy for where to write and how to track provenance. This variant installs that policy and nothing else.

## Collision Policy: Why Fall Back to Project-Level

Four candidates were considered:

- **Overwrite:** destroys prior work from another project. Rejected.
- **Merge:** ambiguous semantics, two prompts don't compose. Rejected.
- **Auto-version (`<name>-v2`):** proliferates artifacts the user didn't ask for; future runs have to reason about which version wins. Rejected.
- **Fall back to project-level:** preserves the existing user-level artifact, still captures the new learning so the current run is not blocked, and leaves an auditable collision record in the manifest for a future meta-agent to reconcile. Chosen.

Revision of an existing user-level artifact is explicitly allowed when the current run is the original author (matches `source_run` in the manifest), so iterative refinement within a venture still works.

## Risks

1. **Token growth in loop.md:** +~50 lines (~63 insertions, 14 deletions net). SKILL.md grew by only ~2 lines. The discovery gate (names and descriptions only, full content lazy-loaded on trigger match) bounds per-generation token load even as the user library grows large. Risk is acceptable and is the minimum needed to define the manifest format, collision policy, and discovery procedure.
2. **Cross-project contamination:** a low-quality promotion in project A could degrade project B. Mitigated by (a) the existing promotion gate ("recurrence + actionability"), (b) trigger-gated loading so a mismatched agent is never invoked, and (c) the retired flag in the manifest so a later run can neutralize a bad artifact without deleting it.
3. **Name collisions with non-syndicate artifacts:** the user may have their own agents and skills at user level. The manifest-is-authoritative rule ("no manifest entry means not ours, do not touch") prevents the syndicate from claiming or modifying anything it did not create.
4. **No migration path for existing project-level learned agents:** runs that already have `syndicate/learned-agents/<name>.md` continue to work unchanged. The project registry is still read. Existing artifacts simply don't get auto-promoted to user level; future ones do.
5. **Coherence firewall:** untouched. The coherence agent's fixed system prompt, zero tool access, and metrics-only view are preserved.

## Expected Improvement

- Gen 0 of every future run starts with a non-empty candidate pool, so early generations can skip re-deriving patterns already discovered elsewhere.
- The syndicate now has the lifelong-learning property Voyager demonstrated: each run is a contribution to a growing shared library, not a sandbox.
- Provenance is queryable: `source_run`, `source_project`, and timestamps let a meta-agent trace any user-level artifact back to its origin when diagnosing problems.
- Plugin's existing flows (bootstrap, worktree dispatch, squash-merge, coherence check, metrics) are unchanged.
