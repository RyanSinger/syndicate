# Native Agents Refactor

Replace `CLAUDECODE= claude -p` shell invocations with Claude Code's native Agent tool. Update the model policy from "start cheap, upgrade" to "start strong, downgrade."

## Agent Definitions

Add YAML frontmatter to the existing agent files in `plugin/skills/run/agents/`. The body (system prompt) of each file stays the same.

### Coherence agent (`agents/coherence.md`)

```yaml
---
name: coherence
description: Detects derailment in the syndicate's evolution trajectory. Never sees code, skills, or prompts.
model: sonnet
tools: []
---
```

`tools: []` gives zero tool access. The coherence agent can only reason about what's in its prompt and return text. This is structurally stronger than `claude -p`, which gives default tool access.

### Task agent (`agents/task.md`)

```yaml
---
name: task
description: Produces the deliverable for each generation.
model: opus
---
```

Tools field is omitted intentionally: this means the task agent inherits all tools from the parent conversation, which is what we want since it needs to read files, write files, and run commands to produce the deliverable. The meta-agent composes the dynamic prompt and passes it via the Agent tool's `prompt` parameter.

## Invocation Pattern

Replace `CLAUDECODE= claude -p "..." --model <model>` Bash commands with Agent tool calls.

### Task agent invocation

The static system prompt is in the agent definition file. Dynamic context goes in the `prompt` parameter:

```
Agent tool:
  description: "Gen N: produce deliverable"
  subagent_type: "syndicate:task"
  model: opus (or downgraded model if evidence supports it)
  prompt: |
    <contents of prompts/task.md>

    Skills:
    <concatenated contents of skills/*.md and skills/domain/*.md>

    Goal:
    <contents of goal.md>

    Produce the deliverable. Put all output files in the current directory.
```

### Coherence agent invocation

Same pattern. The meta-agent composes the limited view and passes only metrics data:

```
Agent tool:
  description: "Gen N: coherence check"
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

### Learned agents invocation

Learned agents live in `syndicate/learned-agents/` (the project directory, not the plugin). The meta-agent reads the definition and passes it as the prompt to a general-purpose agent:

```
Agent tool:
  description: "Gen N: <agent name>"
  model: sonnet (or upgraded/downgraded based on evidence)
  prompt: |
    <contents of learned-agents/<name>.md>

    Context:
    <context as specified by the agent's 'Context Required' section>

    Provide your output as specified in your instructions.
```

This eliminates the `CLAUDECODE=` env var hack entirely.

**Agent identifier format:** Plugin agents are namespaced as `plugin-name:agent-name` (per Claude Code docs: "Plugin subagents appear as `<plugin-name>:<agent-name>`"). The plugin name is "syndicate" and the agent names are "task" and "coherence", so identifiers are `syndicate:task` and `syndicate:coherence`. Learned agents are not plugin agents; they use the general-purpose subagent type with a dynamic prompt.

## Coherence Firewall Protection

The firewall is enforced at two layers:

**Layer 1: Agent definition.** `tools: []` in the coherence agent frontmatter means zero tool access. It cannot read files, run commands, or access anything beyond what's in its prompt.

**Layer 2: Prompt composition.** The meta-agent controls what goes in the `prompt` parameter. SKILL.md and loop.md specify exactly what to include (scores, complexity, git log, diff stats) and what to never include (code, skills, prompts, criteria content).

The coherence agent's system prompt body is fixed and ships with the plugin. The meta-agent cannot modify it.

## Model Policy

The current policy ("start cheap, upgrade with evidence") is replaced by "start strong, downgrade with evidence."

**Task agent:** Starts on **opus**. Downgrade to sonnet if evidence shows the task is simple enough (scores near max on first attempt, straightforward deliverable). Never change model and approach in the same generation.

**Coherence agent:** Always **sonnet**. Fixed. No upgrades or downgrades.

**Learned agents:** Start on **sonnet**. Upgrade to opus or downgrade to haiku based on evidence.

**Rationale:** A wasted generation costs more than a better model. An opus task agent that converges in 2 generations is cheaper than a haiku agent that flounders for 5 and then gets upgraded anyway.

## Cron Runner Impact

The cron runner is invoked via `claude -p` from the shell wrapper. That entry point stays the same. But the cron runner, once running as a Claude session, uses the Agent tool for task and coherence agent invocations instead of shelling out to `claude -p`.

Update the cron plan's cron-runner.md to reference Agent tool invocations for task agent (step 6), coherence agent (step 10), and learned agents (step 3). Update model references to the new policy.

## Files Changed

**`plugin/skills/run/agents/task.md`**: Add frontmatter (name, description, model: opus). Body unchanged.

**`plugin/skills/run/agents/coherence.md`**: Add frontmatter (name, description, model: sonnet, tools: []). Body unchanged.

**`plugin/skills/run/SKILL.md`**: Update Model Selection section to new policy (opus for task, sonnet for coherence, sonnet for learned). Update The Coherence Firewall section to replace "runs as a different model via `claude -p`" with a description of the native agent invocation. Remove all references to `claude -p` throughout the file.

**`plugin/skills/run/references/loop.md`**: Rewrite Subagent Invocation section. Replace all `claude -p` code blocks with Agent tool patterns. Remove `CLAUDECODE=` env var instruction. Update model references.

**`docs/superpowers/plans/2026-03-24-venture-cron-jobs.md`**: Update cron-runner.md prompt to use Agent tool instead of `claude -p` for task, coherence, and learned agent invocations. Update model defaults: task agent to opus, coherence agent to sonnet, learned agents to sonnet. Replace the Rules section line "The coherence agent always runs on haiku. Start the task agent on haiku unless prior meta-notes show evidence the model is the ceiling" with the new policy. Implementation order: update loop.md first since cron-runner.md references it.

**`CLAUDE.md`**: Replace `CLAUDECODE= claude -p` convention with Agent tool convention. Update model descriptions in the Architecture section (task agent starts on opus, coherence agent always sonnet instead of current haiku references).
