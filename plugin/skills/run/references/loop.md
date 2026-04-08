# Loop Reference

Procedural details for running governed evolution. Read this when you need specifics on subagent invocation, metrics formats, or git workflow.

## Subagent Invocation

Invoke subagents using the Agent tool. The plugin ships two agents (`syndicate:task` and `syndicate:coherence`) with static system prompts in `agents/`. Dynamic context goes in the Agent tool's `prompt` parameter.

### Task Agent

`syndicate:task` is invoked via the Agent tool with parallel dispatch. Each proposed variant gets its own task agent running in an isolated worktree simultaneously. The model defaults to opus (from the agent frontmatter); pass `model: sonnet` to downgrade if evidence supports it.

```
Agent tool:
  description: "Gen <N> variant <V>: produce deliverable"
  subagent_type: "syndicate:task"
  isolation: "worktree"
  run_in_background: true
  prompt: |
    <contents of prompts/task.md>

    Skills:
    <concatenated contents of all files in skills/*.md and skills/domain/*.md>

    Goal:
    <contents of goal.md>

    Output directory: syndicate/attempts/gen-<N>-<V>/
    Put all output files in the output directory above. Create it if needed.
```

Dispatch all variants simultaneously. After all complete, check out each variant's branch to read its output for scoring.

### Learned Agents

Learned agents are specialized subagents promoted from recurring patterns in meta-notes. They live at user level (`~/.claude/agents/<name>.md`) by default so every future syndicate run across any project can discover and reuse them. Project-scoped agents (rare, project-specific) live in `syndicate/learned-agents/<name>.md`. See "Promoting Learnings" for the promotion and discovery rules.

Before invoking, read both registries (`~/.claude/syndicate-manifest.jsonl` for user-level, `syndicate/learned-agents/registry.jsonl` for project-level) and each candidate agent's "When to Invoke" field. Only invoke agents whose trigger conditions match the current situation. Most generations invoke zero learned agents.

```
Agent tool:
  description: "Gen <N>: <agent name>"
  model: sonnet
  prompt: |
    <contents of learned-agents/<name>.md>

    Context:
    <context as specified by the agent's 'Context Required' section>

    Provide your output as specified in your instructions.
```

Default to sonnet. Upgrade to opus or downgrade to haiku based on evidence.

Learned agents can run at two points in the loop:
- **Pre-generation** (after Diagnose, before Attempt): output feeds into the task agent's context
- **Post-generation** (after Attempt, before Score): output informs scoring

Update the registry after each invocation: increment `invocations`, set `last_invoked`.

### Coherence Agent

Build a limited view first: scores, complexity, git log, diff stats. Never include code or file contents. The coherence agent has zero tool access (`tools: []` in its definition), so it can only reason about what you pass in the prompt. One coherence call per generation step evaluates the full batch of variants together.

```
Agent tool:
  description: "Gen <N>: coherence check (batch)"
  subagent_type: "syndicate:coherence"
  prompt: |
    Generation: <N>
    Phase: <exploration (gen N of minimum 3) | convergence | convergence (transitioned at gen N)>
    Branch: <list all variants, marking best, e.g. gen-3-b (best), gen-3-a, gen-3-c>
    Variants tried: <count>
    Ratchet: <ratchet action taken, e.g. "added: error recovery" or "raised: test coverage" or "none (convergence phase)">

    Scores:
    <each variant with its score and change description>

    Recent score trajectory (winning variants only):
    <last 10 lines of metrics/scores.jsonl>

    Complexity trend:
    <last 10 lines of metrics/complexity.jsonl>

    Git log (last 10):
    <git log --oneline -10>

    Last change (file stats only, provisional winner by score):
    <git diff of highest-scoring branch --stat>

    Respond as JSON only.
```

On the first generation after transition, use `Phase: convergence (transitioned at gen N)` and add:

```
    Transition rationale: <one-sentence summary of why exploration ended>
```

