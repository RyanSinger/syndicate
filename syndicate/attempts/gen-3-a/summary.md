# Gen 3-a Summary

Integrates gen-2-a mutation operator taxonomy and gen-2-b empirical discovery ranking on top of the gen-1-a + gen-2-c baseline, deferring pairwise selection and record-usage procedure per directive.

## Criterion Checklist

1. **Cross-project promotion end-to-end**: 5. Gen-1-a Promotion Scope and Collision Policy sections untouched (grep-verified). Manifest line is additively extended, backward compatible.
2. **Research-grounded**: 5. Four arXiv citations inline: PromptBreeder 2309.16797, EvoPrompt 2309.08532, Voyager 2305.16291, Zheng 2025 lifelong-agents 2501.07278, each tied to the specific design choice it justifies.
3. **Plugin still works**: 5. All edits are textual additions to `SKILL.md` (2 lines) and `references/loop.md` (two subsections). No agent definition, scoring code, or existing schema mutated.
4. **Net improvement**: 5. Adds two independent primitives (named operator diversity + empirical retrieval) that gen-2-c alone did not carry.
5. **At least TWO non-promotion improvements**: 5. (a) mutation operator taxonomy with per-variant declaration; (b) empirical discovery ranking formula with cold-start fallback and auto-flag. Both are distinct from promotion plumbing.
6. **Token-disciplined; coherence firewall preserved**: 5. SKILL.md +26 words (2 lines, within the 2-line cap). `plugin/agents/coherence.md` untouched. Reference-file additions only load when the meta-agent reads them.
