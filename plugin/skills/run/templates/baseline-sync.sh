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
