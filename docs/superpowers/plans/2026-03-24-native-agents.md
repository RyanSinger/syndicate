# Native Agents Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `CLAUDECODE= claude -p` shell invocations with Claude Code's native Agent tool and update the model policy to "start strong, downgrade with evidence."

**Architecture:** Add YAML frontmatter to existing agent definition files to make them native Claude Code agents. Rewrite invocation patterns in loop.md from Bash commands to Agent tool calls. Update model defaults across all files. The spec is at `docs/superpowers/specs/2026-03-24-native-agents-design.md`.

**Tech Stack:** Markdown

---

### Task 1: Add frontmatter to agent definitions

**Files:**
- Modify: `plugin/skills/run/agents/task.md`
- Modify: `plugin/skills/run/agents/coherence.md`

**Context:** These files currently have no frontmatter. Adding it makes them native Claude Code agents that the Agent tool can reference by name. Read both files before starting. The user's global rule: NEVER use dashes (em dashes, en dashes, or hyphens as separators/punctuation) in any written content.

- [ ] **Step 1: Add frontmatter to task.md**

The current file starts with `# Task Agent`. Prepend frontmatter before the existing content:

```yaml
---
name: task
description: Produces the deliverable for each generation.
model: opus
---
```

The body stays exactly as-is. Tools field is omitted intentionally so the task agent inherits all tools from the parent conversation.

- [ ] **Step 2: Add frontmatter to coherence.md**

The current file starts with `# Coherence Agent`. Prepend frontmatter before the existing content:

```yaml
---
name: coherence
description: Detects derailment in the syndicate's evolution trajectory. Never sees code, skills, or prompts.
model: sonnet
tools: []
---
```

`tools: []` enforces the coherence firewall at the agent level. Zero tool access means it can only reason about what's in its prompt.

- [ ] **Step 3: Commit**

```bash
git add plugin/skills/run/agents/task.md plugin/skills/run/agents/coherence.md
git commit -m "Add native agent frontmatter to task.md and coherence.md"
```

### Task 2: Rewrite Subagent Invocation in loop.md

**Files:**
- Modify: `plugin/skills/run/references/loop.md`

**Context:** The Subagent Invocation section (lines 5-81) needs a complete rewrite. Read the full file and the spec's Invocation Pattern section before starting. The spec is at `docs/superpowers/specs/2026-03-24-native-agents-design.md`.

**Key principle:** The agent system prompt body (e.g., the contents of `agents/task.md`) is now loaded automatically from the agent definition file. Only dynamic context goes in the Agent tool's `prompt` parameter. This is why `<contents of agents/task.md>` no longer appears in the invocation pattern.

- [ ] **Step 1: Replace the entire Subagent Invocation section (lines 5-81)**

Replace everything from `## Subagent Invocation` through `For flag handling behavior, see SKILL.md step 5.` with the following. Note: the Agent tool invocation examples should use plain code fences (triple backticks) in the final loop.md file.

The new section should contain:

**Section header:** `## Subagent Invocation`

**Intro paragraph:** "Invoke subagents using the Agent tool. The plugin ships two agents (`syndicate:task` and `syndicate:coherence`) with static system prompts in `agents/`. Dynamic context goes in the Agent tool's `prompt` parameter."

