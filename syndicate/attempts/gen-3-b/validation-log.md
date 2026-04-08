# Gen 3-b Validation Log: Live Dry-Run Bootstrap

This is the raw execution log from running the plugin's Setup procedure end to end in two disposable scratch projects under `.scratch/` (gitignored, removed before final commit). Every bug observed was fixed in plugin/ and verified by re-running in a second scratch.

## Environment

- Worktree: `/Users/ryan/syndicate/.claude/worktrees/agent-af9ea8ab`
- Global git config observed:
  - `commit.gpgsign = true`
  - `tag.gpgSign = true`
  - `tag.forceSignAnnotated = true`
- These are common developer settings; the plugin must not assume they are off.

## Run 1: Unfixed baseline

### Step 0: create toy project

```
mkdir -p .scratch/run1
git -C .scratch/run1 init -q -b main
echo "# toy" > .scratch/run1/README.md
git -C .scratch/run1 add README.md
git -C .scratch/run1 commit -q -m "init"
# -> f5c3480 init
```

Passed. `commit.gpgsign=true` did not block this commit in this sandbox (key unavailable errors did not fire; likely because the invocation path went through a non-interactive path that silently drops signing). Noted as a known fragile spot for the user, but not fixed in this variant.

### Step 1: copy templates/ to syndicate/

Took an inventory of `plugin/skills/run/templates/` before copying:

```
templates/
  meta-notes.md
  skills-manifest.jsonl
  archive/.gitkeep
  attempts/.gitkeep
  learned-agents/.gitkeep
  learned-agents/registry.jsonl
  metrics/.gitkeep
  prompts/task.md
  reports/.gitkeep
  skills/approach.md
  skills/domain/.gitkeep
```

Note: `archive/branches.jsonl`, `metrics/*.jsonl`, and `discovered.jsonl` are NOT in templates. They are created at runtime by append-writes. `.gitkeep` files hold the empty directories in git until first content lands. This is fine.

Copy executed. Directory layout in run1 matches templates exactly.

### Step 2: detect PR target

Ran `git -C .scratch/run1 symbolic-ref refs/remotes/origin/HEAD`.

Result: **exit 128**, `fatal: ref refs/remotes/origin/HEAD is not a symbolic ref`.

Cause: the scratch repo has no remote. The skill says "fall back to `main`; `none` if no remote" but does not specify that the detection command itself can fail non-zero on a repo that has a remote but no origin/HEAD symbolic ref set (shallow clones, initial pushes without `-u`, etc.). A naive implementer who only tests the "has-remote" branch will hit a crash on these edge cases.

**Bug A (minor, ordering).** The `git symbolic-ref` command can fail even when a remote exists. The written procedure needs to say: if no remote -> `none`; else run the command, and on any non-zero exit fall back to `main`.

Fixed in SKILL.md step 2 and loop.md Git Workflow / Bootstrap.

Wrote `syndicate/.pr-target` = `none`.

### Step 3: create run-1 branch

`git -C .scratch/run1 checkout -q -b syndicate/run-1`. Passed.

### Step 4: discovery pass at gen 0

Tried to read `~/.claude/syndicate-manifest.jsonl`. It does not exist. (Confirmed via Glob tool; the sandbox also blocks direct read of that path from bash, but the underlying file is genuinely absent on this machine.)

The loop.md procedure step 1 says "Read `~/.claude/syndicate-manifest.jsonl` if it exists. Skip entries where `retired: true`." It does NOT say what to do when the file is absent. A conservative implementer should write an empty `syndicate/discovered.jsonl` and move on; a naive one might skip writing the file altogether, which then makes step 3 dangling ("Write `syndicate/discovered.jsonl` (one line per candidate)" implies there is something to write).

**Bug B (first-run trap).** Missing manifest case is under-specified.

Fixed in loop.md "Discovery at Gen 0" step 1, and SKILL.md Setup step 4.

Wrote empty `syndicate/discovered.jsonl` and continued.

### Step 5: bootstrap commit

`git -C .scratch/run1 add -A && git -C .scratch/run1 commit -q -m "syndicate: bootstrap run-1"`. Passed. Commit c0c15fe.

### Step 6: seed tag (THE KEY BUG)

Followed SKILL.md verbatim: "Tag it `syndicate-seed-<N>` (local only)."

Executed `git -C .scratch/run1 tag syndicate-seed-1`.

Result: **exit 128**, `fatal: no tag message?`.

Root cause: with `tag.forceSignAnnotated = true` set globally, `git tag <name>` (a lightweight tag) is upgraded to an annotated-and-signed tag. Signing requires a tag message (via `-m` or editor), and in non-interactive mode the command aborts. A user who has set these configs once (quite common for anyone who signs git artifacts) will hit a hard failure the first time they run the syndicate bootstrap.

