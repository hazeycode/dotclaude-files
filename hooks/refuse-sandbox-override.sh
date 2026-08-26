#!/bin/bash
# PreToolUse(Bash) : refuse any call that asks to run outside the sandbox.
#
# WHY. dangerouslyDisableSandbox is an ordinary tool parameter, so the model can
# request it and — in auto mode — a classifier answers rather than you. That is
# the entire filesystem and network boundary undone by a request nobody saw.
# This hook takes the decision away from the model: the only way to run
# unsandboxed becomes a human unregistering this hook in settings.
#
# COST, deliberately accepted. Installing to ~/.claude needs the override, so
# with this registered an install fails until you unregister it. That is the
# property, not a bug: leaving the boundary requires a human editing config.
#
# The cheap substring test runs BEFORE any jq use, so removing jq cannot
# silence this hook — a payload naming the flag is refused even with no jq to
# parse it. Ordinary calls never mention the flag and exit immediately.

deny() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}' "$1"
  exit 0
}

input=$(</dev/stdin)   # builtin redirection: no external command to remove

case $input in
  *dangerouslyDisableSandbox*) ;;   # worth inspecting
  *) exit 0 ;;                      # absent: nothing to decide
esac

# Present. If jq can read it, honour an explicit false; otherwise refuse.
if command -v jq >/dev/null 2>&1; then
  v=$(jq -r '.tool_input.dangerouslyDisableSandbox // false' <<<"$input" 2>/dev/null)
  [ "$v" = "true" ] || exit 0
fi

deny "sandbox override refused; unregister this hook in settings to allow it"
