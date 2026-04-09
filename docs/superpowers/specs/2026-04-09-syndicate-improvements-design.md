# Syndicate Plugin Improvements: v0.7.0

Spec for four improvements to the syndicate plugin plus two housekeeping fixes. All changes target files under `plugin/`.

## 1. Skill Discovery: Index Installed Plugin Skills

### Problem

The Gen 0 discovery pass only reads `~/.claude/syndicate-manifest.jsonl`, which contains artifacts the syndicate itself promoted. Skills installed via other plugins (available through the Skill tool and listed in the system reminder) are invisible. The syndicate can't reason about, delegate, or build on the user's existing skill ecosystem.

### Design

Expand the Gen 0 discovery pass to harvest installed skills from the system reminder.

**Bootstrap addition (SKILL.md, Setup step 4):**

1. After reading `~/.claude/syndicate-manifest.jsonl`, parse the system reminder's skill list. Each entry has a name (e.g. `superpowers:test-driven-development`) and a description.
2. Write each to `discovered.jsonl` with `"origin": "installed-plugin"`:
   ```jsonl
   {"name": "superpowers:test-driven-development", "kind": "skill", "origin": "installed-plugin", "description": "Use when implementing any feature or bugfix..."}
   ```
3. Existing syndicate-manifest entries continue to be written with `"origin": "syndicate"`.

**Usage during the loop (meta-agent Diagnose/Propose):**

The meta-agent reviews `discovered.jsonl` at each generation's Diagnose step. When a discovered skill's description matches the current work, it includes the skill in the task agent's prompt (see issue 2 below). The ranking formula in loop.md applies to syndicate-origin entries only; installed-plugin entries are ranked by description match alone (no usage stats tracked for external skills).

**Promotion of installed skills:**

When the syndicate wants to modify an installed skill, it follows the existing import procedure: copy to `skills/domain/`, mark `"origin": "import"` in `skills-manifest.jsonl`. The imported copy diverges freely.

New: when the syndicate discovers an improvement that could benefit the original installed skill, note the recommendation in meta-notes with the tag `upstream-recommendation:` and include it in the dissolution or round report under a new "Upstream Recommendations" section. This gives the user actionable feedback without silently diverging.

### Files Changed

- `plugin/skills/run/SKILL.md`: Setup step 4 expanded
- `plugin/skills/run/references/loop.md`: "Discovery at Gen 0" section updated, "Importing External Skills > Finding Skills" updated to prefer `discovered.jsonl` over filesystem scanning

## 2. Task Agent Briefing

### Problem

`templates/prompts/task.md` is three lines. Task agents don't know what tools they have, what skills are available, or how to invoke skills via the Skill tool.

### Design

Expand the task prompt template to orient the agent on its environment.

**New `templates/prompts/task.md`:**

```markdown
# Task Prompt

You are a task agent in a syndicate: an iterative, self-governing system that evolves a deliverable.

## Environment

You have access to standard tools: Bash, Read, Write, Edit, Grep, Glob, Agent.

## Available Skills

The following skills can be invoked using the Skill tool. Use them when their description matches what you're doing.

{{SKILLS_BLOCK}}

To invoke: use the Skill tool with the skill name (e.g., `skill: "voice-check:writing-guard"`).

## Your Task

Read the goal carefully. Produce the complete deliverable. Follow the skills provided below.
```

The `{{SKILLS_BLOCK}}` placeholder is replaced by the meta-agent at invocation time with a list of relevant skills: both syndicate-owned skills (inlined as full content, same as today) and installed plugin skills (name + description only, since the Skill tool loads full content on demand).

**Invocation template update (loop.md, Task Agent section):**

```
prompt: |
  <contents of prompts/task.md, with {{SKILLS_BLOCK}} replaced>

  Goal:
  <contents of goal.md>

  Criteria:
  <contents of criteria.md>

  Output directory: syndicate/attempts/gen-<N>-<V>/
  Put all output files in the output directory above. Create it if needed.
```

The meta-agent selects which installed skills to include based on description relevance to the current generation's focus. Not every skill appears every generation. Syndicate-owned skills (approach.md, domain skills) are always included.

### Clarifying the task.md / agents/task.md relationship

`agents/task.md` is the static system prompt (set by Claude Code when the agent is registered). `templates/prompts/task.md` is dynamic context passed via the `prompt` parameter at invocation. Add a one-line comment to the top of `templates/prompts/task.md`:

```markdown
<!-- Dynamic context passed via Agent tool prompt parameter. Static system prompt is in agents/task.md. -->
```

### Files Changed

- `plugin/skills/run/templates/prompts/task.md`: expanded with environment and skills sections
- `plugin/skills/run/references/loop.md`: Task Agent invocation template updated

## 3. Variant Merge (the "both/and" case)

### Problem

Step 7 of the generation loop always picks one winner and prunes the rest. When variants produce complementary, non-overlapping work (e.g., one does implementation, another does documentation), valuable work is discarded.

### Design

Add a "combine" path between scoring (step 4) and squash-merge (step 7).

**Updated step 7 in SKILL.md:**

After scoring, the meta-agent evaluates whether variants have complementary strengths:

