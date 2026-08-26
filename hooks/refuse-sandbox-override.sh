#!/bin/bash
# PreToolUse(Bash): refuse any call asking to run outside the sandbox.
#
# dangerouslyDisableSandbox is an ordinary tool parameter, so the model can ask
# for it, and in auto mode a classifier answers instead of you. That is the
# whole filesystem and network boundary undone by a request nobody saw. This
# hook takes the decision away from the model: running unsandboxed now needs a
# human to unregister this hook.
#
# Installing to ~/.claude needs the override, so an install fails while this is
# registered. That is the point, not a bug.
#
# The substring test runs before jq is used, so deleting jq cannot silence the
# hook. Ordinary calls never mention the flag and exit straight away.

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