These changes are to the dynamic invocation prompt, not the static system prompt in `agents/coherence.md`. The coherence firewall is not affected.

The coherence agent's response omits `generation`. Add the current generation number before appending to `coherence-log.jsonl`.

If the coherence agent returns invalid JSON, treat it as `flag` with reason "coherence agent returned invalid response" and log that to `coherence-log.jsonl`.

For flag handling behavior, see SKILL.md step 6.

## Metrics Formats

All metrics files are append-only JSONL in `metrics/`.

### scores.jsonl

```jsonl
{"generation": 1, "scores": {"input_validation": 2, "error_messages": 1}, "avg": 1.5, "model": "opus", "criteria_changed": false, "phase": "exploration", "ratchet": "added: error recovery", "timestamp": "2026-03-23T14:30:00Z"}
```

- `phase`: `"exploration"` or `"convergence"`
- `ratchet`: describes the ratchet action taken. Required during exploration, null during convergence if none taken. Include pruning if applicable: `"added: X, pruned: Y (reason)"`.
- `criteria_changed`: still present for backward compatibility. Set to `true` whenever criteria were modified for any reason. The `ratchet` field provides the specific action; `criteria_changed` is the coarse signal the coherence agent uses for trajectory analysis.

Only the winning variant's score is appended per generation step. All variant scores are recorded in `branches.jsonl`. This keeps the coherence agent's score trajectory clean: one entry per generation, not one per variant.

### complexity.jsonl

```jsonl
{"generation": 1, "skill_tokens": 45, "prompt_tokens": 12, "file_count": 3, "learned_agent_count": 0, "learned_agent_invocations": 0, "variants_tried": 1}
```

Count non-retired entries in `learned-agents/registry.jsonl` for `learned_agent_count`. For `learned_agent_invocations`, count the learned agents invoked during the current generation.

### coherence-log.jsonl

```jsonl
{"generation": 1, "status": "continue", "reason": "Scores improving, complexity stable"}
```

### archive/branches.jsonl

```jsonl
{"generation": 3, "variant": "a", "branch": "gen-3-a", "parent": "gen-2-a", "score": 3.2, "pruned": true, "change": "switched to grid layout"}
{"generation": 3, "variant": "b", "branch": "gen-3-b", "parent": "gen-2-a", "score": 4.1, "pruned": false, "change": "added responsive breakpoints"}
```

One line per variant. The `branch` field stores the logical variant name (e.g., `gen-3-b`), not the ephemeral worktree branch name. The `parent` field references the previous generation's winning variant. Since squash-merges land on `syndicate/run-<N>`, the parent for all variants in a generation is the tip of that branch. Only the winning variant has `pruned: false`.

## Git Workflow

### Bootstrap

At bootstrap, detect the PR target branch (`git symbolic-ref refs/remotes/origin/HEAD`, fall back to `main`). If no remote, record `none`. Write the result to `syndicate/.pr-target`.

Create `syndicate/run-<N>` off the current HEAD (N increments if prior runs exist). Commit the initial `syndicate/` directory. Tag it `syndicate-seed-<N>` (local only, not pushed).

### Generation Branches

Variant branches are ephemeral. Claude Code's `isolation: "worktree"` creates them automatically when dispatching task agents. After scoring:

Squash-merge the winning variant onto `syndicate/run-<N>`:

    git checkout syndicate/run-<N>
    git merge --squash <worktree-branch>
    git commit -m "gen-<G>: <one sentence>"

Force-remove all variant worktrees and delete their branches:

    git worktree remove --force <worktree-path>
    git branch -D <worktree-branch>

After cleanup, only `syndicate/run-<N>` exists. The parent for the next generation is always the tip of this branch.

### Completion

