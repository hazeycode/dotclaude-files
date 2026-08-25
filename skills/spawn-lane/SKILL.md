---
name: spawn-lane
description: Construct and launch a worktree-isolated worker lane with a complete brief — model tier, carried findings, scoped gates, and report contract. Use when delegating a piece of work to a background agent.
---

# Spawn a lane

Build the brief from this checklist, then launch with worktree isolation and an
explicit model. A lane that has to rediscover context burns tokens re-reading what
you already know; a lane with a wrong-tier model produces confident wrong answers.

## 1. Model tier (capability floor beats cost)

- **Sonnet** when the brief carries the judgement: mechanical edits, applying a
  decision already made, a fully-specified sweep.
- **Frontier model (Opus-class)** when the lane must decide what "correct" means,
  could invalidate a baseline or golden value, or when its instrument can fail
  silently (a capture that renders black and reads clean, a stale binary that
  prints a confident wrong number).
- Never let price push work below the capability floor. If output tokens are the
  concern, instruct concision — don't downgrade the model.
- **Split briefs by tier, don't tier whole briefs** (standing policy, 2026-08-17):
  when a task bundles a judgement half and a mechanical half (a design stage that
  defines a format, then plumbing that implements it; a metric design, then bulk
  image generation), spawn them as separate lanes — the judgement half on the
  frontier model, the mechanical half on Sonnet once the judgement half's output
  makes the brief carry it. Don't send a whole bundle to the frontier model
  because its first stage needs one.

## 2. The brief must carry

- **Identity and rules**: it is worktree-isolated already; it must run no worktree
  command and spawn no sub-agents; commits go only to its own branch (check
  `git branch --show-current` first); absolute paths, no `cd`; grep-then-read.
- **Established findings**, stated as facts with numbers — never "read the plan".
  Extend plans, don't send lanes to re-derive them.
- **Region ownership**: name the files/regions other live lanes own; the lane must
  stop and report rather than edit those.
- **Scoped gates**: pick the verification list from the lane's diff surface, and
  say "this is your full list". The full suite runs once at merge.
- **Report contract**: exit codes actually seen; what changed with proofs;
  simplification candidates seen but not performed; negative results stated
  plainly; commit a running state-of-play before long operations.

## 3. After launch

Record the lane in your task list with its scope. Do not touch its files. When it
reports: verify its claims against its own evidence, re-run gates on the merged
tree (its gates predate your other merges), and inspect any visual output with
your own eyes before shipping.
