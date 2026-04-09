# Loop Reference

Procedural details for governed evolution. Read for specifics on subagent invocation, metrics formats, or git workflow.

## Subagent Invocation

Invoke subagents using the Agent tool. The plugin ships two agents (`syndicate:task` and `syndicate:coherence`) with static system prompts in `agents/`. Dynamic context goes in the Agent tool's `prompt` parameter.

### Task Agent

`syndicate:task` is dispatched in parallel: each variant gets its own task agent in an isolated worktree, all running simultaneously. Model defaults to opus (from agent frontmatter); pass `model: sonnet` to downgrade with evidence.

```
Agent tool:
  description: "Gen <N> variant <V>: produce deliverable"
  subagent_type: "syndicate:task"
  isolation: "worktree"
  run_in_background: true
  prompt: |
    <contents of prompts/task.md, with {{SKILLS_BLOCK}} replaced (see below)>

    Goal:
    <contents of goal.md>

    Criteria:
    <contents of criteria.md>

    Output directory: syndicate/attempts/gen-<N>-<V>/
    Put all output files in the output directory above. Create it if needed.

Replace `{{SKILLS_BLOCK}}` in the prompt with two sections:

1. **Syndicate skills (inlined):** concatenate all files in `skills/*.md` and `skills/domain/*.md` as full content. These are always included.
2. **Installed plugin skills (listed):** for each installed-plugin entry in `discovered.jsonl` whose description matches the current generation's focus, include one line: `- <name>: <description>`. These are invoked via the Skill tool at runtime; do not inline their full content. Not every installed skill appears every generation. Select based on relevance to the current Diagnose output.
```

Dispatch all variants simultaneously. After they complete, check out each variant's branch to read its output for scoring.

**Worktree baseline-sync (mandatory).** Due to anthropics/claude-code#45371, `isolation: "worktree"` currently forks from the default branch instead of the caller's current HEAD, so the task agent will not see prior generations' winners. Every task-agent prompt MUST include this instruction:

> Before starting work, run: `bash syndicate/baseline-sync.sh syndicate/run-<N>`
> If it fails, write `BASE_ERROR.md` to your output directory explaining the error and stop.

The script checks out all files from the run branch, commits the sync, and verifies `syndicate/` landed. All variant edits sit on top of the baseline-sync commit.

The meta-agent extracts each variant's incremental work with `git diff baseline-sync HEAD` and applies that delta (not the whole branch) to `syndicate/run-<N>`. Remove this workaround (script + prompt instruction) when anthropics/claude-code#45371 is fixed.

### Learned Agents

Learned agents are specialized subagents promoted from recurring patterns. They live at user level (`~/.claude/agents/<name>.md`) by default so any future syndicate run in any project can discover and reuse them. Project-scoped agents (rare, project-specific) live in `syndicate/learned-agents/<name>.md`. See "Promoting Learnings" below.

Before invoking, read both registries (`~/.claude/syndicate-manifest.jsonl` for user level, `syndicate/learned-agents/registry.jsonl` for project level) and each candidate's "When to Invoke" field. Only invoke agents whose triggers match the current situation. Most generations invoke zero learned agents.

```
Agent tool:
  description: "Gen <N>: <agent name>"
  model: sonnet
  prompt: |
    <contents of learned-agents/<name>.md>

    Context:
    <as specified by the agent's 'Context Required' section>

    Provide your output as specified in your instructions.
```

Default to sonnet. Upgrade to opus or downgrade to haiku based on evidence.

Learned agents run at two points in the loop:
- **Pre-generation** (after Diagnose, before Attempt): output feeds into the task agent's context
- **Post-generation** (after Attempt, before Score): output informs scoring

After each invocation, increment `invocations` and set `last_invoked` in the registry.

### Coherence Agent

Build a limited view first: scores, complexity, git log, diff stats. Never include code or file contents. The coherence agent has zero tool access (`tools: []`), so it only sees what you pass in the prompt. One coherence call per generation step evaluates the full batch of variants together.

```
Agent tool:
  description: "Gen <N>: coherence check (batch)"
  subagent_type: "syndicate:coherence"
  prompt: |
    Generation: <N>
    Phase: <exploration (gen N of minimum 3) | convergence | convergence (transitioned at gen N)>
    Branches: <list all variants, marking best, e.g. gen-3-b (best), gen-3-a, gen-3-c>
    Variants tried: <count>
    Ratchet: <action taken, e.g. "added: error recovery" | "raised: test coverage" | "none (convergence phase)">

    Scores:
    <each variant with its score and change description>

    Recent score trajectory (winners only):
    <last 10 lines of metrics/scores.jsonl>

    Complexity trend:
    <last 10 lines of metrics/complexity.jsonl>

    Git log (last 10):
    <git log --oneline -10>

    Last change (file stats only, provisional winner):
    <git diff of highest-scoring branch --stat>

    Respond as JSON only.
```

On the first generation after transition, use `Phase: convergence (transitioned at gen N)` and add:

```
    Transition rationale: <one-sentence summary of why exploration ended>
```

These edits are to the dynamic invocation prompt only, not the static system prompt in `agents/coherence.md`. The firewall is unaffected.

The coherence agent's response omits `generation`. Add the current generation number before appending to `coherence-log.jsonl`.

If the response is not valid JSON, treat it as `flag` with reason "coherence agent returned invalid response" and log that.

For flag handling, see SKILL.md step 6.

## Mutation Operators

Each variant declares one of these operators (recorded as `operator` on its `branches.jsonl` line). A fixed taxonomy outperforms ad-hoc edits in evolutionary prompt search (PromptBreeder, Fernando et al. 2023, arXiv:2309.16797; EvoPrompt, Guo et al. 2023, arXiv:2309.08532).

- **rewrite**: restate an existing instruction/section differently without changing scope.
- **constrain**: add a rule, cap, or guard that narrows allowable behavior.
- **decompose**: split one step, criterion, or artifact into finer-grained parts.
- **invert**: flip the default (opt-in to opt-out, allow-list to deny-list, or swap the primary case).
- **borrow**: import a technique from a cited external source or a prior generation's pruned branch.

Two same-operator variants in one generation do not satisfy the "genuinely different" exploration requirement. Pairwise is available as a tie-breaker; see gen-2-a rationale.

## Metrics Formats

All metrics files are append-only JSONL in `metrics/`.

### scores.jsonl

```jsonl
{"generation": 1, "scores": {"input_validation": 2, "error_messages": 1}, "avg": 1.5, "model": "opus", "criteria_changed": false, "phase": "exploration", "ratchet": "added: error recovery", "timestamp": "2026-03-23T14:30:00Z"}
```

- `phase`: `"exploration"` or `"convergence"`
- `ratchet`: action taken. Required during exploration; null during convergence if none. Include pruning if applicable: `"added: X, pruned: Y (reason)"`.
- `criteria_changed`: kept for backward compatibility. Set `true` whenever criteria were modified for any reason. The `ratchet` field carries the specific action; `criteria_changed` is the coarse signal the coherence agent uses for trajectory analysis.

Only the winner's score is appended per generation. All variant scores live in `branches.jsonl`. This keeps the coherence agent's trajectory clean: one entry per generation, not one per variant.

### complexity.jsonl

```jsonl
{"generation": 1, "skill_tokens": 45, "prompt_tokens": 12, "file_count": 3, "learned_agent_count": 0, "learned_agent_invocations": 0, "variants_tried": 1}
```

`learned_agent_count` counts non-retired entries in `learned-agents/registry.jsonl`. `learned_agent_invocations` counts learned agents invoked during the current generation.

### coherence-log.jsonl

```jsonl
{"generation": 1, "status": "continue", "reason": "Scores improving, complexity stable"}
```

### archive/branches.jsonl

```jsonl
{"generation": 3, "variant": "a", "branch": "gen-3-a", "parent": "gen-2-a", "score": 3.2, "pruned": true, "combined": false, "operator": "rewrite", "change": "switched to grid layout"}
{"generation": 3, "variant": "b", "branch": "gen-3-b", "parent": "gen-2-a", "score": 4.1, "pruned": false, "combined": false, "operator": "constrain", "change": "added responsive breakpoints"}
```

One line per variant. `branch` is the logical variant name (e.g., `gen-3-b`), not the ephemeral worktree branch. `parent` references the previous generation's winner. Since squash-merges land on `syndicate/run-<N>`, the parent for all variants in a generation is the tip of that branch. Only the winner has `pruned: false`.

When variants are combined (see SKILL.md step 7), all contributing variants have `"pruned": false, "combined": true`. Non-contributing variants in the same generation are still `"pruned": true, "combined": false`.

## Git Workflow

### Bootstrap

Detect the PR target branch. If the repo has no remote, write `none`. Otherwise run `git symbolic-ref refs/remotes/origin/HEAD` and, on any non-zero exit (no origin HEAD ref set, shallow clone, etc.), fall back to `main`. Write the result to `syndicate/.pr-target`.

Create `syndicate/run-<N>` off HEAD (N increments past prior runs). Commit the initial `syndicate/` directory. Tag it locally with `git -c tag.gpgSign=false tag -a syndicate-seed-<N> -m "syndicate seed <N>"`. The explicit `-a` and `-c tag.gpgSign=false` are required: users commonly have `tag.gpgSign=true` or `tag.forceSignAnnotated=true` globally, which causes plain `git tag <name>` to fail with `fatal: no tag message?`. Do not push the tag.

### Generation Branches

Variant branches are ephemeral. Claude Code's `isolation: "worktree"` creates them automatically when dispatching task agents. After scoring:

Squash-merge the winner onto `syndicate/run-<N>`:

    git checkout syndicate/run-<N>
    git merge --squash <worktree-branch>
    git commit -m "gen-<G>: <one sentence>"

Force-remove all variant worktrees and delete their branches:

    git worktree remove --force <worktree-path>
    git branch -D <worktree-branch>

After cleanup, only `syndicate/run-<N>` exists. The next generation's parent is always the tip of this branch.

### Completion

On stopping, commit the final state (deliverable + `syndicate/` directory) on `syndicate/run-<N>`. If `syndicate/.pr-target` is not `none`, push the branch and open a PR targeting it. The PR description includes goal, final scores, generation count, and path to the dissolution or round report. If no remote, tell the user which branch contains the deliverable.

## Promoting Learnings

After updating meta-notes, evaluate whether any pattern is ready for promotion. Promote when:
- **Recurrence:** the pattern keeps coming up
- **Actionability:** it's reusable, not just an observation

The meta-agent decides the form:
- **Procedure** (takes input, produces output, runs independently) → **learned agent** (default path: `~/.claude/agents/<name>.md`)
- **Knowledge** (techniques, patterns, domain facts that inform work) → **domain skill** (default path: `~/.claude/skills/<name>/SKILL.md`)

### Promotion Scope: User vs Project

Default to **user-level** promotion. Learnings are broadly useful unless proven otherwise, and cross-run accumulation is the whole point: a pattern discovered in project A should sharpen future runs in projects B, C, and D. This mirrors the lifelong skill libraries in Voyager (Wang et al., 2023), where compounding a persistent library of executable skills across tasks drives superhuman generalization.

**Install project-level only when** the learning is demonstrably project-specific: it references paths, names, schemas, or conventions that would be meaningless or actively misleading elsewhere. Note the opt-out reason in meta-notes.

### Collision Policy

If the target user-level path already exists (`~/.claude/agents/<name>.md` or `~/.claude/skills/<name>/SKILL.md`), **fall back to project-level** install in `syndicate/learned-agents/<name>.md` or `syndicate/skills/domain/<name>.md` and record the collision in the user manifest with `"collision": true` and `"fallback_scope": "project"`. Do not overwrite, merge, or auto-version user-level artifacts from other runs. Revising an existing user-level artifact is allowed only when the current run is its original author (matching `source_run` in the user manifest), in which case update in place and bump `last_revised`.

One policy, no branches. Preserves prior runs' work, keeps this run unblocked, and leaves explicit reconciliation to the meta-agent of a later run if it notices the collision.

### Creating a Learned Agent

Write the agent definition to the chosen path (user-level default: `~/.claude/agents/<name>.md`; project fallback: `syndicate/learned-agents/<name>.md`):

```markdown
# <Agent Name>

Promoted at generation <N>. Last revised generation <M>.

## Role
<One sentence: what this agent does>

## When to Invoke
<One sentence: the condition under which to call this agent>

## Instructions
<The actual agent prompt. Concise, 10-30 lines. Token efficiency still matters.>

## Context Required
<What this agent needs as input>
```

Append a provenance line to the **user manifest** `~/.claude/syndicate-manifest.jsonl` (user-level installs) or to the **project registry** `syndicate/learned-agents/registry.jsonl` (project fallback). The user manifest is the cross-run source of truth; the project registry mirrors it only for project-scoped artifacts.

User manifest line format:

```jsonl
{"kind": "agent", "name": "<name>", "path": "~/.claude/agents/<name>.md", "scope": "user", "source_run": "<project-slug>/run-<N>", "source_project": "<project-path>", "promoted_at": "2026-04-08T12:00:00Z", "last_revised": "2026-04-08T12:00:00Z", "description": "<one sentence from agent frontmatter>", "collision": false, "fallback_scope": null, "retired": false, "uses_count": 0, "score_deltas": [], "avg_score_delta": null, "last_used": null, "flagged": false}
```

Project registry line (unchanged, for project fallback only):

```jsonl
{"name": "<name>", "promoted_at": <gen>, "last_revised": <gen>, "invocations": 0, "last_invoked": null, "retired": false}
```

Note in meta-notes: `Promoted to agent: <name> at <scope> (reason: <one sentence>)`.

### Evolving Learned Agents and Skills

Learned agents and domain skills are living documents. Revise as understanding deepens. A learned agent promoted at gen-5 may be substantially different by gen-20. Update `last_revised` in the registry on revision.

### Retiring Learned Agents

Retire learned agents that no longer pull their weight. Set `retired: true` in the registry. No fixed rules. The coherence agent monitors complexity growth and will flag if proliferation outpaces improvement.

## Discovery at Gen 0

Every fresh syndicate run does one discovery pass at bootstrap, before writing `goal.md`. The point is to load prior runs' accumulated agents and skills as candidate context so the current run starts from the accumulated state, not from zero. This is the library-compounding behavior Voyager demonstrated in a lifelong learning setting: a persistent skill library carried across tasks drives rapid generalization (Wang et al., 2023). Reflexion and ExpeL show the same pattern for textual skill transfer (Shinn et al., 2023; Zhao et al., 2024).

Procedure:

1. Read `~/.claude/syndicate-manifest.jsonl` if it exists. Skip entries where `retired: true`. If the file is missing (first-ever syndicate run on this machine), skip this source.
2. For each non-retired manifest entry, read the `description` field and, if useful, the artifact's frontmatter. Do **not** inline full contents. Write to `syndicate/discovered.jsonl` with `"origin": "syndicate"`: name, kind, path, description.
3. Scan the system reminder's available skills list. For each installed plugin skill, write to `syndicate/discovered.jsonl` with `"origin": "installed-plugin"`, `"kind": "skill"`, name, and description:
   ```jsonl
   {"name": "superpowers:test-driven-development", "kind": "skill", "origin": "installed-plugin", "description": "Use when implementing any feature or bugfix..."}
   ```
4. If neither source yielded entries, write an empty `syndicate/discovered.jsonl`.
5. The meta-agent keeps the index in working context so Diagnose and Propose Changes can reference candidates by name and description.
6. For syndicate-origin entries: load full artifact contents **only when** a candidate's trigger conditions match the situation at generation time (same gating as learned-agent invocation). This bounds per-generation token load even as the user library grows.
7. For installed-plugin entries: include name + description in the task agent prompt when relevant. The task agent invokes them via the Skill tool at runtime.

### Ranking Formula

As the user library grows, description-only ranking degrades: Voyager (Wang et al. 2023, arXiv:2305.16291) shows a persistent skill library drives lifelong performance but retrieval quality matters; the lifelong-LLM-agents roadmap (Zheng et al. 2025, arXiv:2501.07278) names wake-sleep curation as the missing primitive. Rank discovered candidates by:

    rank = 0.5 * desc_match + 0.2 * use_signal + 0.3 * quality

Where `desc_match` is goal-keyword overlap with the entry's description (lowercased, stop-words removed; 0 to 1), `use_signal` is `min(uses_count / 5, 1)`, and `quality` is `clip(0.5 + avg_score_delta / 2, 0, 1)`. Cold-start fallback: unproven entries (`uses_count == 0`) use `quality = 0.5` and `use_signal = 0`, so they compete on description alone. Load the top 10 candidates into working context. Skip entries where `flagged: true`. After `uses_count >= 3`, if `avg_score_delta <= 0`, set `flagged: true` (reversible on a later positive event). Usage recording is finalized when first user-level promotion runs live.

This ranking formula applies to `"origin": "syndicate"` entries only. Installed-plugin entries (`"origin": "installed-plugin"`) have no usage stats in the manifest; rank them by `desc_match` alone.

Claude Code's own discovery (user-level skills and agents under `~/.claude/` are automatically available across projects, with user level taking precedence on name collision) means user-level installs are loadable without any path manipulation from the syndicate. The manifest exists so the syndicate itself can reason about provenance, lifecycle, and collisions.

The user manifest is authoritative for syndicate-owned artifacts. A file at `~/.claude/agents/<name>.md` without a manifest entry belongs to the user or another plugin: do not claim, modify, or retire it.

## Importing External Skills

Domain skills can come from installed Claude Code plugins, not just local promotion. Before writing a new domain skill from scratch, check whether an installed plugin already publishes a relevant one.

### Finding Skills

Check `syndicate/discovered.jsonl` for `"origin": "installed-plugin"` entries matching the current need. Use the Skill tool to load the full content of the matching skill. Fall back to browsing `~/.claude/plugins/` only if `discovered.jsonl` is empty or stale.

### Import Procedure

1. Read the skill file from the installed plugin.
2. Trim to the minimum useful content. Every word costs tokens across every generation.
3. Write to `skills/domain/<name>.md` with a provenance header:

```markdown
# <Skill Name>

> Imported from plugin:<plugin-name>. Generation <N>.

<trimmed content>
```

4. Append to `skills-manifest.jsonl`:

```jsonl
{"name": "<name>", "origin": "import", "source_plugin": "<plugin-name>", "source_path": "<path within plugin>", "imported_at": "gen-<N>", "diverged": false, "last_revised": "gen-<N>", "retired": false}
```

5. Note in `meta-notes.md`: `Imported skill: <name> from <plugin> (reason: <one sentence>)`.

### Evolving Imported Skills

Once imported, a skill belongs to this syndicate. Edit it freely. When you modify an imported skill, set `diverged: true` and update `last_revised` in `skills-manifest.jsonl`. There is no upstream sync. Provenance metadata exists so you can check the source later, not for automatic updates.

When an improvement could benefit the original installed skill, note it in meta-notes with the tag `upstream-recommendation:` followed by the skill name and what changed. These surface in round and dissolution reports.

### Promoting Imported Skills to Agents

Imported skills follow the same promotion path as locally-grown skills. When a skill is being used procedurally (takes input, produces output, runs independently), promote it to a learned agent via the standard procedure. Optionally retire the domain skill in `skills-manifest.jsonl` if the agent fully subsumes it. If the skill still has knowledge value beyond the procedure, keep both.

### skills-manifest.jsonl

Tracks provenance and lifecycle for project-scoped domain skills: plugin imports, plus local promotions that fell back to project scope via the collision policy or an explicit project-specific opt-out. User-level locally promoted skills live in `~/.claude/syndicate-manifest.jsonl` instead. One line per skill.

```jsonl
{"name": "<name>", "origin": "import", "source_plugin": "<plugin>", "source_path": "<path>", "imported_at": "gen-<N>", "diverged": false, "last_revised": "gen-<N>", "retired": false}
{"name": "<name>", "origin": "local", "promoted_at": "gen-<N>", "last_revised": "gen-<N>", "retired": false}
```

When promoting a local learning to a domain skill (instead of a learned agent), also append a line here with `"origin": "local"`.

## Meta-Notes Distillation

`meta-notes.md` is not strictly append-only. Distill it when:
- **Round boundary** (venture mode): natural pause point for cleanup
- **Too long:** the file is consuming too many tokens relative to its value

Procedure:
1. Entries whose learnings have been promoted to agents/skills → replace with a one-line reference: `→ See learned-agents/<name>.md` or `→ See skills/domain/<name>.md`
2. Stale observations (tried something, didn't work, already captured in approach) → compress into a summary paragraph
3. Recent entries (last ~5 generations) → keep intact
4. Add a `--- Distilled through gen-N ---` marker separating compressed history from live notes

Git preserves the full history. The working file stays short and relevant.

### Researching History

When diagnosing stubborn problems, dig into git history, not just current meta-notes. Earlier entries that were distilled away may contain relevant context. Use `git log` and `git show` to recover earlier meta-notes or attempt details when current notes don't explain a recurring failure.

## Discovery Phase (Venture Mode)

After shipping a round's best attempt, the meta-agent shifts from execution to discovery. Not a subagent call: you do this yourself.

1. Read the shipped deliverable in context of the project.
2. Read `meta-notes.md` for accumulated learnings.
3. Read `venture.jsonl` (if it exists) for previous rounds' focus.
4. Identify 3 to 5 candidate improvements, each as one sentence.
5. Pick the highest-value one. Write a brief rationale.
6. Rewrite `criteria.md` targeting that improvement (3 to 7 criteria, same as gen 1).
7. Append to `meta-notes.md`: what was chosen, what was rejected, why. Use a `--- Round N ---` separator.
8. Append to `venture.jsonl` (create on the first round boundary).
9. Write a round report to `reports/round-N.md` per the Round Report Format below. In interactive sessions, also present it to the user.
10. Resume the evolution loop. Generation count continues globally.

Discovery should be fast: one deliberate pause, not a sub-loop. If you can't find anything worth improving, write a dissolution report to `reports/final.md` and dissolve.

## Round Transitions

Generation numbering is **global**. If round 1 ends at gen-12, round 2 starts at gen-13.

**What resets:** `criteria.md` (rewritten for the new focus).

**What may be revised:** `skills/approach.md`, `prompts/task.md`. Adjust if the new focus needs a different approach.

**What persists:** `goal.md` (fixed forever), `meta-notes.md` (distilled at round boundaries), `learned-agents/` (evolving), all `metrics/*`, `archive/branches.jsonl`, `venture.jsonl`.

**Branch lifetime:** One `syndicate/run-<N>` branch spans all rounds. Round boundaries do not create new branches. The PR opens at dissolution, not at each round boundary. Round reports are committed to the branch as written.

### venture.jsonl

Created at the first round boundary. One line per completed round.

```jsonl
{"round": 1, "goal_focus": "initial implementation", "generations": 12, "best_score": 4.2, "shipped_at": "gen-12", "timestamp": "2026-03-24T10:00:00Z"}
```

### venture.jsonl Distillation

Not strictly append-only. When the file consumes too many tokens relative to its value, distill: compress older rounds into a summary paragraph at the top, keep recent rounds intact. Git preserves full history.

### Coherence Agent at Round Boundaries

The coherence agent's fixed prompt does not change. But criteria changes at a round boundary are larger than mid-round tweaks; scores will drop because the scoring dimensions changed. When invoking the coherence agent for the first generation of a new round, add this to the context:

```
Note: Criteria changed at generation <N> (new venture round). Score drops from criteria changes are expected.
```

## Reports

The syndicate writes reports at round boundaries and on dissolution. All reports go in `reports/`.

### Round Report Format

Written after the discovery phase (step 9), before resuming the evolution loop. File: `reports/round-N.md`.

```
# Round N Report

## What Shipped
<One sentence describing the deliverable. Path to best attempt.>

## Score Trajectory
<Starting and ending average scores. Number of generations. Notable events: model upgrades, criteria revisions, coherence flags.>

## What Was Learned
<Two to three sentences distilled from meta-notes. What worked, what didn't.>

## Next Round Focus
<What discovery identified as the highest-value improvement, and why. What was considered and rejected.>

## Upstream Recommendations (optional)
<Include only if the syndicate has `upstream-recommendation:` entries in meta-notes. For each: skill name, what was changed, why it helps.>
```

In interactive sessions, also present the report directly to the user.

### Dissolution Report Format

Written whenever the syndicate dissolves, regardless of mode or stopping condition. File: `reports/final.md`.

```
# Dissolution Report

## Outcome
<One sentence: what was accomplished.>

## Stopping Reason
<Why the syndicate stopped: convergence (job), nothing worth improving (venture), sustained plateau, or all branches pruned.>

## Rounds Summary
<Ventures: one line per round from venture.jsonl. Jobs: single round summary.>

## What Was Learned
<Key learnings distilled from meta-notes. What worked, what failed, what surprised.>

## Deliverable
<Path to the best attempt in the project root.>

## Upstream Recommendations (optional)
<Include only if the syndicate has `upstream-recommendation:` entries in meta-notes. For each: skill name, what was changed, why it helps.>
```

### Dissolution Trigger Points

Write the dissolution report wherever `phase` is set to `"dissolved"`:
- Job mode convergence (round converged, no discovery phase)
- Venture mode exhaustion (discovery found nothing worth improving)
- Sustained plateau (flagged 3+ consecutive times, any mode)
- All branches pruned (no viable parents, any mode)

## Project Structure

After bootstrap, `syndicate/` in the project root contains:

```
syndicate/
├── .pr-target           # PR target branch (detected at bootstrap)
├── goal.md              # User's goal (written gen 1, fixed)
├── criteria.md          # Acceptance criteria (evolves)
├── meta-notes.md        # Persistent memory (distilled periodically)
├── discovered.jsonl     # Per-run index of user-level agents/skills found at bootstrap
├── venture.jsonl         # Round history (venture mode only, distilled periodically)
├── skills-manifest.jsonl # Provenance for project-scoped domain skills
├── skills/
│   ├── approach.md
│   └── domain/          # Project-scoped domain skills (user level is the default; this is fallback)
├── prompts/
│   └── task.md
├── learned-agents/      # Project-scoped learned agents (user level is the default; this is fallback)
│   └── registry.jsonl
├── attempts/
│   └── gen-N/
├── metrics/
│   ├── scores.jsonl
│   ├── complexity.jsonl
│   └── coherence-log.jsonl
├── archive/
│   └── branches.jsonl
└── reports/
    ├── round-N.md          # Round boundary reports
    └── final.md            # Dissolution report
```

User-level (outside any project, shared across all syndicate runs):

```
~/.claude/
├── agents/                 # User-level learned agents (default promotion target)
│   └── <name>.md
├── skills/                 # User-level domain skills (default promotion target)
│   └── <name>/SKILL.md
└── syndicate-manifest.jsonl  # Provenance + lifecycle for all user-level syndicate artifacts
```
