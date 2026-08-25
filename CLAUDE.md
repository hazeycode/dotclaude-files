# Global working rules

Portable, project-agnostic coordinator workflow. Project-specific facts (gates,
hashes, file names) live in each project's own CLAUDE.md — nothing here should
need editing when a project changes.

## Coordination model

- **The main session coordinates; lanes do the work.** One worktree-isolated
  agent per independent piece; keep coordinator turns short. Anything you could
  just write yourself, write — a lane costs a worktree, the project context,
  and a merge.
- **Two skills carry the checklists: `spawn-lane`** (model tier, brief, region
  ownership, scoped gates, report contract) **and `land-lane`** (verify, stage
  the merge, then WATCH — **the HUMAN authors the landing merge on main; the
  coordinator commits only on lane branches**. Every lane, no exceptions).
  Load the skill at those two moments; don't work from memory of this file.
- **Cap concurrent lanes (~4)** unless measurement says more. Exclusive
  resources (GPU, benchmarks) get one lane at a time, or a lock. **Count the
  cap from the LIVE AGENT LIST, never your own tally** — a lane can report
  complete and stay registered as running.
- **The coordinator provides the worktree; the lane VERIFIES it on arrival**
  (cwd inside a worktree, branch not the target) — spawn type `lane` makes the
  harness create it. An unisolated lane STOPS and reports; it never
  hand-builds, and never runs worktree commands that assume a free cwd.
- **Lanes read sibling repos freely, modify them never** — cross-repo edits and
  API-break sequencing are the coordinator's.
- **Dead lanes respawn fresh from a checkpoint; idle lanes get a nudge;
  FINISHED lanes get killed.** Transcript replay is expensive — lanes commit a
  running state-of-play (measured / ruled out / half-built / next) so a fresh
  lane picks up from disk.
- **BAN UNBOUNDED WAIT-LOOPS IN EVERY BRIEF; bound the retries and exit.** A
  lane polling `until` for what can no longer arrive reports complete yet sits
  registered as running — burning a cap slot, firing a notification per expiry.
  One cost three hours of a slot, caught only because the live list disagreed
  with the tally.
- **Briefs carry established findings** — never send a lane to re-read a long
  plan. Extend plans, don't multiply them.
- **Ask vs decide:** the coordinator decides anything derivable from code,
  docs, or measurement; the human rules on goals, trade-offs, and anything
  moving a baseline. Rulings are short option quizzes with a recommendation,
  recorded in the owning doc as they land, never re-litigated — a recorded
  ruling is load-bearing until the human moves it.
- **Gate scoping is the coordinator's job**: pick the lane's list from its diff
  surface at brief time; the full suite runs once at land time (land-lane's
  pre-review battery). Not every lane runs every gate.

## Model selection for lanes

- **Capability floor beats cost.** Never let price push work to a model
  unlikely to perform it; if output tokens are expensive, instruct concision —
  don't use a weaker model.
- **Sonnet when the brief carries the judgement** (mechanical edits, applying a
  decision, a specified sweep); **the frontier model when the lane decides what
  "correct" means, could invalidate baselines, or the instrument can fail
  silently.** Haiku is retired for lanes: a pilot misquoted a number in its one
  interpretation sentence.

## Verification discipline

Checks are cheap; churn is not — mistakes, not verification, are the token cost.

- **Run the check on the tree YOU built**; never quote a literal from a plan,
  doc-comment, or brief when the artifact itself can be read.
- **Quote the exit codes you actually saw** — never pipe a merge or gate
  through `tail`/`head` in a `&&` chain; it launders the exit code. Capture
  `$?` explicitly.
- **Inspect visual A/Bs with your own eyes** — metrics under
  auto-exposure/auto-gain read a defective frame as healthy. Look at both
  images before reporting or shipping.
- **Attribution before acceptance**: two changes with one reading tell you
  nothing. One reading per change plus the combination, on one tree, baseline
  reproduced first.
- **Controls must scramble exactly what the mechanism claims to derive** —
  write the single term down before running one; a control over a composite
  proves only the composite matters. Run the amplitude-matched
  pattern-destroying control before crediting a derivation.
- **State the sampling scale with every number** — cell size / window /
  resolution, or the number means nothing.
- **Never edit a target, reference, or threshold to make a number agree**;
  never harden a gate around current output.
- **Concurrent machines: interleave A/B arms; report ratios, not absolute
  times.**
- **Measure over the SHORTEST statistically valid span, and prove it** — a
  long window is unexamined cost, not rigour. Split the sample: agreeing
  halves prove the span; disagreeing halves mean it must grow. Interleave arms
  in PAIRS and stop when separation exceeds spread — never a habitual rep
  count. An inherited window is not binding: re-measure the baseline as your
  own arm and the span is yours, because acceptance is the RATIO.
- **Watch every new gate or probe go RED on purpose before believing it** —
  and a gate must PRINT its verdict; silence is inconclusive, never a pass.
- **A DELIBERATE-RED ARM HAS A SAMPLE SIZE — state it, and why the arm could
  have failed.** A green deliberate-red usually means the fixture was too
  small to bite: a dropped cache-key field passed at 6 items and failed at 40;
  an identity fixture too coarse to hold the defect passed while testing
  exactly that defect. Both caught only because the lane distrusted its own
  pass.
- **A check must be as WIDE as the claim it supports.** A probe proving a
  cache KEY moves says nothing about the PAYLOAD; a share divided by a
  denominator it never accumulates prints 0.0% while looking armed. The gap
  between verified and concluded is where wrong answers live — and it is the
  READER's error as often as the probe's.
- **When a result surprises, audit the instrument before the mechanism** —
  blind probes, noise-limited gates, and void controls produce confident wrong
  verdicts.
- **Report what you actually saw.** A negative result that kills a design
  cheaply is the most valuable thing a lane can produce.

## Code hygiene

- **No golden-path switches.** Attribution levers (env vars, flags) die at
  acceptance with a no-diff proof; modes, pins, and off-by-default features
  survive. In the shipped path there is no toggle.
- **A code-changing lane tidies the regions it touches** (stale comments,
  lying docs, dead decls — same evidence bar as any deletion) and reports the
  simplification candidates it saw but did not perform. Never a licence to
  refactor past the brief.
- **Keep shared context lean continuously** — compress in the same edit that
  grows it. Every lane loads the project file in full every time.
- **Plans state current truth: DELETE superseded content, don't annotate it
  dead** — a staleness banner makes every reader parse both eras. Grep citing
  sites before cutting; append-only records (ledgers, signed entries) are
  history, not dead — they stay.

## Git in a multi-lane world

- Never bare `git stash`/`stash pop` (the stack is global across worktrees) —
  WIP commits, or `stash push -u -m <tag>` + `apply` by SHA.
- Never `git add -A`, `checkout`, `reset`, `restore`, or `clean` outside your
  own worktree — lanes run concurrently.
- A lane commits ONLY to its own branch (check `git branch --show-current`
  before the first commit); never touch main from a lane; never push unasked.
- Commit early, often, and before any `git checkout`.

## Context economy

- **Grep first, then read the part you need** — reads dominate context cost,
  and a big early read is re-paid every turn after.
- **Absolute paths; no `cd`** — compound `cd … && …` is the largest single
  source of tool errors in sandboxed worktrees.
- **Condense before final commit, without information loss** — responses,
  code, comments, docs, memories; clean stale things as you go.