On stopping, commit the final state (deliverable + `syndicate/` directory) on `syndicate/run-<N>`. If `syndicate/.pr-target` is not `none`, push the branch and open a PR targeting that branch. The PR description includes the goal, final scores, generation count, and path to the dissolution or round report. If no remote, tell the user which branch contains the deliverable.

## Promoting Learnings

After recording observations in meta-notes, evaluate whether any pattern is ready for promotion. Promote when:
- **Recurrence:** the pattern keeps coming up
- **Actionability:** it's reusable, not just an observation

The meta-agent decides the form:
- **Procedure** (takes input, produces output, works independently) → create a **learned agent** (default path: `~/.claude/agents/<name>.md`)
- **Knowledge** (techniques, patterns, domain facts that inform work) → create or update a **domain skill** (default path: `~/.claude/skills/<name>/SKILL.md`)

### Promotion Scope: User vs Project

Default to **user-level** promotion. Learnings are broadly useful unless proven otherwise, and cross-run accumulation is the whole point: a pattern discovered in project A should sharpen future runs in projects B, C, and D. This mirrors lifelong skill libraries in Voyager (Wang et al., 2023) where compounding a persistent library of executable skills across tasks is what drives superhuman generalization.

**Install project-level only when** the learning is demonstrably project-specific: it references paths, names, schemas, or conventions that would be meaningless or actively misleading elsewhere. Note the opt-out reason in meta-notes.

### Collision Policy

If the target user-level path already exists (`~/.claude/agents/<name>.md` or `~/.claude/skills/<name>/SKILL.md`), **fall back to project-level** install in `syndicate/learned-agents/<name>.md` or `syndicate/skills/domain/<name>.md` and record the collision in the user manifest with `"collision": true` and `"fallback_scope": "project"`. Do not overwrite, merge, or auto-version user-level artifacts from other runs. Revision of an existing user-level artifact is allowed only when the current run is the original author (matching `source_run` in the user manifest), in which case update in place and bump `last_revised`.

