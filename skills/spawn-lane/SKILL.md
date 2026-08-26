---
name: spawn-lane
description: Construct and launch a worktree-isolated worker lane with a complete brief — model tier, carried findings, region ownership, scoped gates, report contract. Use when delegating work to a background agent.
---

# Spawn a lane

Build the brief from this checklist; launch with subagent type `lane` (the
vendored agent definition: worktree-isolated, edits auto-accepted inside its
own worktree only) and an explicit model. A lane that rediscovers context burns
tokens re-reading what you already know; a wrong-tier model produces confident
wrong answers.

## 1. Model tier (capability floor beats cost)

- **Sonnet** when the brief carries the judgement: mechanical edits, applying a
  made decision, a fully-specified sweep.
- **Frontier model (Opus-class)** when the lane decides what "correct" means,
  could invalidate a baseline or golden value, or its instrument can fail
  silently (a capture that renders black and reads clean; a stale binary
  printing a confident wrong number).
- Price never pushes work below the capability floor — if output tokens are
  the concern, instruct concision, don't downgrade the model.
- **Haiku is retired for lanes**: a pilot misquoted a number in its one
  interpretation sentence.
- **Split briefs by tier, don't tier whole briefs**: a task bundling a
  judgement half and a mechanical half (format design, then plumbing; metric
  design, then bulk generation) becomes separate lanes — judgement on the
  frontier model, mechanical on Sonnet once the first lane's output makes the
  brief carry it. Never send the whole bundle to the frontier model because
  its first stage needs one.

## 2. The brief must carry

- **Identity and rules**: it is worktree-isolated already; no worktree
  commands, no sub-agents; commits only to its own branch (check
  `git branch --show-current` first); it starts inside its worktree — relative
  paths from cwd, never `cd`; grep-then-read.
- **Exemptions are requests, not edits**: a command the project's exemption
  lists don't already cover goes in the report as glob + command + why nothing
  weaker works. The lane never writes the line (`agents/lane.md` carries it).
- **Established findings** as facts with numbers — never "read the plan".
  Extend plans, don't send lanes to re-derive them.
- **Region ownership**: the files/regions other live lanes own; the lane stops
  and reports rather than edit those.
- **Scoped gates** picked from the lane's diff surface, marked "this is your
  full list". The full suite runs once at land time (land-lane's pre-review
  battery).
- **Report contract**: exit codes actually seen; changes with proofs;
  simplification candidates seen but not done; negative results stated
  plainly; a committed state-of-play before long operations. **CAP the
  report — verdicts, exit codes, hash/golden lines, and pointers to committed
  evidence.** Full tables, derivations, and logs go into files on the lane
  branch (state-of-play, plan sections, log files); the coordinator reads
  them optionally at skeptical-read time. Say this in every brief — a report
  that restates its own committed files doubles its output cost.

## 3. After launch

Record the lane in your task list with its scope; do not touch its files. When
it reports complete, load land-lane and follow it — the coordinator verifies
and stages; the HUMAN authors the landing merge.
