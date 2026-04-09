# Syndicate v0.7.0 Improvements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Improve the syndicate plugin with skill discovery, task agent briefing, variant merging, baseline-sync simplification, and housekeeping fixes.

**Architecture:** All changes are to markdown instruction files and one new shell script under `plugin/`. No runtime code, no test framework. The plugin is a set of instructions that Claude Code interprets at runtime. Edits are to four files: `SKILL.md`, `references/loop.md`, `templates/prompts/task.md`, and a new `templates/baseline-sync.sh`.

**Tech Stack:** Markdown, Bash (shell script), JSONL formats

**Spec:** `docs/superpowers/specs/2026-04-09-syndicate-improvements-design.md`

---

### Task 1: Create baseline-sync.sh

The new shell script that replaces the 5-step inline git procedure for task agents.

**Files:**
- Create: `plugin/skills/run/templates/baseline-sync.sh`

- [ ] **Step 1: Create the script**

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

Write this to `plugin/skills/run/templates/baseline-sync.sh`.

- [ ] **Step 2: Make it executable**

Run: `chmod +x plugin/skills/run/templates/baseline-sync.sh`

- [ ] **Step 3: Commit**

```bash
git add plugin/skills/run/templates/baseline-sync.sh
git commit -m "Add baseline-sync.sh script to replace inline git procedure"
```

---

### Task 2: Update templates/prompts/task.md

Expand the task prompt from 3 lines to a full briefing with environment info and skill invocation instructions.

**Files:**
- Modify: `plugin/skills/run/templates/prompts/task.md` (entire file, 3 lines)

- [ ] **Step 1: Replace the entire file**

Replace the full contents of `plugin/skills/run/templates/prompts/task.md` with:

```markdown
<!-- Dynamic context passed via Agent tool prompt parameter. Static system prompt is in agents/task.md. -->
# Task Prompt

You are a task agent in a syndicate: an iterative, self-governing system that evolves a deliverable.

## Environment

You have access to standard tools: Bash, Read, Write, Edit, Grep, Glob, Agent.

## Available Skills

The following skills can be invoked using the Skill tool. Use them when their description matches what you're doing.

{{SKILLS_BLOCK}}

To invoke a skill: use the Skill tool with the skill name (e.g., `skill: "voice-check:writing-guard"`).

## Your Task

Read the goal carefully. Produce the complete deliverable. Follow the skills provided below.
```

- [ ] **Step 2: Commit**

```bash
git add plugin/skills/run/templates/prompts/task.md
git commit -m "Expand task prompt template with environment and skill briefing"
```

---

### Task 3: Update SKILL.md (Setup, Discovery, Step 7)

Three changes to `plugin/skills/run/SKILL.md`: bootstrap includes baseline-sync.sh, discovery pass indexes installed skills, and step 7 gets the combine path.

**Files:**
- Modify: `plugin/skills/run/SKILL.md`

- [ ] **Step 1: Update Setup step 1 to include baseline-sync.sh**

In the Setup section (line 16), the current step 1 reads:

```
1. Copy `templates/` to `syndicate/` in the project root.
```

Replace with:

```
1. Copy `templates/` to `syndicate/` in the project root. Ensure `syndicate/baseline-sync.sh` is executable (`chmod +x`).
```

- [ ] **Step 2: Expand Setup step 4 (discovery pass)**

The current step 4 (line 19) reads:

```
4. Run the discovery pass (see `references/loop.md` "Discovery at Gen 0") to index user-level agents and skills into `syndicate/discovered.jsonl`. If `~/.claude/syndicate-manifest.jsonl` does not exist, write an empty `discovered.jsonl` and continue.
```

Replace with:

```
4. Run the discovery pass (see `references/loop.md` "Discovery at Gen 0") to index agents and skills into `syndicate/discovered.jsonl`:
   - Read `~/.claude/syndicate-manifest.jsonl` for syndicate-promoted artifacts (`"origin": "syndicate"`). If the file does not exist (first-ever run on this machine), skip this source.
   - Scan the system reminder's skill list for installed plugin skills. Write each with `"origin": "installed-plugin"`, `"kind": "skill"`, name, and description.
   - If neither source yields entries, write an empty `discovered.jsonl` and continue.
```

- [ ] **Step 3: Add combine path to step 7**

The current step 7 (line 53) reads:

```
7. **Squash-merge best, clean up rest.** Squash the winner onto `syndicate/run-<N>` as a single commit: `gen-<G>: <one sentence>`. Mark others pruned in `branches.jsonl`. Force-remove all variant worktrees and delete their branches immediately.
```

