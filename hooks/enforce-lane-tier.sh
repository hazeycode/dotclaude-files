#!/bin/bash
# PreToolUse hook on the Agent tool.
# Gates lane spawns (isolation "worktree" or "remote"): the model parameter
# must be explicit and one of sonnet/opus/fable, and forks are refused (they
# ignore the model parameter). Other spawns pass through. FAILS CLOSED: a
# missing jq or an unparseable payload denies rather than allows.
# Residual gap (accepted): a lane spawned with NO isolation parameter that
# hand-builds its own worktree is not detectable here.
# Registration ships in the repo-root settings.json (installed to
# ~/.claude/settings.json). After provisioning a new machine, watch this hook
# go RED on purpose — spawn a violating lane and see the deny — before
# trusting it: a missing deny is indistinguishable from compliance.

deny_raw() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}' "$1"
  exit 0
}

command -v jq >/dev/null 2>&1 || deny_raw "enforce-lane-tier: jq unavailable - failing closed, not open"

input=$(cat)
if ! isolation=$(jq -r '.tool_input.isolation // empty' <<<"$input" 2>/dev/null); then
  deny_raw "enforce-lane-tier: unparseable hook payload - failing closed, not open"
fi
subagent=$(jq -r '.tool_input.subagent_type // empty' <<<"$input")
case "$isolation:$subagent" in
  worktree:*|remote:*|*:lane) : ;;   # lane agent type carries worktree isolation in its definition
  *) exit 0 ;;
esac

deny() {
  jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
  exit 0
}

model=$(jq -r '.tool_input.model // empty' <<<"$input")

if [ "$subagent" = "fork" ]; then
  deny "Lane spawn refused: forks ignore the model parameter, so the tier cannot be chosen. Spawn a fresh agent with an explicit model (spawn-lane skill)."
fi

if [ -z "$model" ]; then
  deny "Lane spawn refused: no model parameter. Lanes never ride the default - pick the tier per the spawn-lane skill (sonnet for mechanical work, opus/fable for judgement)."
fi

case "$model" in
  sonnet*|opus*|fable*|claude-sonnet*|claude-opus*|claude-fable*) : ;;
  *) deny "Lane spawn refused: model '$model' is not a lane tier. Lanes take sonnet (mechanical) or opus/fable (judgement)." ;;
esac

exit 0
