# Architecture

## Why This Exists

**HyperAgents** (Meta, 2026) showed that self-referential agents can bootstrap persistent cognitive infrastructure that transfers across domains. But no structural defense against derailment.

**TurkoMatic** (Kulkarni, Can & Hartmann, 2011) built a structurally identical system using Mechanical Turk crowds as both labor and management. Key findings:

- Without a separate observer, the system reliably failed
- Dominant failure: *derailment*: recursive self-organization spiraling into complexity without coherence
- Fix: a structurally separate requester maintaining coherence while the system evolved
- Workers self-assessing tractability prevented runaway decomposition

## Three-Tier Governance

| | Corporate | Syndicate |
|---|---|---|
| Board | Evaluates trajectory, doesn't manage | Coherence agent: sees only metrics, prunes bad branches |
| Management | Designs strategy, modifies operations | Meta-agent: modifies skills, prompts, criteria; promotes learnings to agents/skills |
| Operations | Executes tasks | Task agent: produces deliverables. Learned agents: specialized work promoted from experience |

The firewall: the coherence agent's instructions are bundled with this skill and never modified. It runs as a separate invocation with a different model. It sees trajectories, not implementations.

## Lineage

- **TurkoMatic** (2011): Discovered derailment. Fixed it with structural separation.
- **Darwin Gödel Machine** (2025): Open-ended evolution of self-improving coding agents.
- **HyperAgents** (2026): Self-referential meta-agent. Meta-level improvements transfer across domains.
- **Syndicate**: Adds the coherence layer. Criteria evolve through learning-by-doing. Claude Code as native substrate. Supports two lifecycle modes: **jobs** (converge and dissolve) and **ventures** (converge, ship, discover the next improvement, repeat). The three-tier governance is identical in both. Venture mode only changes what happens at convergence.
