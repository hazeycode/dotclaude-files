#!/bin/bash
# Hand ONE workspace file to VS Code, outside the sandbox, with no way for the
# argument to become a flag.
#
# Why this file exists at all. Launching a GUI window needs IPC to launchd /
# RunningBoard, which a sandboxed Bash child cannot reach: `code -n <file>`
# exits 0 and no window appears, and `open` fails with NSCocoaErrorDomain 4099
# "Couldn't communicate with a helper application". So the review window in
# land-lane step 8 is the one command in the workflow that must run with
# dangerouslyDisableSandbox.
#
# Why not exempt `code` directly. `code` takes flags, and an exemption glob is
# matched against raw text where `*` also matches spaces, so ANY wildcarded
# pattern for it is a hole:
#     code -n --install-extension /tmp/evil.vsix x.code-workspace
# is one unchained command with no `$(`, it matches `code -n *.code-workspace`,
# and VS Code extensions execute code. refuse-sandbox-override.sh names THIS
# script instead, and everything after the script name lands in "$1" where it
# cannot be a flag.
#
# The checks below are the actual guarantee. `--` is defence in depth only: it
# is not verified here that the `code` CLI honours it as an end-of-flags
# marker, so nothing rests on that.

# A refusal names the check that failed; the exit codes are unchanged.
usage='usage: open-review.sh <existing *.code-workspace file>'
die() { printf 'open-review.sh: %s\n%s\n' "$1" "$usage" >&2; exit "$2"; }

[ $# -eq 1 ] || die "expected exactly 1 argument, got $#" 64   # never a flag list

case $1 in
  -*)               die "argument looks like a flag: $1" 64 ;;  # never a flag, however spelled
  *.code-workspace) : ;;                                        # never anything but a workspace file
  *)                die "not a .code-workspace file: $1" 64 ;;
esac

[ -f "$1" ] || die "no such workspace file: $1" 66             # must exist; creates nothing

exec code -n -- "$1"
