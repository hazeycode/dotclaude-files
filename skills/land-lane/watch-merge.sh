#!/bin/bash
# Bounded watch for the human's verdict on a staged lane merge.
# Usage: watch-merge.sh <repo-abs-path> <lane-branch> [target-branch=main] [cap-seconds=3600]
# Run in the background after opening the review tool; exits the moment
# MERGE_HEAD disappears and PRINTS the verdict (a gate must print):
#   ACCEPTED <sha>  the lane head is now an ancestor of the target (human committed)
#   REJECTED        merge gone and lane not merged (human aborted)
#   TIMEOUT         cap expired with the merge still staged
# Stateless on purpose: ancestry, not a captured baseline, decides - so a
# commit that lands before the watch even starts is still ACCEPTED.
# The verdict is a trigger, not proof - land-lane step 9 re-verifies.
# --end-of-options guards every ref operand so a branch named like a flag
# (e.g. "--all") is read as a ref, never executed as an option.

repo=$1; lane=$2; target=${3:-main}; cap=${4:-3600}
lane_head=$(git -C "$repo" rev-parse --verify --end-of-options "$lane") || exit 2
git -C "$repo" rev-parse -q --verify --end-of-options "$target" >/dev/null || exit 2
elapsed=0
while [ "$elapsed" -lt "$cap" ]; do
  if ! git -C "$repo" rev-parse -q --verify MERGE_HEAD >/dev/null; then
    if git -C "$repo" merge-base --is-ancestor --end-of-options "$lane_head" "$target"; then
      echo "ACCEPTED $(git -C "$repo" rev-parse --verify --end-of-options "$target")"
    else
      echo "REJECTED"
    fi
    exit 0
  fi
  sleep 5; elapsed=$((elapsed + 5))
done
echo "TIMEOUT"; exit 0