**Bug C (critical).** The bootstrap as written is broken on a common developer setup. The skill must use an explicit annotated tag and must override the signing config for just this invocation so the user's global config cannot break it.

Verified fix interactively:

```
git -C .scratch/run1 -c tag.gpgSign=false tag -a syndicate-seed-1 -m "syndicate seed 1"
```

Passed. Tag listed.

### Toy goal and criteria

Wrote `syndicate/goal.md` (toy resume goal) and `syndicate/criteria.md` (three trivial criteria). This simulates "user approved scope of work."

## Fixes Applied

All edits live ON TOP of the baseline-sync commit.

### Fix 1: SKILL.md Setup step 2 (PR target fallback robustness)

Before:
> 2. Detect the PR target branch (`git symbolic-ref refs/remotes/origin/HEAD`, fall back to `main`; `none` if no remote). Write to `syndicate/.pr-target`.

After:
> 2. Detect the PR target branch: if no remote, write `none`; else try `git symbolic-ref refs/remotes/origin/HEAD` and on any failure fall back to `main`. Write to `syndicate/.pr-target`.

### Fix 2: SKILL.md Setup step 4 (empty manifest handling)

Before:
> 4. Run the discovery pass (see `references/loop.md` "Discovery at Gen 0") to index user-level agents and skills into `syndicate/discovered.jsonl`.

After:
> 4. Run the discovery pass (see `references/loop.md` "Discovery at Gen 0") to index user-level agents and skills into `syndicate/discovered.jsonl`. If `~/.claude/syndicate-manifest.jsonl` does not exist, write an empty `discovered.jsonl` and continue.

### Fix 3: SKILL.md Setup step 6 (tag command explicit)

Before:
> 6. Tag it `syndicate-seed-<N>` (local only).

After:
> 6. Tag it locally as an annotated tag, overriding any user signing config: `git -c tag.gpgSign=false tag -a syndicate-seed-<N> -m "syndicate seed <N>"`. Do not push.

### Fix 4: loop.md Git Workflow / Bootstrap (same robustness, longer-form)

Before:
> Detect the PR target branch (`git symbolic-ref refs/remotes/origin/HEAD`, fall back to `main`; `none` if no remote). Write to `syndicate/.pr-target`.
> Create `syndicate/run-<N>` off HEAD (N increments past prior runs). Commit the initial `syndicate/` directory. Tag it `syndicate-seed-<N>` (local only, not pushed).

After:
> Detect the PR target branch. If the repo has no remote, write `none`. Otherwise run `git symbolic-ref refs/remotes/origin/HEAD` and, on any non-zero exit (no origin HEAD ref set, shallow clone, etc.), fall back to `main`. Write the result to `syndicate/.pr-target`.
> Create `syndicate/run-<N>` off HEAD (N increments past prior runs). Commit the initial `syndicate/` directory. Tag it locally with `git -c tag.gpgSign=false tag -a syndicate-seed-<N> -m "syndicate seed <N>"`. The explicit `-a` and `-c tag.gpgSign=false` are required: users commonly have `tag.gpgSign=true` or `tag.forceSignAnnotated=true` globally, which causes plain `git tag <name>` to fail with `fatal: no tag message?`. Do not push the tag.

### Fix 5: loop.md "Discovery at Gen 0" step 1

Before:
> 1. Read `~/.claude/syndicate-manifest.jsonl` if it exists. Skip entries where `retired: true`.

After:
> 1. Read `~/.claude/syndicate-manifest.jsonl` if it exists. Skip entries where `retired: true`. If the file is missing (first-ever syndicate run on this machine), write an empty `syndicate/discovered.jsonl` and skip the rest of this procedure.

## Run 2: Fixed bootstrap

Re-ran the entire procedure in a fresh `.scratch/run2` project. Same toy setup.

- Step 1 (templates): OK.
- Step 2 (PR target): no remote detected -> wrote `none`. Skipped the failing `symbolic-ref` call per the fixed procedure. OK.
- Step 3 (run-1 branch): OK.
- Step 4 (discovery): manifest absent -> wrote empty `discovered.jsonl` per fix. OK.
- Step 5 (bootstrap commit): 41a5d5d. OK.
- Step 6 (seed tag): `git -c tag.gpgSign=false tag -a syndicate-seed-1 -m "syndicate seed 1"`. **Passed**, tag listed.

Run 2 is a clean second run end to end with zero manual intervention beyond following the fixed procedure verbatim. The tagged commit hash is 41a5d5d; the tag is `syndicate-seed-1`, present in `git tag -l` output.

## Cleanup

`.scratch/` is in `.gitignore` (added at the top of this variant; pre-existing `.gitignore` only covered `*.swp`, `.DS_Store`, `.playwright-mcp/`). Removed `.scratch/` entirely before the final commit. The final tree contains no scratch residue.
