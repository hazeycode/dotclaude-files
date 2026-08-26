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

[ $# -eq 1 ] || exit 64            # exactly one argument, never a flag list

case $1 in
  -*)               exit 64 ;;     # never a flag, however it is spelled
  *.code-workspace) : ;;           # never anything but a workspace file
  *)                exit 64 ;;
esac

[ -f "$1" ] || exit 66             # must already exist; creates nothing

exec code -n -- "$1"
