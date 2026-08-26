#!/bin/bash
# PreToolUse(Write|Edit|Bash): an exemption file is the HUMAN's to write.
#
# The two guards beside this one (guard-allowlisted-bash.sh,
# refuse-sandbox-override.sh) each honour a project-declared exemption list
# with no prompt at all. So writing a line into one of those lists IS granting
# the permission -- a human's call, like the landing merge, not something a
# lane hands itself on the way past. This hook turns every touch of one into a
# prompt, whoever is writing and whatever permission mode is in force; lanes
# auto-accept edits inside their own worktree, so prose alone does not hold.
#
# Matched by BASENAME, so a worktree, an absolute path or a sibling checkout
# is covered the same way:
#     sandbox-exempt          bash-expansion-exempt
#     sandbox-exempt.local    bash-expansion-exempt.local
# For Bash it looks for those stems anywhere in the command text, because a
# write arrives as `>`, `>>`, `tee`, `sed -i`, `cp`, `git checkout` or a
# heredoc and this hook parses no shell. So `cat .claude/sandbox-exempt`
# prompts as well -- consult a list with the Read tool, which is not matched
# here.
#
# It never refuses -- a mistake here costs a prompt, not a hole. In auto mode
# a classifier answers the prompt instead of you.
#
# Needs jq. With no jq it stays silent.

silent() { exit 0; }
ask() {
  jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$r}}'
  exit 0
}

command -v jq >/dev/null 2>&1 || silent
input=$(cat)
tool=$(jq -r '.tool_name // empty' <<<"$input" 2>/dev/null) || silent

why="an exemption file grants a permission the guards then honour without prompting; the human writes it. Report the exact glob, the command it must run, and why nothing weaker works."

case $tool in
  Write|Edit|NotebookEdit)
    path=$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$input" 2>/dev/null)
    [ -n "$path" ] || silent
    case ${path##*/} in
      sandbox-exempt|sandbox-exempt.local|bash-expansion-exempt|bash-expansion-exempt.local)
        ask "$tool writes ${path##*/}: $why" ;;
    esac ;;
  Bash)
    cmd=$(jq -r '.tool_input.command // empty' <<<"$input" 2>/dev/null)
    [ -n "$cmd" ] || silent
    case $cmd in
      *sandbox-exempt*)        ask "Bash command names sandbox-exempt: $why" ;;
      *bash-expansion-exempt*) ask "Bash command names bash-expansion-exempt: $why" ;;
    esac ;;
esac

silent