**Task Agent subsection:** Heading `### Task Agent`. Explain that `syndicate:task` is invoked via the Agent tool. The model defaults to opus (from the agent frontmatter); pass `model: sonnet` to downgrade if evidence supports it. Show the Agent tool invocation pattern in a code fence with these fields: `description: "Gen <N>: produce deliverable"`, `subagent_type: "syndicate:task"`, and `prompt:` containing the dynamic context (contents of prompts/task.md, concatenated skills/*.md and skills/domain/*.md, contents of goal.md, and the line "Produce the deliverable. Put all output files in the current directory."). After the code fence: "Copy output into `attempts/gen-<N>/`."

**Learned Agents subsection:** Heading `### Learned Agents`. Keep the existing explanation (they live in `syndicate/learned-agents/`, read the registry, check trigger conditions, most generations invoke zero). Show the Agent tool invocation: `description: "Gen <N>: <agent name>"`, `model: sonnet`, `prompt:` containing the learned agent definition and context. Note: "Default to sonnet. Upgrade to opus or downgrade to haiku based on evidence." Keep the timing points (pre-generation and post-generation) and registry update instruction.

**Coherence Agent subsection:** Heading `### Coherence Agent`. Explain: "Build a limited view first: scores, complexity, git log, diff stats. Never include code or file contents. The coherence agent has zero tool access (`tools: []` in its definition), so it can only reason about what you pass in the prompt." Show the Agent tool invocation: `description: "Gen <N>: coherence check"`, `subagent_type: "syndicate:coherence"`, `prompt:` containing Generation, Branch, Recent scores (last 10 lines of scores.jsonl), Complexity trend (last 10 lines of complexity.jsonl), Git log (last 10), Last change (file stats only), and "Respond as JSON only." After the code fence, keep these three notes verbatim: (1) "The coherence agent's response omits `generation`. Add the current generation number before appending to `coherence-log.jsonl`." (2) "If the coherence agent returns invalid JSON, treat it as `flag` with reason "coherence agent returned invalid response" and log that to `coherence-log.jsonl`." (3) "For flag handling behavior, see SKILL.md step 5."

- [ ] **Step 2: Verify the rewrite**

Search loop.md for `CLAUDECODE` and `claude -p`. Confirm zero matches. Search for `syndicate:task` and `syndicate:coherence`. Confirm both are present.

- [ ] **Step 3: Commit**

~~~
git add plugin/skills/run/references/loop.md
git commit -m "Rewrite subagent invocations from claude -p to native Agent tool"
~~~

### Task 3: Update SKILL.md model policy and firewall description

**Files:**
- Modify: `plugin/skills/run/SKILL.md`

**Context:** Two sections need updating: The Coherence Firewall (line 44-46) and Model Selection (lines 48-52). Read the full file before starting.

- [ ] **Step 1: Update The Coherence Firewall section**

Replace line 46:

```
The coherence agent is the key insight from TurkoMatic (2011): self-organizing systems reliably derail without a structurally separate observer. It runs as a different model via `claude -p`. It never sees your code, skills, or prompts. Only fitness trajectories, complexity metrics, and commit messages. Its instructions (`agents/coherence.md`) are fixed and cannot be modified. This separation is the whole point.
```

with:

```
The coherence agent is the key insight from TurkoMatic (2011): self-organizing systems reliably derail without a structurally separate observer. It runs as a native subagent with zero tool access. It never sees your code, skills, or prompts. Only fitness trajectories, complexity metrics, and commit messages. Its instructions (`agents/coherence.md`) are fixed and cannot be modified. This separation is the whole point.
```

- [ ] **Step 2: Update Model Selection section**

Replace lines 48-52:

```
## Model Selection

Token cost compounds. Every word in skills and prompts gets multiplied across every task agent call, every generation.

Start the task agent on **haiku**. Upgrade to **sonnet** when you have evidence the model is the ceiling, not the approach. Use **opus** sparingly. Never change model and approach in the same generation. The coherence agent always runs on **haiku**.
```

with:

```
## Model Selection

A wasted generation costs more than a better model. Start strong, downgrade with evidence.

Start the task agent on **opus**. Downgrade to **sonnet** if evidence shows the task is simple enough (scores near max on first attempt, straightforward deliverable). Never change model and approach in the same generation. The coherence agent always runs on **sonnet**. Learned agents default to **sonnet**.
```

- [ ] **Step 3: Commit**

```bash
git add plugin/skills/run/SKILL.md
git commit -m "Update model policy: start opus, coherence on sonnet"
```

### Task 4: Update CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

**Context:** Two areas need updating: the Architecture section (lines 16-17) and the Key Conventions section (line 36). Read the full file before starting.

- [ ] **Step 1: Update Architecture agent descriptions**

Replace lines 16-17:

```
- **Task agent** (subagent via `claude -p`): produces the deliverable each generation. Starts on haiku, upgrades only with evidence
- **Coherence agent** (subagent via `claude -p`, always haiku): watches fitness trajectories and complexity metrics only. Never sees code, prompts, or skills. Its prompt (`agents/coherence.md`) is fixed and must not be modified
```

with:

```
- **Task agent** (native subagent, starts on opus): produces the deliverable each generation. Downgrade to sonnet with evidence
- **Coherence agent** (native subagent, always sonnet, zero tool access): watches fitness trajectories and complexity metrics only. Never sees code, prompts, or skills. Its prompt (`agents/coherence.md`) is fixed and must not be modified
```

- [ ] **Step 2: Update Key Conventions**

Replace line 36:

```
- Subagents are invoked with `CLAUDECODE= claude -p "..."` (stripping env var enables nesting)
```

with:

```
- Subagents are invoked using the Agent tool. Plugin agents (`syndicate:task`, `syndicate:coherence`) have static system prompts; dynamic context goes in the prompt parameter
```

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "Update CLAUDE.md: native agents, opus/sonnet model policy"
```

### Task 5: Update cron plan

**Files:**
- Modify: `docs/superpowers/plans/2026-03-24-venture-cron-jobs.md`

**Context:** The cron plan's cron-runner.md prompt and Rules section reference `claude -p` and the old model policy. Read the full cron plan before starting. Implementation note: this plan should be implemented after Tasks 1-4 since cron-runner.md references loop.md.

- [ ] **Step 1: Update cron-runner.md steps that invoke subagents**

In the cron-runner.md prompt (inside the Task 3 code block, around line 120):

Step 6 says "**Attempt**: invoke the task agent subagent per loop.md." This is fine as-is because it references loop.md which is now updated.

Step 10 says "**Coherence check**: invoke the coherence agent per loop.md." Also fine as-is.

Step 3 says "Check `syndicate/learned-agents/registry.jsonl` for agents to invoke." Also fine.

No changes needed to these steps since they delegate to loop.md.

- [ ] **Step 2: Update the Rules section**

In the cron-runner.md Rules section (around line 168-175), replace:

```
- The coherence agent always runs on haiku. Start the task agent on haiku unless prior meta-notes show evidence the model is the ceiling.
```

with:

```
- The coherence agent always runs on sonnet. Start the task agent on opus. Downgrade to sonnet if prior meta-notes show evidence the task is simple enough.
```

- [ ] **Step 3: Update the cron-runner.sh model flag**

In the cron-runner.sh script (around line 240), the shell wrapper invokes Claude with `--model sonnet`. This is the cron runner session itself (the meta-agent), not the task/coherence subagents. This is fine as-is: the meta-agent session runs on sonnet, and the Agent tool invocations within it specify their own models.

No change needed.

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/plans/2026-03-24-venture-cron-jobs.md
git commit -m "Update cron plan: sonnet coherence, opus task agent"
```

### Task 6: Final verification

- [ ] **Step 1: Verify agent definitions**

Read both agent files and confirm:
1. `plugin/skills/run/agents/task.md` has frontmatter with `name: task`, `model: opus`, no tools field
2. `plugin/skills/run/agents/coherence.md` has frontmatter with `name: coherence`, `model: sonnet`, `tools: []`
3. Both files' body content is unchanged from before the refactor

- [ ] **Step 2: Verify loop.md invocation patterns**

Read the Subagent Invocation section of loop.md and confirm:
1. No `CLAUDECODE=` or `claude -p` references remain
2. Task agent uses `subagent_type: "syndicate:task"`
3. Coherence agent uses `subagent_type: "syndicate:coherence"`
4. Learned agents use general-purpose agent with dynamic prompt
5. Coherence agent section still has the generation field note, invalid JSON recovery, and flag handling cross-reference
6. Task agent model is opus, coherence is sonnet, learned agents default sonnet

- [ ] **Step 3: Verify SKILL.md**

Read SKILL.md and confirm:
1. The Coherence Firewall section says "native subagent with zero tool access" not "via `claude -p`"
2. Model Selection says opus for task, sonnet for coherence, sonnet for learned
3. No `claude -p` references remain anywhere in the file

- [ ] **Step 4: Verify CLAUDE.md**

Read CLAUDE.md and confirm:
1. Architecture section says "native subagent" not "via `claude -p`"
2. Task agent described as starting on opus, coherence as always sonnet
3. Key Conventions references Agent tool, not `CLAUDECODE= claude -p`

- [ ] **Step 5: Verify cron plan**

Read the cron plan and confirm:
1. Rules section says sonnet for coherence, opus for task
2. No `claude -p` references in the cron-runner.md prompt for subagent invocations (the `claude -p` in cron-runner.sh for the entry point is correct and should remain)

- [ ] **Step 6: Cross-file consistency**

Verify:
- Model defaults are consistent across all files (opus task, sonnet coherence, sonnet learned)
- The coherence firewall description is consistent between SKILL.md, CLAUDE.md, and coherence.md frontmatter
- Loop.md invocation patterns match the agent frontmatter (correct names, models)
