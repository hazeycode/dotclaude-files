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
  Extend plans, don't multiply them; never send a lane to re-read a long one.
- **No unbounded wait-loops — say it in the brief**: bound every retry, then
  exit. A lane polling for what can no longer arrive reports complete yet stays
  registered, burning a cap slot; one cost three hours of one.
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

## 3. Concurrency and lifecycle

- **Cap concurrent lanes (~4)** unless measurement says more; exclusive
  resources (GPU, benchmarks) get one at a time, or a lock. **Count from the
  LIVE AGENT LIST, never your own tally** — a lane can report complete and
  stay registered.
- Record each lane with its scope; never touch its files. **Dead lanes respawn
  from a checkpoint, idle get a nudge, FINISHED get killed** — replay is
  expensive, so a lane commits a state-of-play and a fresh one resumes from it.
- On complete: load land-lane. The coordinator verifies and stages; the HUMAN
  authors the merge.
