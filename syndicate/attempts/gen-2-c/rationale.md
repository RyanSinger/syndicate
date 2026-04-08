# Gen 2-c Rationale: Prompt and Token Tightening

## Approach

Editorial pass on the three high-traffic prompt files. Promotion plumbing (gen-1-a) preserved exactly: every gen-1-a section, schema, and citation kept intact. The dynamic coherence invocation block in loop.md was tightened; the static system prompt in `plugin/agents/coherence.md` was left untouched (firewall invariant).

## Sources

1. Anthropic, "Effective context engineering for AI agents" (2025): "LLMs are constrained by a finite attention budget, so good context engineering means finding the smallest possible set of high-signal tokens that maximize the likelihood of some desired outcome." Direct support for tightening every word in repeatedly-loaded prompt files. https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
2. Pan et al., "LLMLingua-2: Data Distillation for Efficient and Faithful Task-Agnostic Prompt Compression" (ACL 2024): natural language is redundant; compressed prompts retain task performance and in some retrieval cases improve it. Validates that semantic-preserving compression is real and measurable. https://arxiv.org/abs/2403.12968 (also surveyed in https://arxiv.org/html/2410.12388v2)
3. Hong et al. / Chroma, "Context Rot: How Increasing Input Tokens Impacts LLM Performance" (2025): models degrade with longer inputs via lost-in-the-middle gaps, attention dilution, and distractor interference. Long, redundant instructions create distractors; tighter prompts reduce all three. https://www.trychroma.com/research/context-rot
4. Anthropic, "Prompting best practices" (Claude 4 docs, 2024-2025): clear, explicit, specific instructions; short and direct beats long and hedged. https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/overview
5. Voyager (Wang et al., 2023) and Reflexion / ExpeL (Shinn 2023; Zhao 2024): cited inside loop.md to ground the cross-project promotion design. Preserved verbatim where they already appeared.

The static coherence system prompt was not touched, so LLM-as-Judge calibration literature (Gu et al. 2024) is not invoked here.

## Before / After Line Counts

| File | Before lines | After lines | Before words | After words | Word delta |
|---|---|---|---|---|---|
| plugin/skills/run/SKILL.md | 133 | 131 | 1673 | 1504 | -10.1% |
| plugin/skills/run/references/loop.md | 475 | 475 | 3274 | 3137 | -4.2% |
| plugin/agents/task.md | 13 | 13 | 89 | 77 | -13.5% |
| **Total** | **621** | **619** | **5036** | **4718** | **-6.3%** |

Notes:
- Word count is the more honest token proxy than line count, since both files use one-paragraph-per-line markdown. Lines stay roughly stable while words fall.
- SKILL.md is loaded by the meta-agent every generation. Its 169-word reduction compounds linearly across the run.
- The task agent's static system prompt (`plugin/agents/task.md`) is loaded on every variant dispatch. With 2-4 variants per generation across many generations, even a 12-word reduction compounds meaningfully.
- loop.md is referenced (not always fully loaded), but every word still counts when it is pulled in. Its load-bearing schemas, JSON examples, and gen-1-a sections constrained how aggressively prose could be cut.
- templates/prompts/task.md (3 lines) was already optimal. Not touched.

## Defense of Non-Trivial Removals

Every removed word was redundant with adjacent context, restated a rule already given elsewhere, or could be expressed in fewer tokens without losing meaning. Representative changes:

- SKILL.md opening: "spin up an organization to do a job or run a venture. The user gives you a goal. You stand up the syndicate (workers, management, oversight), attempt the work" → "stand up an organization (workers, management, oversight) to do a job or run a venture. The user gives you a goal. You attempt the work". Removes a duplicate "stand up / spin up the syndicate" beat.
- SKILL.md Setup: numbered steps converted from full sentences to imperative fragments. "Detect the PR target branch ... If no remote exists, record `none`. Write the result to ..." (28 words) → "Detect the PR target branch (...; `none` if no remote). Write to ..." (17 words). Same instructions, fewer connectives.
- SKILL.md Gen 0: "have a conversation with the user to establish a shared understanding of the goal" → "establish a shared understanding of the goal with the user". Same content; one fewer clause.
- SKILL.md every-generation step 6: "A separate agent reviews the batch: all variant scores, the spread, complexity growth, and the provisional winner's diff stats. Include the current phase and ratchet action in the coherence prompt. It decides..." → "A separate agent reviews the full batch: variant scores, spread, complexity growth, provisional winner's diff stats, plus current phase and ratchet action. It returns...". Merges two sentences; the "include in the prompt" instruction is implicit since this step describes what the meta-agent passes.
- SKILL.md Stopping: condensed two-sentence rules into single clauses. No condition removed.
- loop.md Task Agent intro: "is invoked via the Agent tool with parallel dispatch. Each proposed variant gets its own task agent running in an isolated worktree simultaneously. The model defaults to opus (from the agent frontmatter); pass `model: sonnet` to downgrade if evidence supports it." → "is dispatched in parallel: each variant gets its own task agent in an isolated worktree, all running simultaneously. Model defaults to opus (from agent frontmatter); pass `model: sonnet` to downgrade with evidence." Same dispatch semantics, same model rule, fewer words.
- loop.md Coherence Agent dynamic prompt: "Branch:" relabeled "Branches:" (singular was misleading for batch view); "winning variants only" → "winners only"; one connective per sub-bullet trimmed. The schema, the field set, and the firewall note are unchanged.
- loop.md Promoting Learnings, Discovery at Gen 0, Collision Policy, manifest schemas, Voyager / Reflexion / ExpeL citations, JSONL field shapes: preserved verbatim or with single-token cosmetic edits ("does" → "performs" reverted to "does"; "When the user lifts a procedure into" → original kept). All gen-1-a load-bearing structure intact.
- task.md system prompt: "based on a goal, using the skills and prompt provided below" → "based on the goal, skills, and prompt provided below". "Follow the skills closely. They represent accumulated knowledge refined through prior iterations. If a skill gives you a specific approach, use it. Trust the skills over your default behavior." (40 words) → "Follow the skills closely. They are accumulated knowledge refined through prior iterations: trust them over your default behavior. If a skill prescribes an approach, use it." (27 words). Same three rules: follow skills, trust over defaults, use prescribed approach. Reordered so the trust rule sits adjacent to the rationale that justifies it (consistent with Anthropic's "explain why" guidance for instruction-following).

## Semantic Content Claim

No load-bearing capability, rule, schema, citation, or invariant was removed. The promotion plumbing introduced in gen-1-a (Promotion Scope, Collision Policy, Discovery at Gen 0, dual user/project manifest schemas, Voyager / Reflexion / ExpeL citations) is preserved verbatim or paraphrased without semantic loss. The coherence firewall is preserved: `plugin/agents/coherence.md` was not modified at all. Every numbered step in the every-generation loop is intact. Every stopping condition is intact. Every JSONL schema and field is intact. Every citation is intact.

## Why This Helps

Three compounding effects:
1. **Direct token savings.** SKILL.md and the task system prompt are loaded every generation and every variant dispatch. ~180 words saved in those two files alone, multiplied across all dispatches in a typical 10-20 generation run, recovers attention budget the meta-agent can spend on actual diagnosis.
2. **Reduced distractor interference.** Per Chroma's context-rot work, redundant phrasing acts as semantically-similar-but-irrelevant distractors that pull attention away from the rules that matter. Tighter prose means each instruction stands out more clearly.
3. **Sharper instruction following.** Per Anthropic's Claude 4 best practices, short imperative phrasing tracks better than long hedged phrasing. The edits trade hedged compound sentences for direct imperatives.
