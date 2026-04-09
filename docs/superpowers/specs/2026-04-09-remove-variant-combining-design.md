# Remove Variant Combining

## Problem

Since 0.6.0 added variant combining, syndicates almost always combine instead of pruning. The combine path has structural biases that make it the path of least resistance:

- The meta-agent judges its own work (no separation of concerns)
- The coherence agent never sees the combine decision (runs before merge step)
- File-overlap is the only hard gate, and exploration variants naturally touch different files
- No scoring floor for the non-winner to participate

The result is that selection pressure is weakened. Instead of picking a winner and letting the next generation build on it, the syndicate stitches together pieces from variants that weren't individually good enough to win.

## Decision

Remove the combine path entirely. One winner advances per generation. Pruned variants' ideas carry forward through meta-notes and the "borrow" mutation operator, not through file merging.

This preserves "learn from every variant" (meta-notes, step 8) while keeping selection pressure intact.

## Changes

### SKILL.md step 7 (lines 56-58)

Replace the current "Merge best, clean up rest" step (which has both "Single winner" and "Combine" paths) with a single-winner-only step. The highest-scoring variant wins. Squash-merge onto the run branch. Mark all others pruned in `branches.jsonl`.

### SKILL.md step 8

Make explicit that documenting what worked in pruned variants is how their ideas survive. Future generations can use the "borrow" mutation operator to recover good ideas from pruned branches.

### loop.md branches.jsonl schema (lines 167-173)

- Drop the `combined` field from the schema and example lines
- Remove the paragraph explaining combined variant marking

## What does NOT change

- Scoring (still score all variants honestly)
- Coherence agent (no changes needed)
- Task agent (no changes needed)
- Meta-notes workflow (already captures learnings from all variants)
- Mutation operators (borrow already exists for recovering pruned ideas)
- branches.jsonl `pruned` field (winner is `false`, all others `true`)
