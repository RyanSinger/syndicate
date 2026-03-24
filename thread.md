**1/** I built a self-governing AI agent that spins up a temporary organization to do a job — it iterates on its own work, decides which models to use, and knows when to stop. It's a Claude Code plugin called Syndicate. Install it, tell it what you need, and walk away.

MIT licensed.

**2/** Last week Meta dropped HyperAgents — self-referential agents that modify their own improvement process. The key result: meta-level improvements like persistent memory and performance tracking emerge spontaneously and transfer across domains. Genuinely interesting work.

arxiv.org/abs/2603.19461

**3/** But it has a structural vulnerability that was identified and solved in a completely different field fifteen years ago.

**4/** In 2011, TurkoMatic (Kulkarni, Can & Hartmann) built a system where Mechanical Turk crowds recursively decomposed and solved complex tasks. The crowd was simultaneously labor and management. Structurally identical to what HyperAgents does with LLMs.

**5/** TurkoMatic's dominant failure mode was "derailment" — the recursive process spiraling into complexity without coherence. Their fix: a structurally separate observer who could monitor and prune the self-organizing workflow. Without it, the system reliably failed.

**6/** HyperAgents has no equivalent. The meta-agent modifies itself with no external coherence check beyond benchmark scores, which can only detect derailment after it's already happened.

**7/** Syndicate fixes this with three-tier governance — the same pattern as corporate structure:

Board = coherence agent (sees only trajectories, prunes bad branches)
Management = meta-agent (modifies skills and prompts)
Operations = task agent (produces the deliverable)

**8/** The firewall: the coherence agent runs as a separate claude invocation with a different model. It never sees code — only fitness trajectories, complexity metrics, and commit messages. Its prompt is fixed and cannot be modified by the meta-agent. That's the whole trick.

**9/** The system is cost-aware. Every word added to skills gets multiplied across every task, every generation. The meta-agent must justify token cost against expected score gain before modifying anything. It starts with haiku and upgrades models only when it has evidence the model is the bottleneck.

**10/** It's also self-governing. No generation count. The coherence agent is the termination condition. You say "build me an app that tracks invoices" or "write a partnership agreement for X" and the syndicate spins up, iterates on its own approach, and ships when it converges.

**11/** The whole thing is markdown files, git branches, and claude -p subagent calls. No framework. No dependencies. No build step. Install the plugin, ask Claude to do something, and it stands up the syndicate, does the work, and dissolves when the job is done.

```
/install-github-plugin RyanSinger/syndicate
```

github.com/RyanSinger/syndicate

**12/** The deeper point: the AI self-improvement crowd frames recursive self-modification as an alignment problem. The crowdsourcing and org design people framed the same problem as a governance question. The second framing gives you concrete architecture. The first gives you existential hand-wringing.

Read outside your silo.
