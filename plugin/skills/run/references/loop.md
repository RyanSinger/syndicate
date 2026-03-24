# Loop Reference

Procedural details for running governed evolution. Read this when you need specifics on subagent invocation, metrics formats, or git workflow.

## Subagent Invocation

Invoke subagents using the Agent tool. The plugin ships two agents (`syndicate:task` and `syndicate:coherence`) with static system prompts in `agents/`. Dynamic context goes in the Agent tool's `prompt` parameter.

### Task Agent

`syndicate:task` is invoked via the Agent tool. The model defaults to opus (from the agent frontmatter); pass `model: sonnet` to downgrade if evidence supports it.

```
Agent tool:
  description: "Gen <N>: produce deliverable"
  subagent_type: "syndicate:task"
  prompt: |
    <contents of prompts/task.md>

    Skills:
    <concatenated contents of all files in skills/*.md and skills/domain/*.md>

    Goal:
    <contents of goal.md>

    Produce the deliverable. Put all output files in the current directory.
```

Copy output into `attempts/gen-<N>/`.

### Learned Agents

Learned agents are specialized subagents the meta-agent creates from recurring patterns in meta-notes. They live in `learned-agents/<name>.md` in the project's `syndicate/` directory (not the skill-bundled `agents/` directory, which is fixed).

Before invoking, read the registry (`learned-agents/registry.jsonl`) and each candidate agent's "When to Invoke" field. Only invoke agents whose trigger conditions match the current situation. Most generations invoke zero learned agents.

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

Build a limited view first: scores, complexity, git log, diff stats. Never include code or file contents. The coherence agent has zero tool access (`tools: []` in its definition), so it can only reason about what you pass in the prompt.

```
Agent tool:
  description: "Gen <N>: coherence check"
  subagent_type: "syndicate:coherence"
  prompt: |
    Generation: <N>
    Branch: <current branch>

    Recent scores:
    <last 10 lines of metrics/scores.jsonl>

    Complexity trend:
    <last 10 lines of metrics/complexity.jsonl>

    Git log (last 10):
    <git log --oneline -10>

    Last change (file stats only):
    <git diff HEAD~1 --stat>

    Respond as JSON only.
```

The coherence agent's response omits `generation`. Add the current generation number before appending to `coherence-log.jsonl`.

If the coherence agent returns invalid JSON, treat it as `flag` with reason "coherence agent returned invalid response" and log that to `coherence-log.jsonl`.

For flag handling behavior, see SKILL.md step 5.

## Metrics Formats

All metrics files are append-only JSONL in `metrics/`.

### scores.jsonl

```jsonl
{"generation": 1, "scores": {"input_validation": 2, "error_messages": 1}, "avg": 1.5, "model": "haiku", "criteria_changed": false, "timestamp": "2026-03-23T14:30:00Z"}
```

### complexity.jsonl

```jsonl
{"generation": 1, "skill_tokens": 45, "prompt_tokens": 12, "file_count": 3, "learned_agent_count": 0, "learned_agent_invocations": 0}
```

Count non-retired entries in `learned-agents/registry.jsonl` for `learned_agent_count`. For `learned_agent_invocations`, count the learned agents invoked during the current generation.

### coherence-log.jsonl

```jsonl
{"generation": 1, "status": "continue", "reason": "Scores improving, complexity stable"}
```

### archive/branches.jsonl

```jsonl
{"generation": 1, "branch": "gen-1", "parent": "seed", "score": 1.5, "pruned": false}
```

## Git Workflow

Each generation gets a branch. Commit messages should be a single sentence.

At bootstrap, the initial commit is tagged `seed`. Generation 1 branches from `seed`.

```bash
git checkout -b gen-<N> <parent-branch>
# ... make changes, produce attempt ...
git add -A
git commit -m "gen-<N>: <one sentence>"
```

### Parent Selection

Read `archive/branches.jsonl`. Highest-scoring non-pruned branch ~70% of the time. Random non-pruned branch ~30% for exploration.

## Promoting Learnings

After recording observations in meta-notes, evaluate whether any pattern is ready for promotion. Promote when:
- **Recurrence:** the pattern keeps coming up
- **Actionability:** it's reusable, not just an observation

The meta-agent decides the form:
- **Procedure** (takes input, produces output, works independently) → create a **learned agent** in `learned-agents/<name>.md`
- **Knowledge** (techniques, patterns, domain facts that inform work) → create or update a **domain skill** in `skills/domain/<name>.md`

### Creating a Learned Agent

Write the agent definition to `learned-agents/<name>.md`:

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

Append to `learned-agents/registry.jsonl`:

```jsonl
{"name": "<name>", "promoted_at": <gen>, "last_revised": <gen>, "invocations": 0, "last_invoked": null, "retired": false}
```

Note the promotion in meta-notes: `Promoted to agent: <name> (reason: <one sentence>)`.

### Evolving Learned Agents and Skills

Learned agents and domain skills are living documents. Revise them as understanding deepens. A learned agent promoted at gen-5 may be substantially different by gen-20. Update `last_revised` in the registry when revising an agent.

### Retiring Learned Agents

Retire learned agents that are no longer pulling their weight. Set `retired: true` in the registry. No fixed rules. The coherence agent monitors complexity growth and will flag if proliferation outpaces improvement.

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

Tracks provenance and lifecycle for all domain skills, both imported and locally promoted. One line per skill.

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
├── goal.md              # User's goal (written gen 1, fixed)
├── criteria.md          # Acceptance criteria (evolves)
├── meta-notes.md        # Persistent memory (distilled periodically)
├── venture.jsonl         # Round history (venture mode only, distilled periodically)
├── skills-manifest.jsonl # Provenance and lifecycle for domain skills
├── skills/
│   ├── approach.md
│   └── domain/          # Domain-specific skills (promoted or imported)
├── prompts/
│   └── task.md
├── learned-agents/      # Specialized agents promoted from learnings (evolves)
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