Replace with:

```
7. **Merge best, clean up rest.** After scoring, evaluate whether variants have complementary strengths:
   - **Single winner (default):** One variant dominates across criteria. Squash-merge onto `syndicate/run-<N>` as `gen-<G>: <one sentence>`. Mark others pruned in `branches.jsonl`.
   - **Combine:** Variants excel on different criteria and their file changes don't overlap. Check file-level overlap: run `git diff --name-only` for each variant relative to baseline. If any file appears in more than one variant's diff, fall back to single winner. Otherwise, apply each variant's changes via `git checkout <variant-branch> -- <files>` and commit as `gen-<G>: combined (<variants>): <one sentence>`. Mark contributing variants with `"pruned": false, "combined": true` in `branches.jsonl`. Score the combined result for `scores.jsonl`. Document in meta-notes which variants were combined and which criteria each addressed.
   Force-remove all variant worktrees and delete their branches immediately after merging.
```

- [ ] **Step 4: Commit**

```bash
git add plugin/skills/run/SKILL.md
git commit -m "Update SKILL.md: baseline-sync, expanded discovery, variant combine path"
```

---

### Task 4: Update references/loop.md (Task Agent section)

Simplify the baseline-sync instructions and update the task agent invocation template.

**Files:**
- Modify: `plugin/skills/run/references/loop.md`

- [ ] **Step 1: Replace the baseline-sync block**

In the Task Agent section, the current worktree baseline-sync block (lines 34-42) reads:

```
**Worktree baseline-sync (mandatory).** Due to anthropics/claude-code#45371, `isolation: "worktree"` currently forks from the default branch instead of the caller's current HEAD, so the task agent will not see prior generations' winners. Every task-agent prompt MUST include these mandatory first steps:

1. `git log --oneline -5` (you will see the default branch's tip, not `syndicate/run-<N>`)
2. `git checkout syndicate/run-<N> -- plugin/ syndicate/` (pulls baseline files from shared object store)
3. `git commit -m "baseline-sync: pull syndicate/run-<N> into worktree"`
4. Verify gen landmarks with grep before starting work; abort to `attempts/gen-<N>-<V>/BASE_ERROR.md` if missing
5. All variant edits sit ON TOP of the baseline-sync commit

The meta-agent extracts each variant's incremental work with `git diff baseline-sync HEAD -- plugin/ syndicate/attempts/gen-<N>-<V>/` and applies that delta (not the whole branch) to `syndicate/run-<N>`. Remove this workaround when the upstream bug is fixed.
```

Replace with:

```
**Worktree baseline-sync (mandatory).** Due to anthropics/claude-code#45371, `isolation: "worktree"` currently forks from the default branch instead of the caller's current HEAD, so the task agent will not see prior generations' winners. Every task-agent prompt MUST include this instruction:

> Before starting work, run: `bash syndicate/baseline-sync.sh syndicate/run-<N>`
> If it fails, write `BASE_ERROR.md` to your output directory explaining the error and stop.

The script checks out all files from the run branch, commits the sync, and verifies `syndicate/` landed. All variant edits sit on top of the baseline-sync commit.

The meta-agent extracts each variant's incremental work with `git diff baseline-sync HEAD` and applies that delta (not the whole branch) to `syndicate/run-<N>`. Remove this workaround (script + prompt instruction) when anthropics/claude-code#45371 is fixed.
```

- [ ] **Step 2: Update the task agent invocation template**

The current invocation template (lines 16-30) shows:

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

Replace with:

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

- [ ] **Step 3: Commit**

```bash
git add plugin/skills/run/references/loop.md
git commit -m "Simplify baseline-sync to script invocation, update task agent template"
```

---

### Task 5: Update references/loop.md (Discovery section)

Update the "Discovery at Gen 0" section to include installed plugin skills and update the ranking formula scope.

**Files:**
- Modify: `plugin/skills/run/references/loop.md`

- [ ] **Step 1: Update the discovery procedure**

The current procedure (lines 270-275) reads:

```
Procedure:

1. Read `~/.claude/syndicate-manifest.jsonl` if it exists. Skip entries where `retired: true`. If the file is missing (first-ever syndicate run on this machine), write an empty `syndicate/discovered.jsonl` and skip the rest of this procedure.
2. For each non-retired entry, read the `description` field and, if useful, the artifact's frontmatter. Do **not** inline full contents.
3. Write `syndicate/discovered.jsonl` (one line per candidate): name, kind, path, description. Per-run ephemeral metadata.
4. The meta-agent keeps the index in working context so Diagnose and Propose Changes can reference candidates by name and description.
5. Load full artifact contents **only when** a candidate's trigger conditions match the situation at generation time (same gating as learned-agent invocation). This bounds per-generation token load even as the user library grows.
```