One policy, no branches. Preserves work from prior runs, keeps this run unblocked, and leaves explicit reconciliation to the meta-agent of a later run if it notices the collision.

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
<What this agent needs to see as input>
```

Append a provenance line to the **user manifest** `~/.claude/syndicate-manifest.jsonl` (user-level installs) or to the **project registry** `syndicate/learned-agents/registry.jsonl` (project fallback). The user manifest is the cross-run source of truth; the project registry mirrors it only for project-scoped artifacts.

User manifest line format:

```jsonl
{"kind": "agent", "name": "<name>", "path": "~/.claude/agents/<name>.md", "scope": "user", "source_run": "<project-slug>/run-<N>", "source_project": "<project-path>", "promoted_at": "2026-04-08T12:00:00Z", "last_revised": "2026-04-08T12:00:00Z", "description": "<one sentence from agent frontmatter>", "collision": false, "fallback_scope": null, "retired": false}
```

Project registry line (unchanged, for project fallback only):

```jsonl
{"name": "<name>", "promoted_at": <gen>, "last_revised": <gen>, "invocations": 0, "last_invoked": null, "retired": false}
```

Note the promotion in meta-notes: `Promoted to agent: <name> at <scope> (reason: <one sentence>)`.

### Evolving Learned Agents and Skills

Learned agents and domain skills are living documents. Revise them as understanding deepens. A learned agent promoted at gen-5 may be substantially different by gen-20. Update `last_revised` in the registry when revising an agent.

### Retiring Learned Agents

Retire learned agents that are no longer pulling their weight. Set `retired: true` in the registry. No fixed rules. The coherence agent monitors complexity growth and will flag if proliferation outpaces improvement.

## Discovery at Gen 0

Every fresh syndicate run performs one discovery pass at bootstrap, before writing `goal.md`. The point is to load prior runs' accumulated agents and skills as candidate context so the current run starts from the accumulated state, not from zero. This is the library-compounding behavior Voyager demonstrated in a lifelong learning setting: a persistent skill library carried across tasks is what drives rapid generalization (Wang et al., 2023). Reflexion and ExpeL show the same pattern for textual skill transfer across tasks (Shinn et al., 2023; Zhao et al., 2024).

Procedure:

1. Read `~/.claude/syndicate-manifest.jsonl` if it exists. Skip entries where `retired: true`.
2. For each non-retired entry, read the `description` field and, if useful, the artifact's frontmatter. Do **not** inline full contents.
3. Write `syndicate/discovered.jsonl` (one line per candidate): name, kind, path, description. This is per-run ephemeral metadata.
4. The meta-agent keeps the index in working context so Diagnose and Propose Changes can reference candidates by name and description.
5. Load full artifact contents **only when** a candidate's trigger conditions match the situation at generation time (same gating as learned-agent invocation). This keeps per-generation token load bounded even as the user library grows.

Claude Code's own discovery rules (user-level skills and agents under `~/.claude/` are automatically available across projects, with user-level taking precedence over project-level on name collision) mean user-level installs are loadable by Claude Code without any path manipulation from the syndicate. The manifest exists so the syndicate itself can reason about provenance, lifecycle, and collisions.

The user manifest is authoritative for syndicate-owned artifacts. A file at `~/.claude/agents/<name>.md` without a manifest entry belongs to the user or another plugin; do not claim, modify, or retire it.

## Importing External Skills

Domain skills can come from installed Claude Code plugins, not just local promotion. Before writing a new domain skill from scratch, check whether an installed plugin already publishes a relevant one.

### Finding Skills

Browse `~/.claude/plugins/` for installed plugins. Look in each plugin's `skills/` directory for skill files and references that match the syndicate's current needs.

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

Once imported, a skill belongs to this syndicate. Edit it freely as understanding deepens. When you modify an imported skill, set `diverged: true` and update `last_revised` in `skills-manifest.jsonl`. There is no upstream sync. Provenance metadata exists so you can check the source later if needed, not for automatic updates.

### Promoting Imported Skills to Agents

Imported skills follow the same promotion path as locally-grown skills. When it becomes clear a skill is being used procedurally: it takes input, produces output, and works independently, promote it to a learned agent using the standard procedure. Optionally retire the domain skill in `skills-manifest.jsonl` if the agent fully subsumes it. If the skill still has knowledge value beyond the procedure, keep both.

### skills-manifest.jsonl

Tracks provenance and lifecycle for project-scoped domain skills: plugin imports, and local promotions that fell back to project scope because of the collision policy or an explicit project-specific opt-out. User-level locally promoted skills live in `~/.claude/syndicate-manifest.jsonl` instead. One line per skill.

```jsonl
{"name": "<name>", "origin": "import", "source_plugin": "<plugin>", "source_path": "<path>", "imported_at": "gen-<N>", "diverged": false, "last_revised": "gen-<N>", "retired": false}
{"name": "<name>", "origin": "local", "promoted_at": "gen-<N>", "last_revised": "gen-<N>", "retired": false}
```

When promoting a local learning to a domain skill (instead of a learned agent), also append a line here with `"origin": "local"`.

## Meta-Notes Distillation

meta-notes.md is not strictly append-only. Distill it when:
- **Round boundary** (venture mode): natural pause point for cleanup
- **Too long:** the file is consuming too many tokens relative to its value

Distillation procedure:
1. Entries whose learnings have been promoted to agents/skills → replace with a one-line reference: `→ See learned-agents/<name>.md` or `→ See skills/domain/<name>.md`
2. Stale observations (tried something, didn't work, already captured in approach) → compress into a summary paragraph
3. Recent entries (last ~5 generations) → keep intact
4. Add a `--- Distilled through gen-N ---` marker separating compressed history from live notes

Git preserves the full history. The working file stays short and relevant.

### Researching History

When diagnosing stubborn problems, dig into git history, not just the current meta-notes. Earlier entries that were distilled away may contain relevant context. Use `git log` and `git show` to recover earlier meta-notes or attempt details when current notes don't explain a recurring failure.

## Discovery Phase (Venture Mode)

After shipping a round's best attempt, the meta-agent shifts from execution to discovery. This is not a subagent call. You do this yourself.

1. Read the shipped deliverable in context of the project.
2. Read `meta-notes.md` for accumulated learnings.
3. Read `venture.jsonl` (if it exists) for what previous rounds focused on.
4. Identify 3-5 candidate improvements, each as one sentence.
5. Pick the highest-value one. Write a brief rationale.
6. Rewrite `criteria.md` targeting that improvement (3-7 criteria, same as gen 1).
7. Append to `meta-notes.md`: what was chosen, what was rejected, why. Use a `--- Round N ---` separator.
8. Append to `venture.jsonl` (create it on the first round boundary).
9. Write a round report to `reports/round-N.md` following the Round Report Format above. In interactive sessions, also present it to the user.
10. Resume the evolution loop. The next generation continues the global count.

Discovery should be fast: one deliberate pause, not a sub-loop. If you can't find anything worth improving, write a dissolution report to `reports/final.md` and dissolve.

## Round Transitions

Generation numbering is **global**. If round 1 ends at gen-12, round 2 starts at gen-13.

**What resets:** `criteria.md` (rewritten for the new focus).

**What may be revised:** `skills/approach.md`, `prompts/task.md`. Adjust if the new focus needs a different approach.

**What persists:** `goal.md` (fixed forever), `meta-notes.md` (distilled at round boundaries), `learned-agents/` (evolving), all `metrics/*`, `archive/branches.jsonl`, `venture.jsonl`.

**Branch lifetime:** One `syndicate/run-<N>` branch spans all rounds. Round boundaries do not create new branches. The PR is opened at dissolution, not at each round boundary. Round reports are committed to the branch as they are written.

### venture.jsonl

Created at the first round boundary. One line per completed round.

```jsonl
{"round": 1, "goal_focus": "initial implementation", "generations": 12, "best_score": 4.2, "shipped_at": "gen-12", "timestamp": "2026-03-24T10:00:00Z"}
```

### venture.jsonl Distillation

venture.jsonl is not strictly append-only. When the file is consuming too many tokens relative to its value, distill it: compress older rounds into a summary paragraph at the top, keep recent rounds intact. Git preserves the full history for research.

### Coherence Agent at Round Boundaries

The coherence agent's fixed prompt does not change. But criteria changes at a round boundary are larger than mid-round tweaks. Scores will drop because the scoring dimensions changed. When invoking the coherence agent for the first generation of a new round, add this to the context:

```
Note: Criteria changed at generation <N> (new venture round). Score drops from criteria changes are expected.
```

## Reports

The syndicate writes reports at round boundaries and on dissolution. All reports go in `reports/`.

### Round Report Format

Written after the discovery phase completes (step 9), before resuming the evolution loop. File: `reports/round-N.md`.

```
# Round N Report

## What Shipped
<One sentence describing the deliverable. Path to best attempt.>

## Score Trajectory
<Starting and ending average scores for the round. Number of generations. Notable events: model upgrades, criteria revisions, coherence flags.>

## What Was Learned
<Two to three sentences distilled from meta-notes. What worked, what didn't.>

## Next Round Focus
<What the discovery phase identified as the highest-value improvement, and why. What was considered and rejected.>
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
<For ventures: one line per round from venture.jsonl. For jobs: single round summary.>

## What Was Learned
<Key learnings distilled from meta-notes. What approaches worked, what failed, what surprised.>

## Deliverable
<Path to the best attempt in the project root.>
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
│   └── domain/          # Project-scoped domain skills (user-level is the default; this is the fallback)
├── prompts/
│   └── task.md
├── learned-agents/      # Project-scoped learned agents (user-level is the default; this is the fallback)
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