1. **Single winner (default):** One variant dominates across criteria. Pick it, prune the rest. Existing behavior.
2. **Combine:** Variants excel on different criteria and their file changes don't overlap. The meta-agent cherry-picks contributions from multiple variants onto `syndicate/run-<N>`:
   a. Check file-level overlap: `git diff --name-only` for each variant relative to the baseline. If any files appear in more than one variant's diff, fall back to single winner.
   b. Apply each variant's non-overlapping changes sequentially via `git checkout <variant-branch> -- <files>`.
   c. Commit as: `gen-<G>: combined (<variants>): <one sentence>`.
   d. Record in `branches.jsonl` with `"pruned": false, "combined": true` for all contributing variants. Non-contributing variants are still pruned.
   e. Score the combined result. This is the score that goes to `scores.jsonl`.
   f. Note in meta-notes what was combined and why.

**Coherence agent impact:** None. The coherence agent sees one score entry per generation regardless. The commit message mentions "combined" which gives it a signal, but it doesn't need structural changes.

**Guard rails:**

- File overlap check is mandatory. No conflict resolution logic. Overlapping changes mean fall back to pick-one.
- The meta-agent must articulate why the contributions are complementary in meta-notes. "Both had some good stuff" is not sufficient; the rationale should reference specific criteria each variant addressed.
- Combining is optional. The meta-agent can always fall back to single winner. This is a permission, not a mandate.

### Files Changed

- `plugin/skills/run/SKILL.md`: Step 7 expanded with combine path
- `plugin/skills/run/references/loop.md`: `branches.jsonl` format updated (new `combined` field), brief note in Git Workflow section

## 4. Baseline-Sync Script

### Problem

The mandatory 5-step baseline-sync in every task agent prompt (working around anthropics/claude-code#45371) is frequently misexecuted by task agents. Multi-step git procedures expressed as natural language instructions are fragile when interpreted by LLMs.

### Design

Replace the inline instructions with a shell script committed at bootstrap.

**New file: `templates/baseline-sync.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

BRANCH="${1:?Usage: baseline-sync.sh <run-branch>}"

echo "Syncing baseline from $BRANCH..."
git checkout "$BRANCH" -- .
git commit -m "baseline-sync: pull $BRANCH into worktree"

# Verify the syndicate directory landed
if [ ! -d "syndicate" ]; then
  echo "ERROR: syndicate/ not found after checkout"
  exit 1
fi

echo "Baseline sync complete."
```

**Bootstrap change (SKILL.md, Setup step 1):** When copying templates to `syndicate/`, also copy `baseline-sync.sh` and `chmod +x` it.

**Task agent prompt change:** Replace the 5-step baseline-sync instructions with:

```
Before starting work, run: bash syndicate/baseline-sync.sh syndicate/run-<N>
If it fails, write BASE_ERROR.md to your output directory explaining the error and stop.
```

**Meta-agent diff extraction:** Unchanged. The meta-agent still extracts incremental work via `git diff baseline-sync HEAD`.

**Removal plan:** Add a comment in loop.md noting this workaround exists for anthropics/claude-code#45371 and should be removed when the upstream bug is fixed.

### Files Changed

- `plugin/skills/run/templates/baseline-sync.sh`: new file
- `plugin/skills/run/SKILL.md`: Setup step 1 updated
- `plugin/skills/run/references/loop.md`: Task Agent section simplified, workaround removal note added

## 5. Housekeeping: Import Procedure Uses Discovery Index

### Problem

The "Importing External Skills > Finding Skills" section in loop.md tells the meta-agent to browse `~/.claude/plugins/` directly. With issue 1 adding installed skills to `discovered.jsonl`, this filesystem scanning is redundant and could find unregistered skills.

### Design

Update the "Finding Skills" subsection to:

1. Check `discovered.jsonl` for installed-plugin entries matching the need
2. Use the Skill tool to load the full content of the matching skill
3. Only fall back to filesystem browsing if `discovered.jsonl` is empty or stale

### Files Changed

- `plugin/skills/run/references/loop.md`: "Finding Skills" subsection rewritten

## 6. Housekeeping: Report Template Updates

### Problem

Round reports and dissolution reports don't surface upstream skill improvement recommendations.

### Design

Add an "Upstream Recommendations" section to both report templates in loop.md. This section is optional: only included when the syndicate has `upstream-recommendation:` entries in meta-notes.

```markdown
## Upstream Recommendations
<Skills the syndicate imported and improved. For each: skill name, what was changed, why it helps.>
```

### Files Changed

- `plugin/skills/run/references/loop.md`: Round Report Format and Dissolution Report Format updated

## Summary of All Files Changed

| File | Changes |
|------|---------|
| `plugin/skills/run/SKILL.md` | Setup step 1 (baseline script), step 4 (expanded discovery), step 7 (combine path) |
| `plugin/skills/run/references/loop.md` | Discovery section, Task Agent invocation, Finding Skills, baseline-sync simplification, branches.jsonl format, report templates |
| `plugin/skills/run/templates/prompts/task.md` | Expanded with environment, skills, and clarifying comment |
| `plugin/skills/run/templates/baseline-sync.sh` | New file |

No changes to `agents/task.md` or `agents/coherence.md` (these are fixed by design).