Replace with:

```
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
```

- [ ] **Step 2: Scope the ranking formula**

After the ranking formula section (line 280), the text begins with "As the user library grows...". Add a scoping note after the formula definition. Find:

```
    rank = 0.5 * desc_match + 0.2 * use_signal + 0.3 * quality
```

After the full paragraph that follows this formula (ending with "...so they compete on description alone."), add:

```
This ranking formula applies to `"origin": "syndicate"` entries only. Installed-plugin entries (`"origin": "installed-plugin"`) have no usage stats in the manifest; rank them by `desc_match` alone.
```

- [ ] **Step 3: Commit**

```bash
git add plugin/skills/run/references/loop.md
git commit -m "Expand discovery pass to index installed plugin skills"
```

---

### Task 6: Update references/loop.md (Finding Skills, branches.jsonl, reports)

Three housekeeping changes: update the import procedure to use discovery index, add `combined` field to branches.jsonl, and add Upstream Recommendations to report templates.

**Files:**
- Modify: `plugin/skills/run/references/loop.md`

- [ ] **Step 1: Rewrite the "Finding Skills" subsection**

The current subsection under "Importing External Skills" (lines 295-296) reads:

```
### Finding Skills

Browse `~/.claude/plugins/` for installed plugins. Look in each plugin's `skills/` directory for skill files matching the syndicate's current needs.
```

Replace with:

```
### Finding Skills

Check `syndicate/discovered.jsonl` for `"origin": "installed-plugin"` entries matching the current need. Use the Skill tool to load the full content of the matching skill. Fall back to browsing `~/.claude/plugins/` only if `discovered.jsonl` is empty or stale.
```

- [ ] **Step 2: Add `combined` field to branches.jsonl format**

In the branches.jsonl format section, the example lines (lines 163-164) show:

```jsonl
{"generation": 3, "variant": "a", "branch": "gen-3-a", "parent": "gen-2-a", "score": 3.2, "pruned": true, "operator": "rewrite", "change": "switched to grid layout"}
{"generation": 3, "variant": "b", "branch": "gen-3-b", "parent": "gen-2-a", "score": 4.1, "pruned": false, "operator": "constrain", "change": "added responsive breakpoints"}
```

Replace with:

```jsonl
{"generation": 3, "variant": "a", "branch": "gen-3-a", "parent": "gen-2-a", "score": 3.2, "pruned": true, "combined": false, "operator": "rewrite", "change": "switched to grid layout"}
{"generation": 3, "variant": "b", "branch": "gen-3-b", "parent": "gen-2-a", "score": 4.1, "pruned": false, "combined": false, "operator": "constrain", "change": "added responsive breakpoints"}
```

After the existing paragraph that follows ("One line per variant..."), add:

```
When variants are combined (see SKILL.md step 7), all contributing variants have `"pruned": false, "combined": true`. Non-contributing variants in the same generation are still `"pruned": true, "combined": false`.
```

- [ ] **Step 3: Add Upstream Recommendations to Round Report Format**

In the Round Report Format section, after the `## Next Round Focus` block, add:

```markdown
## Upstream Recommendations (optional)
<Include only if the syndicate has `upstream-recommendation:` entries in meta-notes. For each: skill name, what was changed, why it helps.>
```

- [ ] **Step 4: Add Upstream Recommendations to Dissolution Report Format**

In the Dissolution Report Format section, after the `## Deliverable` block, add:

```markdown
## Upstream Recommendations (optional)
<Include only if the syndicate has `upstream-recommendation:` entries in meta-notes. For each: skill name, what was changed, why it helps.>
```

- [ ] **Step 5: Commit**

```bash
git add plugin/skills/run/references/loop.md
git commit -m "Housekeeping: discovery index for imports, combined field, upstream recommendations in reports"
```

---

### Task 7: Update plugin.json version

Bump the version to 0.7.0.

**Files:**
- Modify: `plugin/.claude-plugin/plugin.json`

- [ ] **Step 1: Update version**

In `plugin/.claude-plugin/plugin.json`, change:

```json
"version": "0.6.0",
```

to:

```json
"version": "0.7.0",
```

- [ ] **Step 2: Commit**

```bash
git add plugin/.claude-plugin/plugin.json
git commit -m "Bump plugin version to 0.7.0"
```
